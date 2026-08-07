#!/usr/bin/env Rscript
# =============================================================================
# ARTICULO — Flujo de participantes, reconciliado
#
# POR QUE EXISTE ESTE SCRIPT. El manuscrito llego a usar cuatro cifras distintas
# para "la muestra": 1 190, 1 157, 1 174 y 711. Las cuatro eran correctas y las
# cuatro contaban cosas distintas, pero el texto las nombraba igual. Es el mismo
# defecto que motivo el pipeline de cifras del proyecto, reaparecido en otra
# forma: no basta con que cada numero salga de su modelo, hay que decir de que
# poblacion habla.
#
# Este script deriva TODAS las cifras de poblacion de un solo lugar y las exporta
# con una definicion explicita cada una, de modo que no puedan divergir.
#
# Ejecutar:  Rscript R/paper/12_flujo.R
# =============================================================================

source(file.path(Sys.getenv("TESIS_ROOT", unset = getwd()), "R", "paper", "00_comun.R"))

titulo("FLUJO DE PARTICIPANTES RECONCILIADO")

d <- cargar_largo("off")
flow_v04 <- read_csv(file.path(DATOS, "flow_v04.csv"), show_col_types = FALSE)

# ---------------------------------------------------------------------------
# Cada fila define UNA poblacion, con la regla que la produce.
# ---------------------------------------------------------------------------
n_bl_filas <- sum(d$EVENT_ID == "BL")
n_bl_completos <- sum(d$EVENT_ID == "BL" & !is.na(d$UPDRS3) & !is.na(d$NP1PAIN))
dm <- d |> filter(!is.na(UPDRS3), !is.na(NP1PAIN))
n_panel_pac <- n_distinct(dm$PATNO)
n_panel_obs <- nrow(dm)
n_v04 <- sum(dm$EVENT_ID == "V04")

flujo <- tribble(
  ~etiqueta, ~definicion, ~n,
  "Cohorte basal",
  "filas con EVENT_ID = BL tras las exclusiones de elegibilidad",
  n_bl_filas,
  "Cohorte basal con ambas medidas",
  "de las anteriores, con dolor Y desenlace motor presentes en la basal",
  n_bl_completos,
  "Panel analitico (pacientes)",
  "pacientes con al menos una visita con ambas medidas, en cualquier ola",
  n_panel_pac,
  "Panel analitico (observaciones)",
  "visitas con ambas medidas, sumadas sobre las seis olas",
  n_panel_obs,
  "Muestra transversal de 12 meses",
  "visitas V04 con ambas medidas; coincide con el flujo STROBE congelado",
  n_v04
)

subtitulo("Poblaciones del articulo, cada una con su definicion")
print(as.data.frame(flujo), right = FALSE)

stopifnot("la muestra de 12 meses no coincide con el flujo STROBE" =
            n_v04 == tail(flow_v04$n, 1))
stopifnot("las poblaciones no estan anidadas como deberian" =
            n_bl_completos <= n_bl_filas && n_panel_pac <= n_bl_filas)

subtitulo("Flujo de elegibilidad en la visita de 12 meses (ADR 0003)")
print(as.data.frame(flow_v04), right = FALSE)

# ---------------------------------------------------------------------------
# Retencion, derivada de la MISMA definicion de panel.
# ---------------------------------------------------------------------------
ret <- dm |>
  count(EVENT_ID, name = "n_con_ambas") |>
  mutate(pct_de_basal = 100 * n_con_ambas / n_bl_completos)
subtitulo("Retencion, con la basal completa como denominador unico")
print(as.data.frame(ret), digits = 4)

cat("\n  NOTA. El denominador de la retencion es la basal CON AMBAS MEDIDAS\n",
    "  (", n_bl_completos, "), no el total de filas basales (", n_bl_filas, ").\n",
    "  Usar uno u otro cambia los porcentajes, y el manuscrito debe usar siempre\n",
    "  el mismo. Aqui se fija este.\n", sep = "")

guardar_tabla(flujo, "t12_flujo_poblaciones.csv")
guardar_tabla(ret, "t12_retencion_reconciliada.csv")

cat("\n\nListo: R/paper/12_flujo.R\n")
