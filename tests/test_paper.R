#!/usr/bin/env Rscript
# =============================================================================
# Pruebas de regresion del ARTICULO.
#
# Recalculan o releen cada resultado publicado y fallan si cambia. No comprueban
# que el analisis sea correcto: comprueban que no se mueva sin que nadie se
# entere. Cuando un cambio de metodo mueva una cifra, la prueba fallara, y eso
# es exactamente lo que tiene que pasar: hay que actualizarla A LA VEZ que el
# ADR que justifica el cambio.
#
# Ejecutar:  Rscript tests/test_paper.R
# =============================================================================

suppressPackageStartupMessages({ library(tidyverse); library(jsonlite) })

ROOT <- Sys.getenv("TESIS_ROOT", unset = getwd())
TAB <- file.path(ROOT, "outputs", "paper", "tables")
# Mismo mecanismo que R/paper/00_comun.R: la CI corre sobre datos sinteticos.
DATOS <- Sys.getenv("DATOS_DIR", unset = file.path(ROOT, "data"))
CIFRAS <- file.path(ROOT, "outputs", "paper", "cifras.json")

n_ok <- 0; n_fallo <- 0
comprobar <- function(desc, condicion) {
  ok <- isTRUE(tryCatch(condicion, error = function(e) FALSE))
  if (ok) { n_ok <<- n_ok + 1; cat("  OK    ", desc, "\n", sep = "") }
  else { n_fallo <<- n_fallo + 1; cat("  FALLO ", desc, "\n", sep = "") }
}
cerca <- function(x, objetivo, tol = 0.02) {
  isTRUE(abs(as.numeric(x) - objetivo) <= tol)
}
seccion <- function(x) cat("\n", strrep("-", 74), "\n", x, "\n", strrep("-", 74), "\n", sep = "")

T <- function(f) read_csv(file.path(TAB, f), show_col_types = FALSE)

cat("\n", strrep("=", 74), "\nPRUEBAS DE REGRESION DEL ARTICULO\n", strrep("=", 74), "\n", sep = "")

# ---------------------------------------------------------------- MUESTRA ---
seccion("Muestra y flujo")

flujo <- read_csv(file.path(DATOS, "flow_v04.csv"), show_col_types = FALSE)
comprobar("el flujo STROBE sigue terminando en N = 711",
          tail(flujo$n, 1) == 711)
comprobar("la exclusion por DBS sigue quitando 2 y no 58",
          flujo$n[flujo$step == "after_monogenic_exclusion"] -
            flujo$n[flujo$step == "after_dbs_exclusion"] == 2)

steb <- read_csv(file.path(DATOS, "stebbins.csv"), show_col_types = FALSE)
comprobar("stebbins.csv NO contiene columnas de identificacion mas alla de PATNO",
          !any(c("visit_date", "INFODT", "birthdt") %in% names(steb)))
comprobar("el fenotipo tiene las tres categorias esperadas",
          setequal(na.omit(unique(steb$phenotype)), c("TD", "PIGD", "Indeterminate")))
comprobar("las tres reglas de denominador cero estan presentes",
          all(c("phenotype", "phenotype_cero_indet", "phenotype_cero_excl") %in% names(steb)))

# --------------------------------------------------------- DIRECCIONALIDAD --
seccion("Direccionalidad (ADR 0006)")

sem <- T("t01_direccionalidad_sem.csv")
clpm_b <- sem |> filter(modelo == "CLPM clasico", etiqueta == "b")
clpm_c <- sem |> filter(modelo == "CLPM clasico", etiqueta == "c")
ri_b <- sem |> filter(modelo == "RI-CLPM", etiqueta == "b")
ri_c <- sem |> filter(modelo == "RI-CLPM", etiqueta == "c")

comprobar("el CLPM clasico sigue haciendo significativas AMBAS direcciones",
          clpm_b$p[1] < 0.05 && clpm_c$p[1] < 0.05)
comprobar("el RI-CLPM sigue anulando la via motor -> dolor",
          ri_b$p[1] > 0.05)
comprobar("el RI-CLPM ajusta mejor que el CLPM (esa es la razon para preferirlo)", {
  m <- readRDS(file.path(ROOT, "outputs", "paper", "models", "direccionalidad.rds"))
  m$riclpm_fit[["cfi.robust"]] > m$clpm_fit[["cfi.robust"]] &&
    m$riclpm_fit[["rmsea.robust"]] < m$clpm_fit[["rmsea.robust"]]
})

ri_cor <- T("t01_correlacion_rasgo.csv")
comprobar("la correlacion de rasgo sigue siendo positiva, pequena y significativa",
          ri_cor$r[1] > 0 && ri_cor$r[1] < 0.30 && ri_cor$p[1] < 0.05)
