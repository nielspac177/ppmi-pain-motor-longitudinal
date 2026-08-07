#!/usr/bin/env Rscript
# =============================================================================
# ARTICULO — Dolor y severidad motora en la EP: estructura longitudinal (PPMI)
# Utilidades compartidas: rutas, carga de datos, derivadas, formato.
#
# Se carga con source() desde cada script de R/paper/. No produce salidas.
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(broom)
})
select <- dplyr::select

ROOT <- Sys.getenv("TESIS_ROOT", unset = getwd())
if (!dir.exists(file.path(ROOT, "outputs"))) {
  stop("Ejecuta desde la raiz del repositorio, o define TESIS_ROOT. ROOT actual: ", ROOT)
}

# Directorio de datos. Por defecto data/, con los datos reales de PPMI. La
# integracion continua no tiene acceso a PPMI y apunta a data-synth/ mediante
# DATOS_DIR, de modo que el mismo codigo corre en ambos casos y un tercero puede
# revisarlo sin firmar el acuerdo de uso.
DATOS <- Sys.getenv("DATOS_DIR", unset = file.path(ROOT, "data"))
if (!dir.exists(DATOS)) stop("No existe el directorio de datos: ", DATOS)

PAPER_TAB <- file.path(ROOT, "outputs", "paper", "tables")
PAPER_MOD <- file.path(ROOT, "outputs", "paper", "models")
PAPER_FIG <- file.path(ROOT, "outputs", "paper", "figures")
for (p in c(PAPER_TAB, PAPER_MOD, PAPER_FIG)) dir.create(p, recursive = TRUE, showWarnings = FALSE)

SEED <- 20260807
ALPHA <- 0.05

# Orden canonico de las visitas y su horizonte nominal en anios.
VISITAS <- c("BL", "V04", "V06", "V08", "V10", "V12")
ANIOS_NOMINALES <- c(BL = 0, V04 = 1, V06 = 2, V08 = 3, V10 = 4, V12 = 5)

titulo <- function(x) cat("\n\n", strrep("=", 78), "\n", x, "\n", strrep("=", 78), "\n", sep = "")
subtitulo <- function(x) cat("\n--- ", x, " ---\n", sep = "")

# --------------------------------------------------------------- FORMATO ---
# Convencion RAE: coma decimal. Unico punto de formato numerico del articulo.
num <- function(x, d = 2) {
  ifelse(is.na(x), "NA", formatC(x, format = "f", digits = d, decimal.mark = ","))
}
pv <- function(p) {
  ifelse(is.na(p), "NA",
    ifelse(p < 0.001, "< 0,001",
           formatC(p, format = "f", digits = 3, decimal.mark = ",")))
}
ic <- function(lo, hi, d = 2) sprintf("%s a %s", num(lo, d), num(hi, d))

