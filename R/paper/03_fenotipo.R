#!/usr/bin/env Rscript
# =============================================================================
# ARTICULO — Analisis 1: el fenotipo motor TD/PIGD como modificador
#
# Prediccion a contrastar. Si el vinculo entre dolor y severidad motora es
# mecanistico y no confusion, el dolor deberia concentrarse en el fenotipo
# rigido-acinetico (PIGD) y no repartirse al azar entre fenotipos.
#
# Estructura:
#   1  Distribucion del fenotipo y su ESTABILIDAD en el seguimiento.
#   2  Asociacion transversal entre dolor y fenotipo.
#   3  Interaccion dolor x fenotipo sobre la MDS-UPDRS III, con el fenotipo
#      clasificado en la BASAL y el desenlace en V04 (mitiga la circularidad).
#   4  Efecto ESTRATIFICADO por fenotipo, que suele ser mas informativo que el
#      termino de interaccion, infrapotenciado por construccion.
#   5  Modificador CONTINUO: log de la razon de Stebbins, sin los cortes.
#   6  Circularidad: se repite todo con una puntuacion motora que excluye los
#      13 items de la Parte III usados para clasificar.
#   7  Sensibilidades: fenotipo concurrente, estado ON, manejo del indeterminado.
#
# Ejecutar:  Rscript R/paper/03_fenotipo.R
# =============================================================================

source(file.path(Sys.getenv("TESIS_ROOT", unset = getwd()), "R", "paper", "00_comun.R"))
suppressPackageStartupMessages({ library(sandwich); library(lmtest) })

set.seed(SEED)
titulo("ANALISIS 1 — EL FENOTIPO MOTOR TD/PIGD")

d <- cargar_largo("off")
salidas <- list()

# =============================================================================
# 1. DISTRIBUCION Y ESTABILIDAD
# =============================================================================
titulo("1. Distribucion del fenotipo y estabilidad en el seguimiento")

# Definicion de la muestra analitica: dolor Y desenlace motor presentes. Es la
# misma regla que congela el flujo STROBE del ADR 0003 y da N = 711 en V04. Se
# aplica aqui para que el articulo y la tesis cuenten la misma muestra.
dm <- d |> filter(!is.na(UPDRS3), !is.na(NP1PAIN))

n_v04 <- sum(dm$EVENT_ID == "V04")
flow <- read_csv(file.path(DATOS, "flow_v04.csv"), show_col_types = FALSE)
stopifnot("El N en V04 no coincide con el flujo STROBE congelado" =
            n_v04 == tail(flow$n, 1))
cat(sprintf("\nMuestra analitica en V04: N = %d (concuerda con el flujo STROBE)\n", n_v04))

dist <- dm |>
  filter(!is.na(fenotipo)) |>
  count(EVENT_ID, fenotipo) |>
  group_by(EVENT_ID) |>
  mutate(pct = 100 * n / sum(n)) |>
  ungroup()
subtitulo("Distribucion por visita (solo visitas con desenlace motor)")
print(dist |> pivot_wider(names_from = fenotipo, values_from = c(n, pct)), n = Inf)
salidas$distribucion <- dist

# Estabilidad. El argumento del articulo es sobre un fenotipo ESTABLE, de modo
# que la estabilidad no es un detalle: es un supuesto que hay que medir.
ancho_f <- dm |>
  select(PATNO, EVENT_ID, fenotipo) |>
  filter(!is.na(fenotipo)) |>
  pivot_wider(names_from = EVENT_ID, values_from = fenotipo)

estab <- map_dfr(setdiff(VISITAS, "BL"), function(v) {
  if (!v %in% names(ancho_f)) return(NULL)
  sub <- ancho_f |> filter(!is.na(BL), !is.na(.data[[v]]))
  if (nrow(sub) == 0) return(NULL)
  tibble(visita = v, n = nrow(sub),
         concordancia = mean(sub$BL == sub[[v]]),
         kappa = {
           tb <- table(sub$BL, sub[[v]])
           po <- sum(diag(tb)) / sum(tb)
           pe <- sum(rowSums(tb) * colSums(tb)) / sum(tb)^2
           (po - pe) / (1 - pe)
         })
})
subtitulo("Estabilidad del fenotipo respecto de la basal")
print(estab)
salidas$estabilidad <- estab

