#!/usr/bin/env Rscript
# =============================================================================
# ARTICULO — Analisis 0 (prioritario): la discrepancia direccional
#
# El trabajo previo (Aim 4.3 y 4.4, mayo de 2026) encontro que los dos rezagos
# eran significativos y que en escala estandarizada la direccion motor -> dolor
# era unas tres veces mas fuerte. Un analisis posterior, restringido a la ventana
# basal -> 12 meses, concluyo lo contrario: dolor -> motor significativo
# (p = 0,009) y motor -> dolor nulo (p = 0,155). Esa asimetria sostiene parte del
# argumento del ADR 0005.
#
# Las dos cosas no pueden ser ciertas a la vez sin explicacion. Este script
# examina las cuatro explicaciones candidatas, en orden:
#
#   H1  La muestra. El Aim 4 corrio sobre N = 655, con sesgo de anticipacion en
#       la exclusion por DBS y duracion de enfermedad fijada en la basal.
#   H2  Los retardos. El Aim 4 trataba las visitas como equiespaciadas.
#   H3  La potencia. La ventana unica usa una fraccion de la informacion.
#   H4  La descomposicion entre e intra persona. Un modelo rezagado con
#       intercepto aleatorio NO separa la covariacion estable entre personas de
#       la dinamica intrapersonal. Si el dolor y la severidad motora coexisten en
#       un fenotipo estable, los dos rezagos cruzados saldran significativos por
#       la correlacion de rasgo, sin que ninguno preceda al otro.
#
# H4 es la explicacion sustantiva y la que el articulo defiende. Se contrasta con
# un modelo de panel cruzado con interceptos aleatorios (RI-CLPM, Hamaker 2015),
# que separa las dos fuentes de variacion, frente al panel cruzado clasico (CLPM)
# que las confunde.
#
# Ejecutar:  Rscript R/paper/01_direccionalidad.R
# =============================================================================

source(file.path(Sys.getenv("TESIS_ROOT", unset = getwd()), "R", "paper", "00_comun.R"))
suppressPackageStartupMessages({
  library(lme4); library(lmerTest); library(lavaan)
})

set.seed(SEED)
titulo("ANALISIS 0 — LA DISCREPANCIA DIRECCIONAL")

d <- cargar_largo("off")

# El desenlace motor y la exposicion de dolor deben existir en la fila para que
# esa visita entre en cualquier modelo rezagado.
d <- d |> filter(!is.na(UPDRS3) | !is.na(NP1PAIN))

resultados <- list()

# =============================================================================
# 1. ESTRUCTURA DE LOS REZAGOS
# =============================================================================
titulo("1. Estructura de los rezagos observados")

lag_d <- d |>
  arrange(PATNO, EVENT_ID) |>
  group_by(PATNO) |>
  mutate(
    ord = as.integer(EVENT_ID),
    lag_ord      = ord - lag(ord),
    lag_anios    = tiempo_anios - lag(tiempo_anios),
    dolor_lag    = lag(dolor_int),
    motor_lag    = lag(UPDRS3),
    LEDD_lag     = lag(LEDD),
    ratio_lag    = lag(log_ratio)
  ) |>
  ungroup() |>
  filter(!is.na(lag_ord))

cat("\nSalto en ORDEN de visita entre visitas consecutivas observadas:\n")
print(table(lag_d$lag_ord))
cat(sprintf("\nPares no adyacentes: %d de %d (%.1f %%)\n",
            sum(lag_d$lag_ord > 1), nrow(lag_d),
            100 * mean(lag_d$lag_ord > 1)))
cat("\nTiempo REAL transcurrido en esos pares (anios):\n")
print(summary(lag_d$lag_anios))

# =============================================================================
# 2. H1 y H2 — REPLICA DEL AIM 4 SOBRE LA MUESTRA CORREGIDA
# =============================================================================
titulo("2. Replica del Aim 4.3 y 4.4 sobre la muestra corregida")

# Escalas de referencia para poder comparar las dos direcciones. Se calculan
# sobre las observaciones que efectivamente entran en los modelos rezagados.
base_lag <- lag_d |> filter(!is.na(dolor_lag), !is.na(motor_lag),
                            !is.na(UPDRS3), !is.na(NP1PAIN))
SD_DOLOR <- sd(base_lag$dolor_int, na.rm = TRUE)
SD_MOTOR <- sd(base_lag$UPDRS3, na.rm = TRUE)
cat(sprintf("\nDE del dolor  = %.4f\nDE del motor = %.4f\n", SD_DOLOR, SD_MOTOR))

