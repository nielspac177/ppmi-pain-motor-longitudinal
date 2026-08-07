#!/usr/bin/env Rscript
# =============================================================================
# ARTICULO — Analisis 2: la estructura longitudinal, con la atricion modelada
#
# Los resultados preliminares no resistian cuatro comprobaciones (documentado en
# docs/paper/01-resultados-longitudinales-preliminares.md). Este script las
# enfrenta todas antes de dar por buena ninguna cifra:
#
#   1  Atricion. Quien se pierde y por que. Comparacion formal.
#   2  Ponderacion por probabilidad inversa de censura (IPCW).
#   3  Nivel frente a pendiente. El modelo mixto es el resultado incomodo.
#   4  ANCOVA frente a puntuacion de cambio. La paradoja de Lord, sin esconderla.
#   5  Horizontes V04 a V12, con y sin ponderacion.
#   6  La prueba discriminante: siete sintomas basales, un solo desenlace.
#   7  E-values.
#
# Ejecutar:  Rscript R/paper/04_longitudinal.R
# =============================================================================

source(file.path(Sys.getenv("TESIS_ROOT", unset = getwd()), "R", "paper", "00_comun.R"))
suppressPackageStartupMessages({
  library(lme4); library(lmerTest); library(sandwich); library(lmtest)
  library(EValue); library(geepack)
})

set.seed(SEED)
titulo("ANALISIS 2 — ESTRUCTURA LONGITUDINAL Y ATRICION")

d <- cargar_largo("off")
dm <- d |> filter(!is.na(UPDRS3), !is.na(NP1PAIN))
salidas <- list()

# Basales de todos los pacientes con dato basal.
bl <- d |> filter(EVENT_ID == "BL") |>
  select(PATNO, dolor_bl = dolor_int, dolor_si_bl = dolor_si, motor_bl = UPDRS3,
         edad_bl = age_yrs, sexo, dur_bl = disease_yrs, moca_bl = MoCA,
         HY_bl = HY, ledd_bl = LEDD, gds_bl = GDS, stai_bl = STAI_state,
         rbd_bl = RBDSQ, ess_bl = ESS, scopa_bl = SCOPA_AUT,
         updrs2_bl = UPDRS2, fenotipo_bl = fenotipo, log_ratio_bl = log_ratio)

# =============================================================================
# 1. ATRICION: QUIEN SE PIERDE
# =============================================================================
titulo("1. Atricion: quien se pierde y en que se diferencia")

seguimiento <- dm |>
  group_by(PATNO) |>
  summarise(visitas = n(), ultima = max(as.integer(EVENT_ID)), .groups = "drop")

# Indicador de presencia en cada visita, entre quienes tienen basal.
presencia <- expand_grid(PATNO = bl$PATNO, EVENT_ID = factor(VISITAS, levels = VISITAS)) |>
  left_join(dm |> mutate(presente = 1L) |> select(PATNO, EVENT_ID, presente),
            by = c("PATNO", "EVENT_ID")) |>
  mutate(presente = replace_na(presente, 0L)) |>
  left_join(bl, by = "PATNO")

subtitulo("Retencion por visita, entre quienes tienen basal")
ret <- presencia |> group_by(EVENT_ID) |>
  summarise(n_presente = sum(presente), n_total = n(),
            pct = 100 * mean(presente), .groups = "drop")
print(ret)
salidas$retencion <- ret

# Comparacion formal de quienes continuan y quienes se pierden en cada horizonte.
subtitulo("Predictores basales de seguir en el estudio (regresion logistica)")
attr_mod <- map_dfr(setdiff(VISITAS, "BL"), function(v) {
  sub <- presencia |> filter(EVENT_ID == v)
  m <- glm(presente ~ dolor_bl + motor_bl + edad_bl + sexo + dur_bl + moca_bl,
           data = sub, family = binomial())
  broom::tidy(m) |>
    filter(term != "(Intercept)") |>
    transmute(visita = v, termino = term, OR = exp(estimate),
              ic_bajo = exp(estimate - 1.96 * std.error),
              ic_alto = exp(estimate + 1.96 * std.error), p = p.value)
})
print(as.data.frame(attr_mod |> filter(termino %in% c("dolor_bl", "motor_bl"))), digits = 4)
salidas$atricion_predictores <- attr_mod