comprobar("la correlacion de rasgo sigue valiendo 0,175", cerca(ri_cor$r[1], 0.175, 0.01))

# ------------------------------------------------------------- REFUTACION ---
seccion("Refutacion (ADR 0008)")

ref <- T("t02_refutacion_riclpm.csv")
ref_c <- ref |> filter(via == "exposicion(t-1) -> desenlace(t)")
comprobar("la via intrapersonal sigue SIN sobrevivir la mayoria de comprobaciones",
          sum(as.numeric(ref_c$p) < 0.05, na.rm = TRUE) <= nrow(ref_c) / 2)
comprobar("las restricciones de igualdad entre olas se siguen rechazando", {
  r1 <- ref |> filter(grepl("^R1", comprobacion)); as.numeric(r1$p[1]) < 0.05
})
comprobar("el control negativo del MoCA sigue dando una via nula", {
  r7 <- ref_c |> filter(grepl("^R7", comprobacion)); as.numeric(r7$p[1]) > 0.05
})
comprobar("el MoCA SI tiene correlacion de rasgo (limita la especificidad)", {
  r7 <- ref_c |> filter(grepl("^R7", comprobacion)); as.numeric(r7$p_rasgo[1]) < 0.05
})

# --------------------------------------------------------------- FENOTIPO ---
seccion("Fenotipo (ADR 0007 y 0008)")

orp <- T("t03_ordinal_dolor_fenotipo.csv") |> filter(grepl("PIGD", termino))
comprobar("el dolor sigue siendo mas frecuente en PIGD", orp$OR[1] > 1 && orp$p[1] < 0.05)
comprobar("la razon de momios de PIGD sigue valiendo 1,49", cerca(orp$OR[1], 1.49, 0.03))

mult <- T("t03_multiplicidad.csv")
prim <- mult |> filter(modelo == "UPDRS3 ~ dolor_int x fenotipo_bl")
comprobar("la interaccion PREESPECIFICADA sigue siendo nula", prim$p[1] > 0.05)
comprobar("ningun contraste sobrevive a Holm", sum(mult$p_holm < 0.05) == 0)
comprobar("ningun contraste sobrevive a Benjamini-Hochberg", sum(mult$p_bh < 0.05) == 0)

sc <- T("t03_sensibilidad_regla_cero.csv") |> filter(grepl("^UPDRS3 \\|", modelo))
comprobar("la conclusion es la misma con las tres reglas de denominador cero",
          all(sc$p > 0.05))

met <- T("t03_contraste_metodo.csv")
comprobar("la modificacion no reaparece con items solo del examinador",
          met$p[met$razon == "log_ratio_p3" & met$desenlace == "UPDRS3_resto"][1] > 0.05)
comprobar("la modificacion no reaparece con items solo autoinformados",
          met$p[met$razon == "log_ratio_p2" & met$desenlace == "UPDRS3_resto"][1] > 0.05)

est <- T("t03_fenotipo_estabilidad.csv")
comprobar("la concordancia con la clase basal sigue cayendo con el horizonte",
          est$concordancia[est$visita == "V12"][1] < est$concordancia[est$visita == "V04"][1])
comprobar("la concordancia a 5 anios sigue por debajo de dos tercios",
          est$concordancia[est$visita == "V12"][1] < 0.667)

# ------------------------------------------------------------ LONGITUDINAL --
seccion("Longitudinal y atricion (ADR 0009 y 0010)")

mix <- T("t04_mixto.csv")
comprobar("el dolor basal sigue asociandose con el NIVEL motor",
          mix$p[mix$termino == "dolor basal (nivel)"][1] < 0.05)
comprobar("el dolor basal sigue SIN asociarse con la PENDIENTE",
          mix$p[mix$termino == "dolor basal x tiempo"][1] > 0.05)

mixw <- T("t04_mixto_ipcw.csv")
comprobar("ponderar por censura no cambia la conclusion sobre el nivel",
          mixw$p[mixw$termino == "dolor basal (nivel)"][1] < 0.05)
comprobar("ponderar por censura no cambia la conclusion sobre la pendiente",
          mixw$p[mixw$termino == "dolor basal x tiempo"][1] > 0.05)

lord <- T("t04_lord.csv")
comprobar("ANCOVA y puntuacion de cambio siguen coincidiendo en DIRECCION",
          all(lord$estimacion > 0))
comprobar("la puntuacion de cambio sigue SIN alcanzar significacion",
          lord$p[grepl("cambio", lord$especificacion)][1] > 0.05)

atr <- T("t04_atricion_predictores.csv")
comprobar("el dolor basal sigue SIN predecir el abandono en ningun horizonte",
          all(atr$p[atr$termino == "dolor_bl"] > 0.05))
