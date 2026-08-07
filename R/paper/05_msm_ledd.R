#!/usr/bin/env Rscript
# =============================================================================
# ARTICULO — Analisis 3: la LEDD como confusor variable en el tiempo
#
# La dosis dopaminergica equivalente es un confusor variable en el tiempo
# AFECTADO POR LA EXPOSICION PREVIA: el dolor influye en la prescripcion, la
# prescripcion influye en el estado motor y en el dolor posterior. Es el
# escenario canonico en que la regresion convencional da estimaciones sesgadas
# tanto si se ajusta por ella como si no (Robins, Hernan y Brumback 2000).
#
#   - Sin ajustar por LEDD: queda confusion por indicacion.
#   - Ajustando por LEDD: se bloquea la parte del efecto que pasa por la
#     prescripcion, y ademas se abre un camino de colision si hay causas comunes
#     no medidas de la LEDD y del desenlace.
#
# La solucion es un modelo estructural marginal con ponderacion por probabilidad
# inversa de tratamiento, estabilizada, combinada con la ponderacion por censura
# del analisis 2. Se anade estimacion g por sustitucion como comprobacion
# independiente, porque las dos tienen supuestos de modelado distintos.
#
# ADVERTENCIA DE INTERPRETACION. El dolor es un ESTADO, no una intervencion.
# "El efecto de tener dolor" no define un contrafactual sin especificar como se
# intervendria. Lo que se estima aqui es un contraste ponderado bajo un modelo
# causal explicito, no el efecto de un tratamiento asignable.
#
# Ejecutar:  Rscript R/paper/05_msm_ledd.R
# =============================================================================

source(file.path(Sys.getenv("TESIS_ROOT", unset = getwd()), "R", "paper", "00_comun.R"))
suppressPackageStartupMessages({
  library(geepack); library(sandwich); library(lmtest)
})

set.seed(SEED)
titulo("ANALISIS 3 — LEDD COMO CONFUSOR VARIABLE EN EL TIEMPO")

d <- cargar_largo("off")
salidas <- list()

# =============================================================================
# 1. ESTRUCTURA TEMPORAL DE LA EXPOSICION Y DEL CONFUSOR
# =============================================================================
titulo("1. Estructura temporal: el dolor precede a la prescripcion?")

panel <- d |>
  filter(!is.na(NP1PAIN) | !is.na(UPDRS3)) |>
  arrange(PATNO, EVENT_ID) |>
  group_by(PATNO) |>
  mutate(
    ola = as.integer(EVENT_ID),
    dolor_prev = lag(dolor_si),
    dolor_int_prev = lag(dolor_int),
    LEDD_prev = lag(LEDD),
    motor_prev = lag(UPDRS3),
    dLEDD = LEDD - lag(LEDD)
  ) |>
  ungroup()

# Comprobacion empirica del supuesto estructural: el dolor previo, predice la
# LEDD actual condicionando en la LEDD previa? Si no lo hiciera, la LEDD no
# seria un confusor afectado por la exposicion y bastaria la regresion estandar.
sub_l <- panel |> filter(!is.na(dolor_prev), !is.na(LEDD_prev), !is.na(LEDD),
                         !is.na(motor_prev))
m_ledd <- lm(LEDD ~ dolor_prev + LEDD_prev + motor_prev + age_yrs + sexo +
               disease_yrs + tiempo_anios, data = sub_l)
ct <- lmtest::coeftest(m_ledd, vcov. = sandwich::vcovCL(m_ledd, cluster = sub_l$PATNO))
subtitulo("La LEDD actual sobre el dolor previo, ajustando por la LEDD previa")
print(round(ct[c("dolor_prev", "LEDD_prev", "motor_prev"), ], 4))

est_l <- tibble(termino = "dolor(t-1) -> LEDD(t) | LEDD(t-1)",
                n = nobs(m_ledd), estimacion = ct["dolor_prev", 1],
                ee = ct["dolor_prev", 2],
                ic_bajo = ct["dolor_prev", 1] - 1.96 * ct["dolor_prev", 2],
                ic_alto = ct["dolor_prev", 1] + 1.96 * ct["dolor_prev", 2],
                p = ct["dolor_prev", 4])
print(as.data.frame(est_l), digits = 4)
salidas$dolor_a_ledd <- est_l