# Version continua: correlacion de la razon en el tiempo.
ancho_r <- dm |>
  select(PATNO, EVENT_ID, log_ratio) |>
  filter(is.finite(log_ratio)) |>
  pivot_wider(names_from = EVENT_ID, values_from = log_ratio)
estab_r <- map_dfr(setdiff(VISITAS, "BL"), function(v) {
  if (!v %in% names(ancho_r)) return(NULL)
  sub <- ancho_r |> filter(!is.na(BL), !is.na(.data[[v]]))
  if (nrow(sub) < 10) return(NULL)
  tibble(visita = v, n = nrow(sub),
         spearman = cor(sub$BL, sub[[v]], method = "spearman"))
})
subtitulo("Estabilidad de la razon log-transformada (continua)")
print(estab_r)
salidas$estabilidad_continua <- estab_r

cat("\n  LECTURA. La concordancia de la clasificacion tricotomica baja con el\n",
    " horizonte. Un fenotipo cuyo ETIQUETADO cambia en una cuarta parte de los\n",
    " pacientes al cabo de un anio no es 'estable' en el sentido categorico. La\n",
    " version continua conserva mas orden. El articulo debe declararlo y apoyar\n",
    " el argumento en la version continua, no en la etiqueta.\n", sep = "")

# =============================================================================
# 2. ASOCIACION TRANSVERSAL ENTRE DOLOR Y FENOTIPO
# =============================================================================
titulo("2. El dolor, se concentra en el fenotipo PIGD?")

v04 <- dm |> filter(EVENT_ID == "V04")
bl_f <- d |> filter(EVENT_ID == "BL") |>
  select(PATNO, fenotipo_bl = fenotipo, log_ratio_bl = log_ratio,
         dolor_bl = dolor_int, motor_bl = UPDRS3, motor_resto_bl = UPDRS3_resto,
         HY_bl = HY, moca_bl = MoCA, edad_bl = age_yrs, dur_bl = disease_yrs,
         sexo_bl = sexo, ledd_bl = LEDD)

subtitulo("Dolor por fenotipo, en la misma visita (V04)")
tab_v04 <- v04 |> filter(!is.na(fenotipo)) |>
  group_by(fenotipo) |>
  summarise(n = n(), dolor_medio = mean(dolor_int, na.rm = TRUE),
            de = sd(dolor_int, na.rm = TRUE),
            pct_con_dolor = 100 * mean(dolor_si, na.rm = TRUE),
            motor_medio = mean(UPDRS3, na.rm = TRUE), .groups = "drop")
print(tab_v04)

# Regresion ordinal del dolor sobre el fenotipo, ajustada.
mod_pf <- MASS::polr(factor(dolor_int) ~ fenotipo + age_yrs + sexo + disease_yrs + MoCA,
                     data = v04 |> filter(!is.na(fenotipo), !is.na(dolor_int)), Hess = TRUE)
ct <- coef(summary(mod_pf))
ct <- cbind(ct, p = 2 * pnorm(abs(ct[, "t value"]), lower.tail = FALSE))
subtitulo("Regresion ordinal: dolor ~ fenotipo + ajuste (V04)")
print(round(ct[grep("fenotipo", rownames(ct)), , drop = FALSE], 4))
or_pf <- tibble(termino = rownames(ct)[grep("fenotipo", rownames(ct))],
                OR = exp(ct[grep("fenotipo", rownames(ct)), "Value"]),
                ic_bajo = exp(ct[grep("fenotipo", rownames(ct)), "Value"] -
                                1.96 * ct[grep("fenotipo", rownames(ct)), "Std. Error"]),
                ic_alto = exp(ct[grep("fenotipo", rownames(ct)), "Value"] +
                                1.96 * ct[grep("fenotipo", rownames(ct)), "Std. Error"]),
                p = ct[grep("fenotipo", rownames(ct)), "p"])
print(or_pf)
salidas$dolor_por_fenotipo <- or_pf
salidas$tabla_dolor_fenotipo <- tab_v04

# =============================================================================
# 3-6. INTERACCION, ESTRATIFICADO, CONTINUO Y CIRCULARIDAD
# =============================================================================
titulo("3-6. Interaccion dolor x fenotipo sobre la severidad motora")