ajustar_rezago <- function(datos, formula, termino, etiqueta, sd_desenlace, sd_exposicion) {
  m <- lmerTest::lmer(formula, data = datos, REML = TRUE,
                      control = lmerControl(optimizer = "bobyqa"))
  sing <- isSingular(m, tol = 1e-4)
  cf <- summary(m)$coefficients
  fila <- cf[termino, ]
  est <- fila[["Estimate"]]; ee <- fila[["Std. Error"]]; p <- fila[["Pr(>|t|)"]]
  tibble(
    modelo = etiqueta,
    n_obs = nobs(m), n_pac = ngrps(m)[[1]],
    estimacion = est, ee = ee,
    ic_bajo = est - 1.96 * ee, ic_alto = est + 1.96 * ee,
    p = p,
    # Estandarizada: cambio en DE del desenlace por DE de la exposicion.
    est_de = est * sd_exposicion / sd_desenlace,
    ic_bajo_de = (est - 1.96 * ee) * sd_exposicion / sd_desenlace,
    ic_alto_de = (est + 1.96 * ee) * sd_exposicion / sd_desenlace,
    singular = sing
  )
}

subtitulo("2a. Especificacion original: rezago por ORDEN de visita, sin tiempo real")

m43 <- ajustar_rezago(
  base_lag,
  UPDRS3 ~ dolor_lag + motor_lag + age_yrs + sexo + disease_yrs + MoCA + (1 | PATNO),
  "dolor_lag", "4.3 dolor(t-1) -> motor(t), orden de visita", SD_MOTOR, SD_DOLOR)

m44 <- ajustar_rezago(
  base_lag,
  NP1PAIN ~ motor_lag + dolor_lag + age_yrs + sexo + disease_yrs + MoCA + (1 | PATNO),
  "motor_lag", "4.4 motor(t-1) -> dolor(t), orden de visita", SD_DOLOR, SD_MOTOR)

print(bind_rows(m43, m44) |> select(modelo, n_obs, n_pac, estimacion, ic_bajo, ic_alto, p, est_de, singular))

subtitulo("2b. Retardo corregido: se anade el tiempo real transcurrido")

# El tiempo real entre las dos visitas del par entra como covariable. Si los
# retardos irregulares explicaran la discrepancia, el coeficiente cambiaria aqui.
m43t <- ajustar_rezago(
  base_lag,
  UPDRS3 ~ dolor_lag + motor_lag + lag_anios + age_yrs + sexo + disease_yrs + MoCA + (1 | PATNO),
  "dolor_lag", "4.3 con tiempo real transcurrido", SD_MOTOR, SD_DOLOR)

m44t <- ajustar_rezago(
  base_lag,
  NP1PAIN ~ motor_lag + dolor_lag + lag_anios + age_yrs + sexo + disease_yrs + MoCA + (1 | PATNO),
  "motor_lag", "4.4 con tiempo real transcurrido", SD_DOLOR, SD_MOTOR)

subtitulo("2c. Solo pares adyacentes (salto de orden = 1)")

adj <- base_lag |> filter(lag_ord == 1)
m43a <- ajustar_rezago(
  adj,
  UPDRS3 ~ dolor_lag + motor_lag + age_yrs + sexo + disease_yrs + MoCA + (1 | PATNO),
  "dolor_lag", "4.3 solo pares adyacentes", SD_MOTOR, SD_DOLOR)
m44a <- ajustar_rezago(
  adj,
  NP1PAIN ~ motor_lag + dolor_lag + age_yrs + sexo + disease_yrs + MoCA + (1 | PATNO),
  "motor_lag", "4.4 solo pares adyacentes", SD_DOLOR, SD_MOTOR)

rezagos <- bind_rows(m43, m44, m43t, m44t, m43a, m44a)
print(rezagos |> select(modelo, n_obs, estimacion, ic_bajo, ic_alto, p, est_de, singular))
resultados$rezagos <- rezagos

# =============================================================================
# 3. H3 — LA VENTANA UNICA BASAL -> 12 MESES
# =============================================================================
titulo("3. La ventana unica basal -> 12 meses (el analisis posterior)")