cat("\n  LECTURA. Si el dolor basal predice el abandono, la perdida NO es\n",
    " completamente al azar y los horizontes largos estan seleccionados. Es la\n",
    " razon por la que se pondera.\n", sep = "")

# =============================================================================
# 2. PONDERACION POR PROBABILIDAD INVERSA DE CENSURA
# =============================================================================
titulo("2. Pesos por probabilidad inversa de censura (IPCW)")

# Pesos estabilizados: numerador con solo la exposicion basal, denominador con el
# conjunto completo de predictores basales de la permanencia. Se calculan por
# visita, sobre el conjunto que llego a la visita anterior.
PRED_IPCW <- c("dolor_bl", "motor_bl", "edad_bl", "sexo", "dur_bl", "moca_bl",
               "gds_bl", "stai_bl", "rbd_bl", "ess_bl", "scopa_bl",
               "updrs2_bl", "ledd_bl")

calcular_ipcw <- function(visita) {
  # Los dos modelos deben ajustarse sobre EL MISMO conjunto de filas: si el
  # denominador pierde casos por covariables ausentes y el numerador no, las
  # predicciones no se alinean y el cociente queda desplazado. Se impone caso
  # completo sobre todos los predictores antes de ajustar nada.
  sub <- presencia |> filter(EVENT_ID == visita) |>
    drop_na(all_of(PRED_IPCW))
  den <- glm(reformulate(PRED_IPCW, response = "presente"),
             data = sub, family = binomial())
  num <- glm(presente ~ dolor_bl, data = sub, family = binomial())
  stopifnot("los modelos de IPCW no comparten filas" =
              nobs(den) == nobs(num) && nobs(den) == nrow(sub))
  tibble(PATNO = sub$PATNO, EVENT_ID = visita, presente = sub$presente,
         w = predict(num, type = "response") / predict(den, type = "response")) |>
    filter(presente == 1)
}

# ---------------------------------------------------------------------------
# IPCW SECUENCIAL con predictores VARIABLES EN EL TIEMPO.
#
# El modelo anterior usaba solo covariables basales y producia pesos casi
# constantes. Eso admite dos lecturas: que la censura sea casi al azar dado lo
# basal, o que el modelo este infraajustado frente a predictores que si varian.
# Como la severidad motora basal predice el abandono cada vez mas con el
# horizonte, la severidad ACTUAL deberia predecirlo aun mejor, de modo que hay
# que darle la oportunidad de hacerlo antes de concluir que la atricion es
# inocua. Se modela la probabilidad de seguir en la visita k CONDICIONADA a
# haber estado en la k-1, con el estado de la visita k-1 como predictor.
PRED_TV <- c("dolor_prev", "motor_prev", "moca_prev", "ledd_prev")

calcular_ipcw_tv <- function(visita) {
  idx <- match(visita, VISITAS)
  previa <- VISITAS[idx - 1]

  # El estado previo se toma de la visita PROGRAMADA anterior, no de la ultima
  # observada. Tomarlo de la ultima observada solo incluiria a quienes siguieron,
  # de modo que el desenlace del modelo de censura no tendria variacion y el
  # peso seria constante por construccion.
  prev <- dm |> filter(EVENT_ID == previa) |>
    select(PATNO, dolor_prev = dolor_int, motor_prev = UPDRS3,
           moca_prev = MoCA, ledd_prev = LEDD)

  sub <- presencia |> filter(EVENT_ID == visita) |>
    inner_join(prev, by = "PATNO") |>
    drop_na(all_of(c(PRED_IPCW, PRED_TV)))

  if (nrow(sub) < 60 || n_distinct(sub$presente) < 2) return(NULL)
  den <- glm(reformulate(c(PRED_IPCW, PRED_TV), response = "presente"),
             data = sub, family = binomial())
  num <- glm(presente ~ dolor_bl, data = sub, family = binomial())
  stopifnot(nobs(den) == nobs(num), nobs(den) == nrow(sub))
  tibble(PATNO = sub$PATNO, EVENT_ID = visita, presente = sub$presente,
         w = predict(num, type = "response") / predict(den, type = "response"))
}