comprobar("la severidad motora basal SI predice el abandono a 5 anios",
          atr$p[atr$termino == "motor_bl" & atr$visita == "V12"][1] < 0.05)

disc <- T("t04_discriminante.csv")
comprobar("el dolor sigue entre los predictores de la severidad motora futura",
          disc$p[disc$sintoma == "dolor"][1] < 0.05)
comprobar("el dolor sobrevive a Benjamini-Hochberg pero NO a Holm",
          disc$p_bh[disc$sintoma == "dolor"][1] < 0.05 &&
            disc$p_holm[disc$sintoma == "dolor"][1] > 0.05)
comprobar("depresion, ansiedad, sueno REM, autonomico y somnolencia siguen nulos",
          all(disc$p[disc$sintoma %in% c("depresion", "ansiedad", "sueno_REM",
                                         "autonomico", "somnolencia")] > 0.05))

ctrl <- T("t04_controles_negativos.csv")
comprobar("el dolor sigue SIN predecir el MoCA a 12 meses",
          ctrl$p[ctrl$desenlace == "moca_v04"][1] > 0.05)

ev <- T("t04_evalue.csv")
comprobar("el E-value sigue siendo bajo (fragil a confusion no medida)",
          ev$evalue_puntual[1] < 2 && ev$evalue_ic[1] < 1.5)
comprobar("el E-value se calculo sobre la escala ESTANDARIZADA, no la cruda",
          !is.na(ev$sd_desenlace[1]) && ev$sd_desenlace[1] > 5)

# -------------------------------------------------------------------- MSM ---
seccion("Confusion variable en el tiempo (ADR 0010)")

msm <- T("t05_sintesis_msm.csv")
crudo <- msm$estimacion[grepl("SIN ajustar", msm$especificacion)][1]
iptw <- msm$estimacion[grepl("marginal", msm$especificacion)][1]
gcomp <- msm$estimacion[grepl("estimacion g", msm$especificacion)][1]

comprobar("el modelo estructural marginal sigue ATENUANDO frente al estandar",
          iptw < crudo)
comprobar("la atenuacion sigue rondando un tercio",
          (1 - iptw / crudo) > 0.20 && (1 - iptw / crudo) < 0.55)
comprobar("los dos estimadores causales siguen coincidiendo entre si",
          abs(iptw - gcomp) < 0.5)
comprobar("la asociacion sigue siendo distinta de cero tras ponderar", {
  b <- msm |> filter(grepl("remuestreo", especificacion)); b$ic_bajo[1] > 0
})

bal <- T("t05_balance.csv")
comprobar("la ponderacion sigue MEJORANDO el balance de la dosis previa",
          abs(bal$ponderada[1]) < abs(bal$sin_ponderar[1]))

pi <- T("t05_pesos_iptw.csv")
comprobar("los pesos de tratamiento siguen centrados cerca de uno",
          all(pi$media > 0.9 & pi$media < 1.1))

# ----------------------------------------------------------------- CIFRAS ---
seccion("Cifras y manuscrito")

cif <- fromJSON(CIFRAS, simplifyVector = FALSE)
comprobar("cifras.json existe y no esta vacio", length(cif) > 100)
comprobar("toda cifra es una cadena ya formateada",
          all(vapply(cif, is.character, logical(1))))
comprobar("ninguna cifra quedo como NA",
          !any(vapply(cif, function(x) grepl("NA", x), logical(1))))
comprobar("el N del manuscrito coincide con el flujo STROBE",
          cif$n_v04 == "711")

manu <- file.path(ROOT, "manuscript", "paper.md")
comprobar("el manuscrito existe", file.exists(manu))
if (file.exists(manu)) {
  txt <- paste(readLines(manu, warn = FALSE), collapse = "\n")
  marcadores <- unique(gsub("[{}]", "",
    unlist(regmatches(txt, gregexpr("\\{\\{[a-zA-Z0-9_]+\\}\\}", txt)))))
  comprobar("todo marcador del manuscrito tiene su cifra",
            length(setdiff(marcadores, names(cif))) == 0)
  comprobar("el manuscrito no tiene rayas tipograficas", !grepl("—", txt))
  comprobar("ninguna cifra clave esta tecleada a mano en el texto",
            !grepl("\\b711\\b|\\b1,190\\b|0\\.175", txt))
}

# ------------------------------------------------------------------ CIERRE --
cat("\n", strrep("=", 74), "\n", sep = "")
cat(sprintf("%d pruebas, %d fallos\n", n_ok + n_fallo, n_fallo))
cat(strrep("=", 74), "\n")
if (n_fallo > 0) quit(status = 1)