bl <- d |> filter(EVENT_ID == "BL") |>
  select(PATNO, dolor_bl = dolor_int, motor_bl = UPDRS3, HY_bl = HY,
         age_bl = age_yrs, sexo, dur_bl = disease_yrs, moca_bl = MoCA,
         ledd_bl = LEDD, ratio_bl = log_ratio, fenotipo_bl = fenotipo)
v04 <- d |> filter(EVENT_ID == "V04") |>
  select(PATNO, dolor_v04 = dolor_int, motor_v04 = UPDRS3, HY_v04 = HY)
panel <- inner_join(bl, v04, by = "PATNO")

cat(sprintf("\nPanel BL -> V04: n = %d\n", nrow(panel)))

sd_dolor_bl <- sd(panel$dolor_bl, na.rm = TRUE)
sd_motor_bl <- sd(panel$motor_bl, na.rm = TRUE)

vent1 <- lm(motor_v04 ~ dolor_bl + motor_bl + age_bl + sexo + dur_bl + moca_bl, data = panel)
vent2 <- lm(dolor_v04 ~ motor_bl + dolor_bl + age_bl + sexo + dur_bl + moca_bl, data = panel)

f_vent <- function(m, term, etiqueta, sd_des, sd_exp) {
  s <- summary(m)$coefficients[term, ]
  est <- s[["Estimate"]]; ee <- s[["Std. Error"]]; p <- s[["Pr(>|t|)"]]
  tibble(modelo = etiqueta, n_obs = nobs(m), n_pac = nobs(m),
         estimacion = est, ee = ee,
         ic_bajo = est - 1.96 * ee, ic_alto = est + 1.96 * ee, p = p,
         est_de = est * sd_exp / sd_des,
         ic_bajo_de = (est - 1.96 * ee) * sd_exp / sd_des,
         ic_alto_de = (est + 1.96 * ee) * sd_exp / sd_des,
         singular = NA)
}

# Los dos modelos anteriores NO se ajustan sobre las mismas personas: el dolor
# esta disponible en mas visitas que la puntuacion motora, de modo que cada
# direccion usa su propio conjunto maximo. Para comparar direcciones hay que
# hacerlo sobre el conjunto COMUN completo, y esa es la comparacion que explica
# la asimetria publicada en el trabajo previo.
comun <- panel |>
  filter(!is.na(dolor_bl), !is.na(motor_bl), !is.na(dolor_v04), !is.na(motor_v04),
         !is.na(age_bl), !is.na(dur_bl), !is.na(moca_bl))
vent1c <- lm(motor_v04 ~ dolor_bl + motor_bl + age_bl + sexo + dur_bl + moca_bl, data = comun)
vent2c <- lm(dolor_v04 ~ motor_bl + dolor_bl + age_bl + sexo + dur_bl + moca_bl, data = comun)

ventana <- bind_rows(
  f_vent(vent1, "dolor_bl", "Conjunto propio: dolor -> motor", sd_motor_bl, sd_dolor_bl),
  f_vent(vent2, "motor_bl", "Conjunto propio: motor -> dolor", sd_dolor_bl, sd_motor_bl),
  f_vent(vent1c, "dolor_bl", "Panel COMUN completo: dolor -> motor", sd_motor_bl, sd_dolor_bl),
  f_vent(vent2c, "motor_bl", "Panel COMUN completo: motor -> dolor", sd_dolor_bl, sd_motor_bl)
)
cat(sprintf("\nPanel comun completo: n = %d (frente a %d y %d de cada conjunto propio)\n",
            nrow(comun), nobs(vent1), nobs(vent2)))
print(ventana |> select(modelo, n_obs, estimacion, ic_bajo, ic_alto, p, est_de))
resultados$ventana <- ventana

# =============================================================================
# 4. H4 — DESCOMPOSICION ENTRE PERSONAS / INTRA PERSONA
# =============================================================================
titulo("4. Panel cruzado: CLPM clasico frente a RI-CLPM")

# Formato ancho, una fila por paciente, seis olas.
ancho <- d |>
  select(PATNO, EVENT_ID, dolor_int, UPDRS3) |>
  pivot_wider(names_from = EVENT_ID, values_from = c(dolor_int, UPDRS3),
              names_sep = "_")
nombres_d <- paste0("dolor_int_", VISITAS)
nombres_m <- paste0("UPDRS3_", VISITAS)
ancho <- ancho |> select(PATNO, all_of(nombres_d), all_of(nombres_m))
names(ancho) <- c("PATNO", paste0("d", 1:6), paste0("m", 1:6))