# Base de trabajo: fenotipo BASAL, desenlace en V04. Es la mitigacion de la
# circularidad que recomienda el plan: el clasificador y el desenlace no se miden
# en la misma visita.
base <- v04 |>
  select(PATNO, dolor_int, dolor_si, UPDRS3, UPDRS3_resto, UPDRS3_on,
         age_yrs, sexo, disease_yrs, MoCA, HY, LEDD,
         fenotipo_conc = fenotipo, log_ratio_conc = log_ratio) |>
  inner_join(bl_f, by = "PATNO")

cat(sprintf("\nBase para los modelos: n = %d (fenotipo basal no ausente: %d)\n",
            nrow(base), sum(!is.na(base$fenotipo_bl))))

# La referencia es TD, de modo que el termino de interaccion contrasta PIGD
# frente a TD, que es la comparacion de la hipotesis.
ajustar_interaccion <- function(datos, desenlace, exposicion, modificador,
                                etiqueta, ref = "TD") {
  datos <- datos |> filter(!is.na(.data[[modificador]]))
  if (is.factor(datos[[modificador]])) {
    datos[[modificador]] <- relevel(droplevels(datos[[modificador]]), ref = ref)
  }
  f <- as.formula(sprintf("%s ~ %s * %s + age_yrs + sexo + disease_yrs + MoCA",
                          desenlace, exposicion, modificador))
  m <- lm(f, data = datos)
  # HC3 por heterocedasticidad; el desenlace motor tiene varianza creciente.
  ct <- lmtest::coeftest(m, vcov. = sandwich::vcovHC(m, type = "HC3"))
  filas <- grep(":", rownames(ct), value = TRUE)
  tibble(modelo = etiqueta, n = nobs(m), termino = filas,
         estimacion = ct[filas, 1], ee = ct[filas, 2],
         ic_bajo = ct[filas, 1] - 1.96 * ct[filas, 2],
         ic_alto = ct[filas, 1] + 1.96 * ct[filas, 2],
         p = ct[filas, 4])
}

estratificado <- function(datos, desenlace, exposicion, modificador, etiqueta) {
  datos <- datos |> filter(!is.na(.data[[modificador]]))
  niveles <- levels(droplevels(datos[[modificador]]))
  map_dfr(niveles, function(lv) {
    sub <- datos |> filter(.data[[modificador]] == lv)
    if (nrow(sub) < 30) return(tibble(modelo = etiqueta, estrato = lv, n = nrow(sub),
                                      estimacion = NA, ee = NA, ic_bajo = NA,
                                      ic_alto = NA, p = NA))
    f <- as.formula(sprintf("%s ~ %s + age_yrs + sexo + disease_yrs + MoCA",
                            desenlace, exposicion))
    m <- lm(f, data = sub)
    ct <- lmtest::coeftest(m, vcov. = sandwich::vcovHC(m, type = "HC3"))
    tibble(modelo = etiqueta, estrato = lv, n = nobs(m),
           estimacion = ct[exposicion, 1], ee = ct[exposicion, 2],
           ic_bajo = ct[exposicion, 1] - 1.96 * ct[exposicion, 2],
           ic_alto = ct[exposicion, 1] + 1.96 * ct[exposicion, 2],
           p = ct[exposicion, 4])
  })
}

# Rejilla de especificaciones: dos desenlaces x dos exposiciones x dos momentos
# de clasificacion del fenotipo.
rejilla <- expand_grid(
  desenlace = c("UPDRS3", "UPDRS3_resto"),
  exposicion = c("dolor_int", "dolor_si"),
  modificador = c("fenotipo_bl", "fenotipo_conc")
)

inter <- pmap_dfr(rejilla, function(desenlace, exposicion, modificador) {
  ajustar_interaccion(base, desenlace, exposicion, modificador,
                      sprintf("%s ~ %s x %s", desenlace, exposicion, modificador))
})
subtitulo("Terminos de interaccion (referencia del fenotipo = TD)")
print(as.data.frame(inter |> select(modelo, n, termino, estimacion, ic_bajo, ic_alto, p)),
      digits = 4)
salidas$interaccion <- inter