cat("\n  LECTURA. Si este coeficiente es distinto de cero, la LEDD es confusor\n",
    " AFECTADO por la exposicion previa y los g-metodos estan justificados. Si\n",
    " es nulo, la regresion estandar basta y hay que decirlo.\n", sep = "")

# Aplicacion de la regla, sin excepciones. Se evalua aqui y su resultado se
# arrastra a la sintesis, para que no dependa de como se lea la prosa despues.
REGLA_CUMPLIDA <- est_l$p[1] < ALPHA
cat(sprintf("\n  VEREDICTO DE LA REGLA: p = %.4f -> %s\n", est_l$p[1],
            if (REGLA_CUMPLIDA) "se cumple, los g-metodos estan justificados"
            else "NO se cumple. El modelo estructural marginal pasa a SENSIBILIDAD."))

# Y el otro brazo: la LEDD previa, predice el dolor actual?
sub_d <- panel |> filter(!is.na(dolor_int), !is.na(LEDD_prev), !is.na(dolor_int_prev))
m_dol <- lm(dolor_int ~ LEDD_prev + dolor_int_prev + age_yrs + sexo +
              disease_yrs + tiempo_anios, data = sub_d)
ct2 <- lmtest::coeftest(m_dol, vcov. = sandwich::vcovCL(m_dol, cluster = sub_d$PATNO))
subtitulo("El dolor actual sobre la LEDD previa, ajustando por el dolor previo")
print(round(ct2["LEDD_prev", , drop = FALSE], 6))
salidas$ledd_a_dolor <- tibble(
  termino = "LEDD(t-1) -> dolor(t) | dolor(t-1)", n = nobs(m_dol),
  estimacion = ct2["LEDD_prev", 1], ee = ct2["LEDD_prev", 2],
  ic_bajo = ct2["LEDD_prev", 1] - 1.96 * ct2["LEDD_prev", 2],
  ic_alto = ct2["LEDD_prev", 1] + 1.96 * ct2["LEDD_prev", 2], p = ct2["LEDD_prev", 4])

# =============================================================================
# 2. PESOS DE TRATAMIENTO ESTABILIZADOS (IPTW)
# =============================================================================
titulo("2. Pesos estabilizados para la historia de exposicion")

# Exposicion binaria por visita: presencia de dolor. El modelo del denominador
# condiciona en la historia de confusores variables en el tiempo (LEDD, motor)
# y en la exposicion previa; el numerador solo en la exposicion previa y en las
# basales fijas. El cociente es el peso estabilizado de Robins.
msm_d <- panel |>
  filter(!is.na(dolor_si), !is.na(LEDD), !is.na(UPDRS3),
         !is.na(age_yrs), !is.na(disease_yrs), !is.na(MoCA), !is.na(tiempo_anios)) |>
  group_by(PATNO) |>
  arrange(EVENT_ID, .by_group = TRUE) |>
  mutate(dolor_prev = lag(dolor_si), LEDD_prev = lag(LEDD),
         motor_prev = lag(UPDRS3)) |>
  ungroup()

# La primera visita de cada paciente no tiene historia previa: su peso es 1.
con_hist <- msm_d |> filter(!is.na(dolor_prev), !is.na(LEDD_prev), !is.na(motor_prev))

den_t <- glm(dolor_si ~ dolor_prev + LEDD_prev + motor_prev + LEDD +
               age_yrs + sexo + disease_yrs + MoCA + tiempo_anios,
             data = con_hist, family = binomial())
num_t <- glm(dolor_si ~ dolor_prev + age_yrs + sexo + disease_yrs + tiempo_anios,
             data = con_hist, family = binomial())
stopifnot("los modelos de IPTW no comparten filas" = nobs(den_t) == nobs(num_t))

pd <- predict(den_t, type = "response")
pn <- predict(num_t, type = "response")
a <- con_hist$dolor_si
# Probabilidad del valor de exposicion efectivamente observado.
con_hist$w_t <- ifelse(a == 1, pn / pd, (1 - pn) / (1 - pd))

# El peso de la historia es el producto acumulado a lo largo del seguimiento.
con_hist <- con_hist |>
  group_by(PATNO) |>
  arrange(EVENT_ID, .by_group = TRUE) |>
  mutate(w_iptw = cumprod(w_t)) |>
  ungroup()

lim <- quantile(con_hist$w_iptw, c(0.01, 0.99), na.rm = TRUE)
con_hist <- con_hist |> mutate(w_iptw_tr = pmin(pmax(w_iptw, lim[1]), lim[2]))