cat(sprintf("\nPacientes en el panel ancho: %d\n", nrow(ancho)))
cat("Observaciones no ausentes por ola (dolor / motor):\n")
print(rbind(dolor = colSums(!is.na(ancho[, paste0("d", 1:6)])),
            motor = colSums(!is.na(ancho[, paste0("m", 1:6)]))))

# ------------------------------------------------------------- CLPM clasico --
# Rezagos cruzados con restriccion de igualdad entre olas. NO separa la
# variacion estable entre personas: es el modelo cuya logica siguio el Aim 4.
clpm_txt <- '
  # autorregresivos y rezagos cruzados, restringidos a ser iguales entre olas
  d2 ~ a*d1 + b*m1
  d3 ~ a*d2 + b*m2
  d4 ~ a*d3 + b*m3
  d5 ~ a*d4 + b*m4
  d6 ~ a*d5 + b*m5
  m2 ~ c*d1 + e*m1
  m3 ~ c*d2 + e*m2
  m4 ~ c*d3 + e*m3
  m5 ~ c*d4 + e*m4
  m6 ~ c*d5 + e*m5
  # covarianzas contemporaneas de los residuos
  d1 ~~ m1
  d2 ~~ m2
  d3 ~~ m3
  d4 ~~ m4
  d5 ~~ m5
  d6 ~~ m6
'

# --------------------------------------------------------------- RI-CLPM -----
# Hamaker, Kuiper y Grasman (2015). Un intercepto aleatorio por constructo capta
# la diferencia estable entre personas; los rezagos cruzados se estiman sobre las
# desviaciones intrapersonales respecto de ese nivel propio.
riclpm_txt <- '
  # interceptos aleatorios (rasgo estable de cada persona)
  RId =~ 1*d1 + 1*d2 + 1*d3 + 1*d4 + 1*d5 + 1*d6
  RIm =~ 1*m1 + 1*m2 + 1*m3 + 1*m4 + 1*m5 + 1*m6

  # componentes intrapersonales
  wd1 =~ 1*d1
  wd2 =~ 1*d2
  wd3 =~ 1*d3
  wd4 =~ 1*d4
  wd5 =~ 1*d5
  wd6 =~ 1*d6
  wm1 =~ 1*m1
  wm2 =~ 1*m2
  wm3 =~ 1*m3
  wm4 =~ 1*m4
  wm5 =~ 1*m5
  wm6 =~ 1*m6

  # varianza residual de los indicadores fijada a cero
  d1 ~~ 0*d1
  d2 ~~ 0*d2
  d3 ~~ 0*d3
  d4 ~~ 0*d4
  d5 ~~ 0*d5
  d6 ~~ 0*d6
  m1 ~~ 0*m1
  m2 ~~ 0*m2
  m3 ~~ 0*m3
  m4 ~~ 0*m4
  m5 ~~ 0*m5
  m6 ~~ 0*m6

  # dinamica intrapersonal, restringida a ser igual entre olas
  wd2 ~ a*wd1 + b*wm1
  wd3 ~ a*wd2 + b*wm2
  wd4 ~ a*wd3 + b*wm3
  wd5 ~ a*wd4 + b*wm4
  wd6 ~ a*wd5 + b*wm5
  wm2 ~ c*wd1 + e*wm1
  wm3 ~ c*wd2 + e*wm2
  wm4 ~ c*wd3 + e*wm3
  wm5 ~ c*wd4 + e*wm4
  wm6 ~ c*wd5 + e*wm5

  # covariacion de los rasgos estables: es el parametro de interes sustantivo
  RId ~~ RIm
  RId ~~ RId
  RIm ~~ RIm
  RId ~~ 0*wd1 + 0*wm1
  RIm ~~ 0*wd1 + 0*wm1

  # covarianzas contemporaneas intrapersonales
  wd1 ~~ wm1
  wd2 ~~ wm2
  wd3 ~~ wm3
  wd4 ~~ wm4
  wd5 ~~ wm5
  wd6 ~~ wm6
'