estr <- pmap_dfr(rejilla, function(desenlace, exposicion, modificador) {
  estratificado(base, desenlace, exposicion, modificador,
                sprintf("%s ~ %s | %s", desenlace, exposicion, modificador))
})
subtitulo("Efecto del dolor ESTRATIFICADO por fenotipo")
print(as.data.frame(estr), digits = 4)
salidas$estratificado <- estr

# ---------------------------------------------------------------------------
# PREESPECIFICACION Y MULTIPLICIDAD
#
# La rejilla anterior tiene 16 modelos y seria deshonesto elegir despues el que
# convenga. La especificacion PRIMARIA se declara aqui, y es la que prescribe el
# plan del articulo: desenlace MDS-UPDRS III completa, exposicion ordinal,
# fenotipo clasificado en la BASAL. Todo lo demas es sensibilidad.
# ---------------------------------------------------------------------------
PRIMARIA <- "UPDRS3 ~ dolor_int x fenotipo_bl"

subtitulo("Especificacion PRIMARIA preespecificada")
prim <- inter |> filter(modelo == PRIMARIA, grepl("PIGD", termino))
print(as.data.frame(prim), digits = 4)

subtitulo("Multiplicidad sobre las 16 especificaciones de la rejilla")
mult <- inter |>
  filter(grepl("PIGD", termino)) |>
  mutate(p_holm = p.adjust(p, method = "holm"),
         p_bh = p.adjust(p, method = "BH")) |>
  select(modelo, termino, estimacion, p, p_holm, p_bh) |>
  arrange(p)
print(as.data.frame(mult), digits = 4)
cat(sprintf("\n  Contrastes PIGD vs TD: %d. Con p < 0,05 sin corregir: %d.",
            nrow(mult), sum(mult$p < ALPHA)))
cat(sprintf(" Tras Holm: %d. Tras Benjamini-Hochberg: %d.\n",
            sum(mult$p_holm < ALPHA), sum(mult$p_bh < ALPHA)))
salidas$primaria <- prim
salidas$multiplicidad <- mult

subtitulo("Modificador CONTINUO: log de la razon de Stebbins")
cont <- map_dfr(c("UPDRS3", "UPDRS3_resto"), function(des) {
  datos <- base |> filter(is.finite(log_ratio_bl))
  m <- lm(as.formula(sprintf(
    "%s ~ dolor_int * log_ratio_bl + age_yrs + sexo + disease_yrs + MoCA", des)),
    data = datos)
  ct <- lmtest::coeftest(m, vcov. = sandwich::vcovHC(m, type = "HC3"))
  fila <- "dolor_int:log_ratio_bl"
  tibble(desenlace = des, n = nobs(m), estimacion = ct[fila, 1], ee = ct[fila, 2],
         ic_bajo = ct[fila, 1] - 1.96 * ct[fila, 2],
         ic_alto = ct[fila, 1] + 1.96 * ct[fila, 2], p = ct[fila, 4])
})
print(as.data.frame(cont), digits = 4)
salidas$continuo <- cont

# =============================================================================
# 6b. SENSIBILIDAD A LA REGLA DE DENOMINADOR CERO
# =============================================================================
titulo("6b. Sensibilidad a la regla de denominador cero de Stebbins")

# En esta cohorte cerca de una quinta parte de las visitas tiene media PIGD = 0,
# y no se pudo verificar que Stebbins enuncie una regla para ese caso. La
# eleccion mueve pacientes entre TD e indeterminado, de modo que se contrasta.
base_cero <- v04 |>
  select(PATNO, dolor_int, dolor_si, UPDRS3, UPDRS3_resto,
         age_yrs, sexo, disease_yrs, MoCA) |>
  inner_join(d |> filter(EVENT_ID == "BL") |>
               select(PATNO,
                      jankovic = fenotipo,
                      cero_indeterminado = fenotipo_cero_indet,
                      cero_excluido = fenotipo_cero_excl,
                      denominador_cero),
             by = "PATNO")

cat(sprintf("\nVisitas basales con denominador cero: %d de %d (%.1f %%)\n",
            sum(base_cero$denominador_cero == 1, na.rm = TRUE),
            sum(!is.na(base_cero$denominador_cero)),
            100 * mean(base_cero$denominador_cero == 1, na.rm = TRUE)))