pesos_tv <- map_dfr(setdiff(VISITAS, "BL"), calcular_ipcw_tv)
if (nrow(pesos_tv)) {
  pesos_tv <- pesos_tv |>
    filter(presente == 1) |>
    mutate(EVENT_ID = factor(EVENT_ID, levels = VISITAS)) |>
    arrange(PATNO, EVENT_ID) |>
    group_by(PATNO) |>
    mutate(w_acum = cumprod(w)) |>
    ungroup()
  lim_tv <- quantile(pesos_tv$w_acum, c(0.01, 0.99), na.rm = TRUE)
  pesos_tv <- pesos_tv |> mutate(w_tv = pmin(pmax(w_acum, lim_tv[1]), lim_tv[2]))

  subtitulo("Pesos SECUENCIALES con predictores variables en el tiempo")
  salidas$pesos_tv <- pesos_tv |> group_by(EVENT_ID) |>
    summarise(n = n(), media = mean(w_tv), de = sd(w_tv),
              min = min(w_tv), max = max(w_tv), .groups = "drop")
  print(as.data.frame(salidas$pesos_tv), digits = 4)
  cat(sprintf("\n  Recorrido global de los pesos secuenciales: %.3f a %.3f\n",
              min(pesos_tv$w_tv), max(pesos_tv$w_tv)))
  cat("\n  LECTURA. Si estos pesos siguen proximos a uno con predictores que SI\n",
      "  varian en el tiempo, la censura es realmente poco informativa dado lo\n",
      "  medido. Si se dispersan, el modelo basal estaba infraajustado y la\n",
      "  afirmacion de que la atricion apenas distorsiona no se sostiene.\n", sep = "")
}

pesos <- map_dfr(setdiff(VISITAS, "BL"), calcular_ipcw)
# Truncado al percentil 1 y 99: los pesos extremos inflan la varianza sin
# aportar informacion, y es practica estandar declararlo.
lim <- quantile(pesos$w, c(0.01, 0.99), na.rm = TRUE)
pesos <- pesos |> mutate(w_trunc = pmin(pmax(w, lim[1]), lim[2]))

subtitulo("Distribucion de los pesos estabilizados")
print(pesos |> group_by(EVENT_ID) |>
        summarise(n = n(), media = mean(w_trunc), min = min(w_trunc),
                  max = max(w_trunc), .groups = "drop"))
cat(sprintf("\n  Truncado en [%.3f, %.3f] (percentiles 1 y 99)\n", lim[1], lim[2]))
salidas$pesos <- pesos |> group_by(EVENT_ID) |>
  summarise(n = n(), media = mean(w_trunc), de = sd(w_trunc),
            min = min(w_trunc), max = max(w_trunc), .groups = "drop")

# =============================================================================
# 3. NIVEL FRENTE A PENDIENTE
# =============================================================================
titulo("3. El resultado incomodo: nivel frente a pendiente")

mixto_d <- dm |>
  inner_join(bl |> select(PATNO, dolor_bl, motor_bl, edad_bl, dur_bl, moca_bl,
                          fenotipo_bl, log_ratio_bl), by = "PATNO") |>
  filter(!is.na(tiempo_anios), !is.na(dolor_bl))