ajustar_sem <- function(txt, etiqueta) {
  fit <- try(lavaan::sem(txt, data = ancho, missing = "fiml",
                         estimator = "MLR", fixed.x = FALSE), silent = TRUE)
  if (inherits(fit, "try-error") || !lavaan::lavInspect(fit, "converged")) {
    cat(sprintf("\n  %s: NO converge\n", etiqueta))
    return(NULL)
  }
  cat(sprintf("\n%s: converge. n = %d\n", etiqueta, lavaan::lavInspect(fit, "ntotal")))
  fm <- lavaan::fitMeasures(fit, c("cfi.robust", "tli.robust", "rmsea.robust", "srmr"))
  cat("  ajuste: "); print(round(fm, 4))
  pe <- lavaan::parameterEstimates(fit, standardized = TRUE)
  list(fit = fit, pe = pe, fm = fm)
}

clpm <- ajustar_sem(clpm_txt, "CLPM clasico")
riclpm <- ajustar_sem(riclpm_txt, "RI-CLPM restringido")

# El modelo restringido impone igualdad de los rezagos entre olas, y esa
# restriccion se RECHAZA (ver R/paper/02_refutacion_riclpm.R, prueba R1). No se
# puede presentar como primario un modelo que los datos rechazan, de modo que el
# primario pasa a ser el LIBRE y el restringido queda como referencia.
riclpm_libre_txt <- {
  ix <- 1:6
  t <- c(paste0("RId =~ ", paste(paste0("1*d", ix), collapse = " + ")),
         paste0("RIm =~ ", paste(paste0("1*m", ix), collapse = " + ")),
         paste0("wd", ix, " =~ 1*d", ix), paste0("wm", ix, " =~ 1*m", ix),
         paste0("d", ix, " ~~ 0*d", ix), paste0("m", ix, " ~~ 0*m", ix))
  for (k in 2:6) {
    t <- c(t, sprintf("wd%d ~ a%d*wd%d + b%d*wm%d", k, k, k - 1, k, k - 1),
              sprintf("wm%d ~ c%d*wd%d + e%d*wm%d", k, k, k - 1, k, k - 1))
  }
  paste(c(t, "RId ~~ RIm", "RId ~~ RId", "RIm ~~ RIm",
          "RId ~~ 0*wd1 + 0*wm1", "RIm ~~ 0*wd1 + 0*wm1",
          paste0("wd", ix, " ~~ wm", ix)), collapse = "\n")
}
riclpm_libre <- ajustar_sem(riclpm_libre_txt, "RI-CLPM libre (PRIMARIO)")

extraer_sem <- function(obj, etiqueta_modelo) {
  if (is.null(obj)) return(NULL)
  pe <- obj$pe
  filas <- pe[pe$label %in% c("a", "b", "c", "e") & pe$op == "~", ]
  filas <- filas[!duplicated(filas$label), ]
  etiquetas <- c(a = "dolor(t-1) -> dolor(t) [autorregresivo]",
                 b = "motor(t-1) -> dolor(t) [cruzado inverso]",
                 c = "dolor(t-1) -> motor(t) [cruzado directo]",
                 e = "motor(t-1) -> motor(t) [autorregresivo]")
  tibble(
    modelo = etiqueta_modelo,
    parametro = unname(etiquetas[filas$label]),
    etiqueta = filas$label,
    estimacion = filas$est, ee = filas$se,
    ic_bajo = filas$ci.lower, ic_alto = filas$ci.upper,
    p = filas$pvalue,
    est_std = filas$std.all
  )
}

# El modelo primario es el LIBRE. Extraer solo del restringido dejaba todas las
# afirmaciones direccionales del articulo apoyadas en una especificacion cuyas
# restricciones el propio articulo reporta como rechazadas. Se extraen las vias
# del libre por ola y se resume su comportamiento.
extraer_libre <- function(obj, etiqueta) {
  if (is.null(obj)) return(NULL)
  pe <- obj$pe
  filas <- pe[grepl("^[abce][2-6]$", pe$label) & pe$op == "~", ]
  if (!nrow(filas)) return(NULL)
  tipo <- c(a = "dolor(t-1) -> dolor(t) [autorregresivo]",
            b = "motor(t-1) -> dolor(t) [cruzado inverso]",
            c = "dolor(t-1) -> motor(t) [cruzado directo]",
            e = "motor(t-1) -> motor(t) [autorregresivo]")
  tibble(modelo = etiqueta,
         parametro = unname(tipo[substr(filas$label, 1, 1)]),
         ola = as.integer(substr(filas$label, 2, 2)),
         etiqueta = filas$label,
         estimacion = filas$est, ee = filas$se,
         ic_bajo = filas$ci.lower, ic_alto = filas$ci.upper,
         p = filas$pvalue, est_std = filas$std.all)
}