subtitulo("Distribucion de los pesos acumulados de tratamiento")
print(con_hist |> group_by(EVENT_ID) |>
        summarise(n = n(), media = mean(w_iptw_tr), de = sd(w_iptw_tr),
                  min = min(w_iptw_tr), max = max(w_iptw_tr), .groups = "drop"))
cat(sprintf("\n  Truncado en [%.3f, %.3f]. Media global = %.3f (debe rondar 1)\n",
            lim[1], lim[2], mean(con_hist$w_iptw_tr)))
salidas$pesos_iptw <- con_hist |> group_by(EVENT_ID) |>
  summarise(n = n(), media = mean(w_iptw_tr), de = sd(w_iptw_tr),
            min = min(w_iptw_tr), max = max(w_iptw_tr), .groups = "drop")

# Diagnostico de balance: correlacion entre exposicion y confusor, antes y
# despues de ponderar. Si el peso funciona, la asociacion debe caer.
bal_antes <- cor(con_hist$dolor_si, con_hist$LEDD_prev, use = "complete.obs")
bal_desp <- with(con_hist, {
  wm1 <- weighted.mean(LEDD_prev[dolor_si == 1], w_iptw_tr[dolor_si == 1])
  wm0 <- weighted.mean(LEDD_prev[dolor_si == 0], w_iptw_tr[dolor_si == 0])
  (wm1 - wm0) / sd(LEDD_prev)
})
bal_crudo <- with(con_hist, (mean(LEDD_prev[dolor_si == 1]) -
                             mean(LEDD_prev[dolor_si == 0])) / sd(LEDD_prev))
subtitulo("Balance de la LEDD previa entre expuestos y no expuestos")
cat(sprintf("  diferencia estandarizada SIN ponderar: %.4f\n", bal_crudo))
cat(sprintf("  diferencia estandarizada PONDERADA:   %.4f\n", bal_desp))
salidas$balance <- tibble(medida = "LEDD previa, diferencia estandarizada",
                          sin_ponderar = bal_crudo, ponderada = bal_desp)

# =============================================================================
# 3. MODELO ESTRUCTURAL MARGINAL
# =============================================================================
titulo("3. Modelo estructural marginal")

# Peso final: tratamiento x censura. La censura se recalcula aqui sobre el mismo
# conjunto, con los predictores basales del analisis 2.
bl <- d |> filter(EVENT_ID == "BL") |>
  select(PATNO, dolor_bl = dolor_si, motor_bl = UPDRS3, edad_bl = age_yrs,
         dur_bl = disease_yrs, moca_bl = MoCA, gds_bl = GDS, ledd_bl = LEDD)

msm_fit <- con_hist |> inner_join(bl, by = "PATNO")

# Comparacion de tres especificaciones sobre EL MISMO conjunto de filas, para
# que la diferencia entre ellas sea el metodo y no la muestra.
gee_fit <- function(datos, formula, pesos = NULL, etiqueta) {
  # geeglm evalua `weights` dentro de `data`, de modo que el peso tiene que ser
  # una columna del propio marco y no una expresion del entorno de llamada.
  datos <- datos |> arrange(PATNO, EVENT_ID)
  datos$.w <- if (is.null(pesos)) 1 else datos[[pesos]]
  m <- geepack::geeglm(formula, data = datos, id = PATNO,
                       weights = .w, corstr = "independence")
  s <- summary(m)$coefficients
  fila <- "dolor_si"
  tibble(especificacion = etiqueta, n_obs = nrow(datos),
         n_pac = length(unique(datos$PATNO)),
         estimacion = s[fila, "Estimate"], ee = s[fila, "Std.err"],
         ic_bajo = s[fila, "Estimate"] - 1.96 * s[fila, "Std.err"],
         ic_alto = s[fila, "Estimate"] + 1.96 * s[fila, "Std.err"],
         p = s[fila, "Pr(>|W|)"])
}

comparacion <- bind_rows(
  gee_fit(msm_fit,
          UPDRS3 ~ dolor_si + tiempo_anios + edad_bl + sexo + dur_bl + moca_bl,
          NULL, "regresion estandar SIN ajustar por LEDD"),
  gee_fit(msm_fit,
          UPDRS3 ~ dolor_si + LEDD + tiempo_anios + edad_bl + sexo + dur_bl + moca_bl,
          NULL, "regresion estandar AJUSTANDO por LEDD"),
  gee_fit(msm_fit,
          UPDRS3 ~ dolor_si + tiempo_anios + edad_bl + sexo + dur_bl + moca_bl,
          "w_iptw_tr", "modelo estructural marginal (IPTW estabilizado)")
)
subtitulo("Las tres especificaciones, sobre el mismo conjunto de filas")
print(as.data.frame(comparacion), digits = 4)
salidas$comparacion <- comparacion