sens_cero <- map_dfr(c("jankovic", "cero_indeterminado", "cero_excluido"), function(rg) {
  map_dfr(c("UPDRS3", "UPDRS3_resto"), function(des) {
    r <- ajustar_interaccion(base_cero, des, "dolor_int", rg,
                             sprintf("%s | regla: %s", des, rg))
    r |> filter(grepl("PIGD", termino))
  })
})
subtitulo("Interaccion dolor x PIGD segun la regla de denominador cero")
print(as.data.frame(sens_cero |> select(modelo, n, estimacion, ic_bajo, ic_alto, p)), digits = 4)
salidas$sensibilidad_cero <- sens_cero

# =============================================================================
# 6c. CONTRASTE DE METODO: EVALUADOR FRENTE A AUTOINFORME
# =============================================================================
titulo("6c. Contraste de metodo: items del examinador frente a autoinformados")

# El dolor (NP1PAIN) es autoinformado y la MDS-UPDRS III la puntua un examinador,
# de modo que la asociacion principal NO comparte metodo de medida. Pero el
# clasificador de Stebbins mezcla ambos: 13 items del examinador y 3 del
# cuestionario del paciente. Si la modificacion del efecto viviera solo en la
# parte autoinformada, seria correlacion de metodo compartido y no fenotipo.
S3 <- read_csv(file.path(DATOS, "stebbins.csv"), show_col_types = FALSE) |>
  filter(EVENT_ID == "BL") |>
  mutate(
    # Razon construida SOLO con items del examinador (Parte III).
    trem_p3 = rowMeans(across(all_of(c("NP3PTRMR", "NP3PTRML", "NP3KTRMR", "NP3KTRML",
                                       "NP3RTARU", "NP3RTALU", "NP3RTARL", "NP3RTALL",
                                       "NP3RTALJ", "NP3RTCON")))),
    pigd_p3 = rowMeans(across(all_of(c("NP3GAIT", "NP3FRZGT", "NP3PSTBL")))),
    # Razon construida SOLO con items autoinformados (Parte II).
    trem_p2 = NP2TRMR,
    pigd_p2 = rowMeans(across(all_of(c("NP2WALK", "NP2FREZ")))),
    log_ratio_p3 = log(trem_p3 / na_if(pigd_p3, 0)),
    log_ratio_p2 = log(trem_p2 / na_if(pigd_p2, 0))
  ) |>
  select(PATNO, log_ratio_p3, log_ratio_p2)

base_met <- base |> inner_join(S3, by = "PATNO")

metodo <- map_dfr(c("log_ratio_bl", "log_ratio_p3", "log_ratio_p2"), function(mv) {
  map_dfr(c("UPDRS3", "UPDRS3_resto"), function(des) {
    datos <- base_met |> filter(is.finite(.data[[mv]]))
    if (nrow(datos) < 50) return(NULL)
    m <- lm(as.formula(sprintf(
      "%s ~ dolor_int * %s + age_yrs + sexo + disease_yrs + MoCA", des, mv)), data = datos)
    ct <- lmtest::coeftest(m, vcov. = sandwich::vcovHC(m, type = "HC3"))
    fila <- paste0("dolor_int:", mv)
    tibble(razon = mv, desenlace = des, n = nobs(m),
           estimacion = ct[fila, 1], ee = ct[fila, 2],
           ic_bajo = ct[fila, 1] - 1.96 * ct[fila, 2],
           ic_alto = ct[fila, 1] + 1.96 * ct[fila, 2], p = ct[fila, 4])
  })
})
subtitulo("Interaccion continua segun la fuente de los items del clasificador")
cat("  log_ratio_bl = los 16 items; log_ratio_p3 = solo examinador; log_ratio_p2 = solo autoinforme\n")
print(as.data.frame(metodo), digits = 4)
salidas$contraste_metodo <- metodo

# =============================================================================
# 7. EL FENOTIPO, EXPLICA LA COVARIACION ESTABLE?
# =============================================================================
titulo("7. El fenotipo, explica la covariacion estable entre dolor y motor?")