# El tiempo se CENTRA en la mitad del seguimiento. Sin centrar, el efecto
# principal del dolor basal es su efecto en tiempo = 0, es decir, la asociacion
# transversal en la propia visita basal, y llamarla "nivel a lo largo del
# seguimiento" seria describir mal lo que estima.
T_CENTRO <- median(mixto_d$tiempo_anios[mixto_d$tiempo_anios > 0], na.rm = TRUE)
mixto_d <- mixto_d |> mutate(tiempo_c = tiempo_anios - T_CENTRO)
cat(sprintf("\nTiempo centrado en %.2f anios (mediana del seguimiento no basal)\n", T_CENTRO))

m_mixto <- lmerTest::lmer(
  UPDRS3 ~ dolor_bl * tiempo_c + edad_bl + sexo + dur_bl + moca_bl +
    (1 + tiempo_c | PATNO),
  data = mixto_d, REML = TRUE, control = lmerControl(optimizer = "bobyqa"))

cf <- summary(m_mixto)$coefficients
subtitulo("Modelo mixto con pendiente aleatoria")
cat(sprintf("  observaciones = %d, pacientes = %d\n", nobs(m_mixto), ngrps(m_mixto)[[1]]))
print(round(cf[c("dolor_bl", "tiempo_c", "dolor_bl:tiempo_c"), ], 5))

mixto_tab <- tibble(
  termino = c("dolor basal (nivel a mitad de seguimiento)", "tiempo (pendiente)",
              "dolor basal x tiempo"),
  estimacion = cf[c("dolor_bl", "tiempo_c", "dolor_bl:tiempo_c"), "Estimate"],
  ee = cf[c("dolor_bl", "tiempo_c", "dolor_bl:tiempo_c"), "Std. Error"],
  p = cf[c("dolor_bl", "tiempo_c", "dolor_bl:tiempo_c"), "Pr(>|t|)"]) |>
  mutate(ic_bajo = estimacion - 1.96 * ee, ic_alto = estimacion + 1.96 * ee)
print(as.data.frame(mixto_tab), digits = 4)
salidas$mixto <- mixto_tab

cat("\n  LECTURA. Si la interaccion con el tiempo es nula, la afirmacion\n",
    " defendible es que el dolor marca un NIVEL mas alto, no una pendiente mas\n",
    " rapida. Escribirlo al reves seria sobrevender.\n", sep = "")

# El mismo modelo, ponderado por IPCW.
mixto_d_w <- mixto_d
mixto_w <- mixto_d_w |>
  left_join(pesos |> select(PATNO, EVENT_ID, w_trunc), by = c("PATNO", "EVENT_ID")) |>
  mutate(w_trunc = if_else(EVENT_ID == "BL", 1, w_trunc)) |>
  filter(!is.na(w_trunc))

# lme4 interpreta `weights` como pesos de PRECISION (inversa de la varianza), no
# como pesos de muestreo: no reponderaria la estructura de efectos aleatorios y
# sus errores estandar serian los del modelo, no robustos. Una ponderacion por
# probabilidad inversa exige ecuaciones de estimacion generalizadas con varianza
# robusta por conglomerado, que es lo que se usa aqui.
# geeglm no admite filas incompletas: elimina las de la matriz de diseno pero no
# del vector de pesos ni del identificador de conglomerado, y falla o desalinea.
# Se impone caso completo ANTES de ajustar.
mixto_w <- mixto_w |>
  drop_na(UPDRS3, dolor_bl, tiempo_c, edad_bl, sexo, dur_bl, moca_bl, w_trunc) |>
  arrange(PATNO, EVENT_ID)
mixto_w$.w <- mixto_w$w_trunc
m_mixto_w <- geepack::geeglm(
  UPDRS3 ~ dolor_bl * tiempo_c + edad_bl + sexo + dur_bl + moca_bl,
  data = mixto_w, id = PATNO, weights = .w, corstr = "exchangeable")