sem_libre <- extraer_libre(riclpm_libre, "RI-CLPM libre (PRIMARIO)")
if (!is.null(sem_libre)) {
  subtitulo("Rezagos cruzados del modelo PRIMARIO (libre), por ola")
  print(as.data.frame(sem_libre |> filter(grepl("cruzado", parametro)) |>
                        select(parametro, ola, estimacion, ic_bajo, ic_alto, p)),
        digits = 4)
  resumen_libre <- sem_libre |>
    filter(grepl("cruzado", parametro)) |>
    group_by(parametro) |>
    summarise(olas = n(), olas_significativas = sum(p < ALPHA),
              p_min = min(p), .groups = "drop")
  subtitulo("Resumen: en cuantas olas alcanza significacion cada direccion")
  print(as.data.frame(resumen_libre), digits = 4)
  guardar_tabla(sem_libre, "t01_sem_libre_por_ola.csv")
  guardar_tabla(resumen_libre, "t01_sem_libre_resumen.csv")
}

sem_tab <- bind_rows(extraer_sem(clpm, "CLPM clasico"),
                     extraer_sem(riclpm, "RI-CLPM restringido"))
subtitulo("Rezagos cruzados: CLPM frente a RI-CLPM")
print(as.data.frame(sem_tab |> select(modelo, parametro, estimacion, ic_bajo, ic_alto, p, est_std)),
      digits = 4)
resultados$sem <- sem_tab

# Covariacion de los interceptos aleatorios: el parametro que sostiene la tesis
# del fenotipo compartido.
if (!is.null(riclpm)) {
  pe <- riclpm$pe
  ri <- pe[pe$lhs == "RId" & pe$rhs == "RIm" & pe$op == "~~", ]
  ri_d <- pe[pe$lhs == "RId" & pe$rhs == "RId" & pe$op == "~~", ]
  ri_m <- pe[pe$lhs == "RIm" & pe$rhs == "RIm" & pe$op == "~~", ]
  r_ri <- ri$est[1] / sqrt(ri_d$est[1] * ri_m$est[1])
  ri_cor_valor <<- r_ri
  subtitulo("Correlacion de los interceptos aleatorios (rasgo estable)")
  cat(sprintf("  covarianza = %.4f (EE %.4f, p = %.4g)\n", ri$est[1], ri$se[1], ri$pvalue[1]))
  cat(sprintf("  varianza del rasgo de dolor = %.4f\n", ri_d$est[1]))
  cat(sprintf("  varianza del rasgo motor    = %.4f\n", ri_m$est[1]))
  cat(sprintf("  CORRELACION DE RASGO r = %.4f (std.all = %.4f)\n", r_ri, ri$std.all[1]))
  resultados$ri_cor <- tibble(
    parametro = "correlacion de interceptos aleatorios (dolor, motor)",
    covarianza = ri$est[1], ee = ri$se[1], p = ri$pvalue[1],
    var_dolor = ri_d$est[1], var_motor = ri_m$est[1],
    r = r_ri, r_std = ri$std.all[1])
}

# =============================================================================
# 5. SINTESIS
# =============================================================================
titulo("5. Sintesis de la discrepancia")

sintesis <- bind_rows(
  rezagos |> mutate(fuente = "mixto rezagado (confunde entre e intra persona)"),
  ventana |> mutate(fuente = "ventana unica BL->V04 (confunde entre e intra persona)")
) |>
  select(fuente, modelo, n_obs, estimacion, ic_bajo, ic_alto, p, est_de, singular)
print(as.data.frame(sintesis), digits = 4)

ajustes <- bind_rows(
  if (!is.null(clpm)) tibble(modelo = "CLPM clasico", cfi = clpm$fm[["cfi.robust"]],
                             rmsea = clpm$fm[["rmsea.robust"]], srmr = clpm$fm[["srmr"]]),
  if (!is.null(riclpm)) tibble(modelo = "RI-CLPM restringido", cfi = riclpm$fm[["cfi.robust"]],
                               rmsea = riclpm$fm[["rmsea.robust"]], srmr = riclpm$fm[["srmr"]]),
  if (!is.null(riclpm_libre)) tibble(modelo = "RI-CLPM libre (PRIMARIO)",
                                     cfi = riclpm_libre$fm[["cfi.robust"]],
                                     rmsea = riclpm_libre$fm[["rmsea.robust"]],
                                     srmr = riclpm_libre$fm[["srmr"]]))