# Si la covariacion de rasgo entre dolor y severidad motora se debe a que ambos
# se concentran en el fenotipo rigido-acinetico, condicionar sobre el fenotipo
# basal deberia atenuarla. Se usa el promedio intrapersonal de cada serie como
# medida del componente entre personas.
prom <- dm |>
  group_by(PATNO) |>
  summarise(dolor_medio = mean(dolor_int, na.rm = TRUE),
            motor_medio = mean(UPDRS3, na.rm = TRUE),
            motor_resto_medio = mean(UPDRS3_resto, na.rm = TRUE),
            n_visitas = n(), .groups = "drop") |>
  filter(n_visitas >= 2) |>
  inner_join(bl_f, by = "PATNO")

cat(sprintf("\nPacientes con 2 o mas visitas: %d\n", nrow(prom)))

comparar <- function(desenlace) {
  d1 <- prom |> filter(!is.na(fenotipo_bl), !is.na(.data[[desenlace]]), !is.na(dolor_medio))
  m0 <- lm(as.formula(sprintf("%s ~ dolor_medio + edad_bl + sexo_bl + dur_bl + moca_bl", desenlace)), data = d1)
  m1 <- lm(as.formula(sprintf("%s ~ dolor_medio + fenotipo_bl + edad_bl + sexo_bl + dur_bl + moca_bl", desenlace)), data = d1)
  m2 <- lm(as.formula(sprintf("%s ~ dolor_medio + log_ratio_bl + edad_bl + sexo_bl + dur_bl + moca_bl", desenlace)),
           data = d1 |> filter(is.finite(log_ratio_bl)))
  f <- function(m, et) {
    ct <- lmtest::coeftest(m, vcov. = sandwich::vcovHC(m, type = "HC3"))
    tibble(desenlace = desenlace, ajuste = et, n = nobs(m),
           estimacion = ct["dolor_medio", 1], ee = ct["dolor_medio", 2],
           ic_bajo = ct["dolor_medio", 1] - 1.96 * ct["dolor_medio", 2],
           ic_alto = ct["dolor_medio", 1] + 1.96 * ct["dolor_medio", 2],
           p = ct["dolor_medio", 4])
  }
  bind_rows(f(m0, "sin fenotipo"), f(m1, "+ fenotipo basal (categorico)"),
            f(m2, "+ log razon basal (continuo)"))
}

atenuacion <- bind_rows(comparar("motor_medio"), comparar("motor_resto_medio"))
subtitulo("Asociacion entre promedios intrapersonales, con y sin ajuste por fenotipo")
print(as.data.frame(atenuacion), digits = 4)
salidas$atenuacion <- atenuacion

pct_at <- atenuacion |>
  group_by(desenlace) |>
  summarise(atenuacion_categorico = 100 * (1 - estimacion[ajuste == "+ fenotipo basal (categorico)"] /
                                             estimacion[ajuste == "sin fenotipo"]),
            atenuacion_continuo = 100 * (1 - estimacion[ajuste == "+ log razon basal (continuo)"] /
                                           estimacion[ajuste == "sin fenotipo"]),
            .groups = "drop")
subtitulo("Porcentaje de atenuacion al condicionar sobre el fenotipo")
print(as.data.frame(pct_at), digits = 4)
salidas$atenuacion_pct <- pct_at

# =============================================================================
# GUARDADO
# =============================================================================
titulo("Guardado")
guardar_tabla(dist, "t03_fenotipo_distribucion.csv")
guardar_tabla(estab, "t03_fenotipo_estabilidad.csv")
guardar_tabla(estab_r, "t03_fenotipo_estabilidad_continua.csv")
guardar_tabla(tab_v04, "t03_dolor_por_fenotipo.csv")
guardar_tabla(or_pf, "t03_ordinal_dolor_fenotipo.csv")
guardar_tabla(inter, "t03_interaccion.csv")
guardar_tabla(estr, "t03_estratificado.csv")
guardar_tabla(cont, "t03_modificador_continuo.csv")
guardar_tabla(mult, "t03_multiplicidad.csv")
guardar_tabla(sens_cero, "t03_sensibilidad_regla_cero.csv")
guardar_tabla(metodo, "t03_contraste_metodo.csv")
guardar_tabla(atenuacion, "t03_atenuacion.csv")
guardar_tabla(pct_at, "t03_atenuacion_pct.csv")
saveRDS(salidas, file.path(PAPER_MOD, "fenotipo.rds"))

cat("\n\nListo: R/paper/03_fenotipo.R\n")