cfw <- summary(m_mixto_w)$coefficients
subtitulo("Modelo PONDERADO por IPCW (GEE con varianza robusta por paciente)")
print(round(cfw[c("dolor_bl", "tiempo_c", "dolor_bl:tiempo_c"), ], 5))
salidas$mixto_ipcw <- tibble(
  termino = c("dolor basal (nivel a mitad de seguimiento)", "tiempo (pendiente)",
              "dolor basal x tiempo"),
  estimacion = cfw[c("dolor_bl", "tiempo_c", "dolor_bl:tiempo_c"), "Estimate"],
  ee = cfw[c("dolor_bl", "tiempo_c", "dolor_bl:tiempo_c"), "Std.err"],
  p = cfw[c("dolor_bl", "tiempo_c", "dolor_bl:tiempo_c"), "Pr(>|W|)"])

# El MISMO modelo con los pesos SECUENCIALES. Calcular una distribucion de pesos
# y no ajustar nada con ella no permite afirmar que las conclusiones no cambian:
# hay que ajustar el modelo y mirarlo.
if (exists("pesos_tv") && nrow(pesos_tv)) {
  mixto_tv <- mixto_d |>
    left_join(pesos_tv |> select(PATNO, EVENT_ID, w_tv), by = c("PATNO", "EVENT_ID")) |>
    mutate(w_tv = if_else(EVENT_ID == "BL", 1, w_tv)) |>
    drop_na(UPDRS3, dolor_bl, tiempo_c, edad_bl, sexo, dur_bl, moca_bl, w_tv) |>
    arrange(PATNO, EVENT_ID)
  mixto_tv$.w <- mixto_tv$w_tv
  m_tv <- geepack::geeglm(
    UPDRS3 ~ dolor_bl * tiempo_c + edad_bl + sexo + dur_bl + moca_bl,
    data = mixto_tv, id = PATNO, weights = .w, corstr = "exchangeable")
  cft <- summary(m_tv)$coefficients
  subtitulo("Modelo PONDERADO con los pesos SECUENCIALES (predictores variables)")
  cat(sprintf("  observaciones = %d, pacientes = %d\n",
              nrow(mixto_tv), n_distinct(mixto_tv$PATNO)))
  print(round(cft[c("dolor_bl", "tiempo_c", "dolor_bl:tiempo_c"), ], 5))
  salidas$mixto_ipcw_tv <- tibble(
    termino = c("dolor basal (nivel a mitad de seguimiento)", "tiempo (pendiente)",
                "dolor basal x tiempo"),
    n_obs = nrow(mixto_tv),
    estimacion = cft[c("dolor_bl", "tiempo_c", "dolor_bl:tiempo_c"), "Estimate"],
    ee = cft[c("dolor_bl", "tiempo_c", "dolor_bl:tiempo_c"), "Std.err"],
    p = cft[c("dolor_bl", "tiempo_c", "dolor_bl:tiempo_c"), "Pr(>|W|)"])
}

# =============================================================================
# 4. ANCOVA FRENTE A PUNTUACION DE CAMBIO
# =============================================================================
titulo("4. ANCOVA frente a puntuacion de cambio (paradoja de Lord)")

panel_v04 <- dm |> filter(EVENT_ID == "V04") |>
  select(PATNO, motor_v04 = UPDRS3) |>
  inner_join(bl, by = "PATNO") |>
  filter(!is.na(motor_v04), !is.na(dolor_bl), !is.na(motor_bl)) |>
  mutate(cambio = motor_v04 - motor_bl)

f_lord <- function(m, et) {
  ct <- lmtest::coeftest(m, vcov. = sandwich::vcovHC(m, type = "HC3"))
  tibble(especificacion = et, n = nobs(m),
         estimacion = ct["dolor_bl", 1], ee = ct["dolor_bl", 2],
         ic_bajo = ct["dolor_bl", 1] - 1.96 * ct["dolor_bl", 2],
         ic_alto = ct["dolor_bl", 1] + 1.96 * ct["dolor_bl", 2],
         p = ct["dolor_bl", 4])
}