# -------------------------------------------------------- CARGA DE DATOS ---
# Une el formato largo de la tesis con el fenotipo de Stebbins y construye las
# derivadas que necesitan todos los analisis del articulo.
#
# `tiempo_anios` es el tiempo REAL desde la basal de cada paciente, calculado a
# partir de visit_date, no el horizonte nominal de la visita. Los modelos
# rezagados del trabajo previo trataban las visitas como equiespaciadas; no lo
# estan, y ese es uno de los defectos que este articulo corrige.
cargar_largo <- function(estado = c("off", "on")) {
  estado <- match.arg(estado)
  arch <- if (estado == "off") "stebbins.csv" else "stebbins_on.csv"

  L <- read_csv(file.path(DATOS, "tidy_long.csv"), show_col_types = FALSE)
  S <- read_csv(file.path(DATOS, arch), show_col_types = FALSE) |>
    select(PATNO, EVENT_ID, tremor_mean, pigd_mean, td_pigd_ratio, phenotype,
           phenotype_cero_indet, phenotype_cero_excl, denominador_cero,
           items_complete, np3_tremor_sum, np3_pigd_sum, np3_clasificadores_sum)

  d <- L |>
    left_join(S, by = c("PATNO", "EVENT_ID")) |>
    filter(EVENT_ID %in% VISITAS) |>
    mutate(
      EVENT_ID = factor(EVENT_ID, levels = VISITAS),
      # visit_date de PPMI viene como "Mon-yy"; se ancla al dia 1 del mes.
      fecha = as.Date(paste0("01-", visit_date), format = "%d-%b-%y"),
      sexo = factor(sex_male, levels = c(0, 1), labels = c("Mujer", "Varon")),
      dolor_int = as.numeric(NP1PAIN),
      dolor_si  = as.integer(NP1PAIN >= 1),
      fenotipo = factor(phenotype, levels = c("TD", "Indeterminate", "PIGD"),
                        labels = c("TD", "Indeterminado", "PIGD")),
      # Las dos variantes de la regla de denominador cero (ADR 0007).
      fenotipo_cero_indet = factor(phenotype_cero_indet,
                                   levels = c("TD", "Indeterminate", "PIGD"),
                                   labels = c("TD", "Indeterminado", "PIGD")),
      fenotipo_cero_excl = factor(phenotype_cero_excl,
                                  levels = c("TD", "Indeterminate", "PIGD"),
                                  labels = c("TD", "Indeterminado", "PIGD")),
      # log(razon) es la version continua de la clasificacion: simetrica en torno
      # a 1 y sin los cortes arbitrarios de 1,15 y 0,90.
      log_ratio = log(td_pigd_ratio),
      # Puntuacion motora que EXCLUYE los 13 items de la Parte III usados para
      # clasificar el fenotipo. Permite contrastar la circularidad parcial en
      # lugar de solo declararla: si el patron se mantiene aqui, no puede ser un
      # artefacto de que el clasificador y el desenlace compartan items.
      UPDRS3_resto = UPDRS3 - np3_clasificadores_sum,
      LEDD_100 = LEDD / 100,
      tratado = as.integer(LEDD > 0)
    ) |>
    group_by(PATNO) |>
    arrange(EVENT_ID, .by_group = TRUE) |>
    mutate(
      fecha_bl = fecha[EVENT_ID == "BL"][1],
      tiempo_anios = as.numeric(fecha - fecha_bl) / 365.25
    ) |>
    ungroup() |>
    mutate(anio_nominal = unname(ANIOS_NOMINALES[as.character(EVENT_ID)]))

  d
}

# Valores basales de un conjunto de variables, en formato ancho por PATNO.
basales <- function(d, vars) {
  d |>
    filter(EVENT_ID == "BL") |>
    select(PATNO, all_of(vars)) |>
    rename_with(~ paste0(.x, "_bl"), all_of(vars))
}

# Conjunto de ajuste del modelo primario (ADR 0005: sin Hoehn & Yahr).
AJUSTE_PRIMARIO <- c("age_yrs", "sexo", "disease_yrs", "MoCA")

# Coeficiente de un termino con IC de Wald, en un data frame de una fila.
extraer <- function(modelo, termino, etiqueta = termino, vcov_fn = NULL) {
  tid <- broom::tidy(modelo)
  if (!is.null(vcov_fn)) {
    ct <- lmtest::coeftest(modelo, vcov. = vcov_fn)
    tid <- tibble(term = rownames(ct), estimate = ct[, 1], std.error = ct[, 2],
                  statistic = ct[, 3], p.value = ct[, 4])
  }
  fila <- tid[tid$term == termino, ]
  if (nrow(fila) == 0) {
    stop("Termino no encontrado en el modelo: ", termino,
         ". Disponibles: ", paste(tid$term, collapse = ", "))
  }
  tibble(
    termino = etiqueta,
    estimacion = fila$estimate[1],
    ee = fila$std.error[1],
    ic_bajo = fila$estimate[1] - 1.96 * fila$std.error[1],
    ic_alto = fila$estimate[1] + 1.96 * fila$std.error[1],
    p = fila$p.value[1]
  )
}

guardar_tabla <- function(x, nombre) {
  ruta <- file.path(PAPER_TAB, nombre)
  write_csv(x, ruta)
  cat(sprintf("  -> %s (%d filas)\n", basename(ruta), nrow(x)))
  invisible(ruta)
}