# El error estandar del MSM con pesos estimados es anticonservador si se toma el
# sandwich sin mas. Se remuestrea por PACIENTE, que es la unidad independiente, y
# se reestiman los pesos dentro de cada replica.
titulo("3b. Intervalo por remuestreo de pacientes (los pesos se reestiman)")

msm_fit <- msm_fit |> arrange(PATNO, EVENT_ID)
pacientes <- unique(msm_fit$PATNO)
B <- 500

# Se preindexan las filas de cada paciente una sola vez. Remuestrear filtrando el
# marco completo por paciente en cada replica es cuadratico y tarda horas; con el
# indice, cada replica es una concatenacion de vectores de posiciones.
filas_por_paciente <- split(seq_len(nrow(msm_fit)), msm_fit$PATNO)
filas_por_paciente <- filas_por_paciente[as.character(pacientes)]
n_pac <- length(pacientes)

una_replica <- function() {
  sel <- sample.int(n_pac, n_pac, replace = TRUE)
  idx <- unlist(filas_por_paciente[sel], use.names = FALSE)
  rep_d <- msm_fit[idx, ]
  # Identificador unico por copia: si un paciente sale dos veces, sus dos copias
  # no pueden compartir grupo o el producto acumulado los mezclaria.
  rep_d$.id <- rep(seq_along(sel), lengths(filas_por_paciente[sel]))

  dt <- try(glm(dolor_si ~ dolor_prev + LEDD_prev + motor_prev + LEDD +
                  age_yrs + sexo + disease_yrs + MoCA + tiempo_anios,
                data = rep_d, family = binomial()), silent = TRUE)
  nt <- try(glm(dolor_si ~ dolor_prev + age_yrs + sexo + disease_yrs + tiempo_anios,
                data = rep_d, family = binomial()), silent = TRUE)
  if (inherits(dt, "try-error") || inherits(nt, "try-error")) return(NA_real_)
  p1 <- predict(dt, type = "response"); p0 <- predict(nt, type = "response")
  aa <- rep_d$dolor_si
  wt <- ifelse(aa == 1, p0 / p1, (1 - p0) / (1 - p1))
  wc <- ave(wt, rep_d$.id, FUN = cumprod)
  l <- quantile(wc, c(0.01, 0.99), na.rm = TRUE)
  rep_d$.wc <- pmin(pmax(wc, l[1]), l[2])
  m <- try(lm(UPDRS3 ~ dolor_si + tiempo_anios + edad_bl + sexo + dur_bl + moca_bl,
              data = rep_d, weights = rep_d$.wc), silent = TRUE)
  if (inherits(m, "try-error")) return(NA_real_)
  coef(m)[["dolor_si"]]
}

boot_est <- replicate(B, una_replica())
boot_est <- boot_est[is.finite(boot_est)]
ic_boot <- quantile(boot_est, c(0.025, 0.975))
cat(sprintf("\n  replicas validas: %d de %d\n", length(boot_est), B))
cat(sprintf("  MSM, estimacion puntual = %.4f\n",
            comparacion$estimacion[comparacion$especificacion ==
                                     "modelo estructural marginal (IPTW estabilizado)"]))
cat(sprintf("  IC 95 %% por remuestreo  = %.4f a %.4f\n", ic_boot[1], ic_boot[2]))
salidas$msm_bootstrap <- tibble(
  especificacion = "MSM con IC por remuestreo de pacientes",
  estimacion = comparacion$estimacion[comparacion$especificacion ==
                                        "modelo estructural marginal (IPTW estabilizado)"],
  ic_bajo = ic_boot[[1]], ic_alto = ic_boot[[2]], replicas = length(boot_est))

# =============================================================================
# 4. LO QUE NO SE PUEDE PRESENTAR COMO ESTIMACION G
# =============================================================================
titulo("4. Contraste por sustitucion: NO es una estimacion g")