lord <- bind_rows(
  f_lord(lm(motor_v04 ~ dolor_bl + motor_bl + edad_bl + sexo + dur_bl + moca_bl,
            data = panel_v04), "ANCOVA (ajusta por el basal)"),
  f_lord(lm(cambio ~ dolor_bl + edad_bl + sexo + dur_bl + moca_bl,
            data = panel_v04), "puntuacion de cambio (sin ajustar el basal)")
)
print(as.data.frame(lord), digits = 4)
salidas$lord <- lord

cat("\n  LECTURA. Las dos especificaciones responden preguntas distintas y no\n",
    " tienen por que coincidir. Se reportan ambas; ninguna es 'la correcta'.\n", sep = "")

# =============================================================================
# 5. HORIZONTES, CON Y SIN PONDERACION
# =============================================================================
titulo("5. Horizontes V04 a V12, crudos y ponderados por IPCW")

horizonte <- map_dfr(setdiff(VISITAS, "BL"), function(v) {
  sub <- dm |> filter(EVENT_ID == v) |>
    select(PATNO, motor_v = UPDRS3) |>
    inner_join(bl, by = "PATNO") |>
    left_join(pesos |> filter(EVENT_ID == v) |> select(PATNO, w_trunc), by = "PATNO") |>
    filter(!is.na(motor_v), !is.na(dolor_bl), !is.na(motor_bl), !is.na(moca_bl))
  if (nrow(sub) < 40) return(NULL)
  m0 <- lm(motor_v ~ dolor_bl + motor_bl + edad_bl + sexo + dur_bl + moca_bl, data = sub)
  sw <- sub |> filter(!is.na(w_trunc))
  m1 <- lm(motor_v ~ dolor_bl + motor_bl + edad_bl + sexo + dur_bl + moca_bl,
           data = sw, weights = w_trunc)
  f <- function(m, et) {
    ct <- lmtest::coeftest(m, vcov. = sandwich::vcovHC(m, type = "HC3"))
    tibble(visita = v, especificacion = et, n = nobs(m),
           estimacion = ct["dolor_bl", 1],
           ic_bajo = ct["dolor_bl", 1] - 1.96 * ct["dolor_bl", 2],
           ic_alto = ct["dolor_bl", 1] + 1.96 * ct["dolor_bl", 2],
           p = ct["dolor_bl", 4])
  }
  bind_rows(f(m0, "crudo"), f(m1, "ponderado IPCW"))
})
print(as.data.frame(horizonte), digits = 4)
salidas$horizontes <- horizonte

# =============================================================================
# 6. LA PRUEBA DISCRIMINANTE
# =============================================================================
titulo("6. Prueba discriminante: siete sintomas basales, el mismo desenlace")

sintomas <- c(dolor = "dolor_bl", AVD = "updrs2_bl", depresion = "gds_bl",
              ansiedad = "stai_bl", sueno_REM = "rbd_bl",
              autonomico = "scopa_bl", somnolencia = "ess_bl")

discrim <- map_dfr(names(sintomas), function(nm) {
  v <- sintomas[[nm]]
  sub <- panel_v04 |> filter(!is.na(.data[[v]]))
  sub$expo <- as.numeric(scale(sub[[v]]))
  m <- lm(motor_v04 ~ expo + motor_bl + edad_bl + sexo + dur_bl + moca_bl, data = sub)
  ct <- lmtest::coeftest(m, vcov. = sandwich::vcovHC(m, type = "HC3"))
  tibble(sintoma = nm, n = nobs(m), estimacion = ct["expo", 1],
         ic_bajo = ct["expo", 1] - 1.96 * ct["expo", 2],
         ic_alto = ct["expo", 1] + 1.96 * ct["expo", 2], p = ct["expo", 4])
}) |>
  mutate(p_holm = p.adjust(p, method = "holm"),
         p_bh = p.adjust(p, method = "BH"))
subtitulo("Efecto por desviacion estandar sobre la MDS-UPDRS III a 12 meses")
print(as.data.frame(discrim), digits = 4)
salidas$discriminante <- discrim