subtitulo("Indices de ajuste de los tres modelos")
print(as.data.frame(ajustes), digits = 4)
guardar_tabla(ajustes, "t01_ajuste_modelos.csv")

# Correlacion de rasgo en el modelo PRIMARIO (libre).
if (!is.null(riclpm_libre)) {
  pel <- riclpm_libre$pe
  ril <- pel[pel$lhs == "RId" & pel$rhs == "RIm" & pel$op == "~~", ]
  rasgo_libre <- tibble(modelo = "RI-CLPM libre (PRIMARIO)",
                        r = ril$std.all[1], ee = ril$se[1], p = ril$pvalue[1])
  subtitulo("Correlacion de rasgo en el modelo primario (libre)")
  print(as.data.frame(rasgo_libre), digits = 4)
  guardar_tabla(rasgo_libre, "t01_correlacion_rasgo_libre.csv")
}

# ---------------------------------------------------------------------------
# La correlacion de rasgo del RI-CLPM es CRUDA: el modelo no lleva covariables.
# Para las vias INTRAPERSONALES eso es correcto y es la virtud del modelo, porque
# los interceptos aleatorios absorben todo confusor invariante en el tiempo. Pero
# la correlacion ENTRE personas, que es el resultado positivo del articulo, no
# esta protegida por ese argumento: la edad, el sexo y la duracion causan
# plausiblemente las dos series. Se estima tambien ajustada, regresando los dos
# interceptos sobre las basales dentro del propio modelo.
# ---------------------------------------------------------------------------
titulo("4b. Correlacion de rasgo AJUSTADA por las covariables basales")

bl_cov <- d |> filter(EVENT_ID == "BL") |>
  select(PATNO, edad = age_yrs, varon = sex_male, dur = disease_yrs, moca = MoCA)
ancho_aj <- ancho |> inner_join(bl_cov, by = "PATNO") |>
  mutate(across(c(edad, dur, moca), ~ as.numeric(scale(.x))))

riclpm_aj_txt <- paste(riclpm_txt,
  "RId ~ edad + varon + dur + moca",
  "RIm ~ edad + varon + dur + moca", sep = "\n")

fit_aj <- try(lavaan::sem(riclpm_aj_txt, data = ancho_aj, missing = "fiml",
                          estimator = "MLR", fixed.x = FALSE), silent = TRUE)
if (!inherits(fit_aj, "try-error") && lavaan::lavInspect(fit_aj, "converged")) {
  pe_aj <- lavaan::parameterEstimates(fit_aj, standardized = TRUE)
  ri_aj <- pe_aj[pe_aj$lhs == "RId" & pe_aj$rhs == "RIm" & pe_aj$op == "~~", ]
  rasgo_aj <- tibble(modelo = "RI-CLPM con interceptos ajustados por basales",
                     r = ri_aj$std.all[1], ee = ri_aj$se[1], p = ri_aj$pvalue[1])
  print(as.data.frame(rasgo_aj), digits = 4)
  cat(sprintf("\n  Cruda %.4f frente a ajustada %.4f\n",
              ri_cor_valor, rasgo_aj$r[1]))
  cat(if (rasgo_aj$p[1] < ALPHA)
        "  La correlacion de rasgo SOBREVIVE al ajuste por las basales.\n"
      else
        "  La correlacion de rasgo NO sobrevive al ajuste: hay que decirlo.\n")
  guardar_tabla(rasgo_aj, "t01_correlacion_rasgo_ajustada.csv")
}

guardar_tabla(sintesis, "t01_direccionalidad_rezagos.csv")
guardar_tabla(sem_tab, "t01_direccionalidad_sem.csv")
if (!is.null(resultados$ri_cor)) guardar_tabla(resultados$ri_cor, "t01_correlacion_rasgo.csv")

saveRDS(list(rezagos = rezagos, ventana = ventana, sem = sem_tab,
             ri_cor = resultados$ri_cor,
             clpm_fit = if (!is.null(clpm)) clpm$fm else NULL,
             riclpm_fit = if (!is.null(riclpm)) riclpm$fm else NULL,
             sd_dolor = SD_DOLOR, sd_motor = SD_MOTOR),
        file.path(PAPER_MOD, "direccionalidad.rds"))

cat("\n\nListo: R/paper/01_direccionalidad.R\n")