cat("\n  Este contraste se conserva por trazabilidad y se reporta como lo que es.\n",
    "  Mantiene la LEDD y el estado motor previos en sus valores OBSERVADOS bajo\n",
    "  los dos regimenes. Como la LEDD es, por la premisa del propio analisis, un\n",
    "  confusor AFECTADO por la exposicion previa, fijarla condiciona sobre un\n",
    "  descendiente de la exposicion. Una formula g exige simular hacia delante\n",
    "  las covariables variables en el tiempo bajo cada regimen.\n",
    "  Por tanto NO es una comprobacion independiente del modelo estructural\n",
    "  marginal, y su coincidencia con el no corrobora nada.\n", sep = "")

# Se modela el desenlace condicionando en la historia, y se promedia sobre la
# distribucion de los confusores bajo dos regimenes: dolor siempre presente y
# dolor siempre ausente. Los supuestos de modelado son distintos de los del
# IPTW, de modo que la coincidencia es informativa.
mod_y <- lm(UPDRS3 ~ dolor_si + dolor_prev + LEDD + LEDD_prev + motor_prev +
              tiempo_anios + edad_bl + sexo + dur_bl + moca_bl, data = msm_fit)

d1 <- msm_fit |> mutate(dolor_si = 1, dolor_prev = 1)
d0 <- msm_fit |> mutate(dolor_si = 0, dolor_prev = 0)
gcomp <- mean(predict(mod_y, d1)) - mean(predict(mod_y, d0))

g_boot <- replicate(B, {
  sel <- sample.int(n_pac, n_pac, replace = TRUE)
  rep_d <- msm_fit[unlist(filas_por_paciente[sel], use.names = FALSE), ]
  m <- try(lm(UPDRS3 ~ dolor_si + dolor_prev + LEDD + LEDD_prev + motor_prev +
                tiempo_anios + edad_bl + sexo + dur_bl + moca_bl, data = rep_d),
           silent = TRUE)
  if (inherits(m, "try-error")) return(NA_real_)
  mean(predict(m, rep_d |> mutate(dolor_si = 1, dolor_prev = 1))) -
    mean(predict(m, rep_d |> mutate(dolor_si = 0, dolor_prev = 0)))
})
g_boot <- g_boot[is.finite(g_boot)]
ic_g <- quantile(g_boot, c(0.025, 0.975))
cat(sprintf("\n  contraste por sustitucion (dolor siempre vs nunca) = %.4f\n", gcomp))
cat(sprintf("  IC 95 %% por remuestreo               = %.4f a %.4f (%d replicas)\n",
            ic_g[1], ic_g[2], length(g_boot)))
salidas$gcomp <- tibble(especificacion = "sustitucion con covariables fijadas (NO es formula g)",
                        estimacion = gcomp, ic_bajo = ic_g[[1]], ic_alto = ic_g[[2]],
                        replicas = length(g_boot))

# =============================================================================
# SINTESIS
# =============================================================================
titulo("Sintesis del analisis 3")
sint <- bind_rows(
  comparacion |> select(especificacion, estimacion, ic_bajo, ic_alto, p),
  salidas$msm_bootstrap |> select(especificacion, estimacion, ic_bajo, ic_alto) |>
    mutate(p = NA_real_),
  salidas$gcomp |> select(especificacion, estimacion, ic_bajo, ic_alto) |>
    mutate(p = NA_real_)
)
print(as.data.frame(sint), digits = 4)
salidas$sintesis <- sint

subtitulo("Estatus del modelo estructural marginal")
estatus <- tibble(
  regla = "dolor(t-1) -> LEDD(t) | LEDD(t-1) distinto de cero",
  p_observada = est_l$p[1],
  cumplida = REGLA_CUMPLIDA,
  consecuencia = if (REGLA_CUMPLIDA) "MSM como analisis principal"
                 else "MSM DEGRADADO a analisis de sensibilidad")
print(as.data.frame(estatus), digits = 4)
salidas$estatus <- estatus
guardar_tabla(estatus, "t05_estatus_regla.csv")

titulo("Guardado")
guardar_tabla(est_l, "t05_dolor_a_ledd.csv")
guardar_tabla(salidas$ledd_a_dolor, "t05_ledd_a_dolor.csv")
guardar_tabla(salidas$pesos_iptw, "t05_pesos_iptw.csv")
guardar_tabla(salidas$balance, "t05_balance.csv")
guardar_tabla(sint, "t05_sintesis_msm.csv")
saveRDS(salidas, file.path(PAPER_MOD, "msm_ledd.rds"))

cat("\n\nListo: R/paper/05_msm_ledd.R\n")