subtitulo("Controles negativos: otros desenlaces a 12 meses")
otros <- dm |> filter(EVENT_ID == "V04") |>
  select(PATNO, moca_v04 = MoCA, gds_v04 = GDS) |>
  inner_join(panel_v04, by = "PATNO")
ctrl <- map_dfr(c("moca_v04", "gds_v04"), function(des) {
  basal <- if (des == "moca_v04") "moca_bl" else "gds_bl"
  sub <- otros |> filter(!is.na(.data[[des]]), !is.na(.data[[basal]]))
  m <- lm(as.formula(sprintf("%s ~ dolor_bl + %s + edad_bl + sexo + dur_bl", des, basal)),
          data = sub)
  ct <- lmtest::coeftest(m, vcov. = sandwich::vcovHC(m, type = "HC3"))
  tibble(desenlace = des, n = nobs(m), estimacion = ct["dolor_bl", 1],
         ic_bajo = ct["dolor_bl", 1] - 1.96 * ct["dolor_bl", 2],
         ic_alto = ct["dolor_bl", 1] + 1.96 * ct["dolor_bl", 2], p = ct["dolor_bl", 4])
})
print(as.data.frame(ctrl), digits = 4)
salidas$controles <- ctrl

# =============================================================================
# 7. E-VALUES
# =============================================================================
titulo("7. E-values del efecto longitudinal")

# El E-value para una diferencia de medias continua se calcula sobre la escala
# estandarizada (Chinn), no sobre el coeficiente crudo. Es el error que ya se
# cometio en otro proyecto de este equipo y no se repite aqui.
sd_out <- sd(panel_v04$motor_v04, na.rm = TRUE)
est_ancova <- lord$estimacion[lord$especificacion == "ANCOVA (ajusta por el basal)"]
lo_ancova <- lord$ic_bajo[lord$especificacion == "ANCOVA (ajusta por el basal)"]

ev <- EValue::evalues.OLS(est = est_ancova, se = lord$ee[1], sd = sd_out,
                          delta = 1, true = 0)
subtitulo("E-value del ANCOVA por punto de dolor")
print(round(ev, 4))
cat(sprintf("\n  DE del desenlace usada para estandarizar: %.3f\n", sd_out))
salidas$evalue <- tibble(
  medida = "ANCOVA dolor basal -> motor V04, por punto",
  estimacion = est_ancova, ic_bajo = lo_ancova, sd_desenlace = sd_out,
  evalue_puntual = ev[2, 1], evalue_ic = ev[2, 2])
print(as.data.frame(salidas$evalue), digits = 4)

# =============================================================================
# GUARDADO
# =============================================================================
titulo("Guardado")
guardar_tabla(ret, "t04_retencion.csv")
guardar_tabla(attr_mod, "t04_atricion_predictores.csv")
guardar_tabla(salidas$pesos, "t04_pesos_ipcw.csv")
if (!is.null(salidas$pesos_tv)) guardar_tabla(salidas$pesos_tv, "t04_pesos_ipcw_tv.csv")
if (!is.null(salidas$mixto_ipcw_tv)) guardar_tabla(salidas$mixto_ipcw_tv, "t04_mixto_ipcw_tv.csv")
guardar_tabla(mixto_tab, "t04_mixto.csv")
guardar_tabla(salidas$mixto_ipcw, "t04_mixto_ipcw.csv")
guardar_tabla(lord, "t04_lord.csv")
guardar_tabla(horizonte, "t04_horizontes.csv")
guardar_tabla(discrim, "t04_discriminante.csv")
guardar_tabla(ctrl, "t04_controles_negativos.csv")
guardar_tabla(salidas$evalue, "t04_evalue.csv")
saveRDS(salidas, file.path(PAPER_MOD, "longitudinal.rds"))

cat("\n\nListo: R/paper/04_longitudinal.R\n")
