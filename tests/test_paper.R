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
ri_b <- sem |> filter(modelo == "RI-CLPM restringido", etiqueta == "b")
ri_c <- sem |> filter(modelo == "RI-CLPM restringido", etiqueta == "c")

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
          mix$p[grepl("^dolor basal \\(nivel", mix$termino)][1] < 0.05)
comprobar("el dolor basal sigue SIN asociarse con la PENDIENTE",
          mix$p[mix$termino == "dolor basal x tiempo"][1] > 0.05)

mixw <- T("t04_mixto_ipcw.csv")
comprobar("ponderar por censura no cambia la conclusion sobre el nivel",
          mixw$p[grepl("^dolor basal \\(nivel", mixw$termino)][1] < 0.05)
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
gcomp <- msm$estimacion[grepl("sustitucion", msm$especificacion)][1]

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


# ------------------------------------------------------- DOMINIOS MOTORES ---
seccion("Descomposicion por dominio motor (H1)")

dom <- T("t09_dominios_entre.csv")
comprobar("el temblor sigue SIN asociarse con el dolor",
          dom$p[dom$dominio == "temblor"][1] > 0.05)
comprobar("los otros cuatro dominios siguen asociandose",
          all(dom$p[!dom$dominio %in% c("temblor", "TOTAL (referencia)")] < 0.05))
dif <- T("t09_dominios_diferencial.csv")
comprobar("el eje rigidez-bradicinesia sigue difiriendo del temblor",
          dif$p[1] < 0.05 && dif$ic_bajo[1] > 0)
ras <- T("t09_dominios_rasgo.csv")
comprobar("el dominio axial sigue teniendo la correlacion de rasgo mas alta",
          ras$r_rasgo[ras$dominio == "axial"][1] ==
            max(ras$r_rasgo[ras$dominio != "TOTAL (referencia)"], na.rm = TRUE))

# --------------------------------------------------- CONTROLES DE COHORTE ---
seccion("Controles negativos de cohorte (H5)")

coh <- T("t10_controles_negativos.csv")
comprobar("las tres cohortes siguen presentes", nrow(coh) == 3)
comprobar("la correlacion de rasgo sigue siendo positiva en las tres",
          all(coh$r_rasgo > 0))
comprobar("los controles sanos siguen teniendo un recorrido motor mucho menor",
          coh$de_motor[grepl("Controles", coh$cohorte)] <
            coh$de_motor[grepl("Parkinson", coh$cohorte)] / 3)
cmp <- T("t10_comparacion_correlaciones.csv")
comprobar("Parkinson y controles siguen SIN diferenciarse significativamente",
          cmp$p[grepl("controles", cmp$contraste)][1] > 0.05)
comprobar("el intervalo de esa diferencia sigue siendo ancho (no concluyente)", {
  f <- cmp |> filter(contraste == "Parkinson vs controles sanos")
  (f$ic_alto[1] - f$ic_bajo[1]) > 0.15
})

# ---------------------------------------------- CONTRASTE DE HIPOTESIS ------
seccion("Contraste de hipotesis mecanisticas")

h2 <- T("t11_h2_dat.csv") |> filter(region == "dat_estriado")
comprobar("la severidad motora sigue siguiendo al DAT estriatal",
          h2$p[h2$desenlace == "motor"][1] < 0.001 &&
            h2$beta_de[h2$desenlace == "motor"][1] < 0)
comprobar("el dolor sigue SIN seguir al DAT estriatal",
          h2$p[h2$desenlace == "dolor"][1] > 0.05)
h2b <- T("t11_h2_ajuste_dat.csv")
comprobar("ajustar por DAT sigue sin cambiar la asociacion dolor-motor",
          abs(h2b$b[1] - h2b$b[2]) < 0.02)

h3 <- T("t11_h3_cargas.csv")
comprobar("el temblor sigue SIN cargar en el factor general",
          h3$p[h3$indicador == "temblor"][1] > 0.05)
comprobar("el dolor sigue cargando menos que los dominios motores", {
  cd <- h3$carga_std[h3$indicador == "dolor"]
  cm <- mean(h3$carga_std[h3$indicador %in% c("rigidez", "bradicinesia", "axial", "bulbar")])
  cd > 0 && cd < cm / 2
})
# La prueba anterior leia el residuo por puntuaciones factoriales, que era un
# artefacto de parte-todo. La sustituye la prueba anidada correcta.
h3a <- T("t11_h3_anidado.csv")
comprobar("liberar la covarianza residual dolor-motor no mejora el ajuste",
          h3a$p[1] > 0.05)

h4 <- T("t11_h4_icc.csv")
comprobar("el dolor sigue siendo la medida MENOS de rasgo de las cuatro",
          h4$icc[grepl("Dolor", h4$serie)][1] == min(h4$icc))
comprobar("la ICC del dolor sigue por debajo de 0,5 (poca senal entre personas)",
          h4$icc[grepl("Dolor", h4$serie)][1] < 0.5)

h8 <- T("t11_h8_miembros.csv")
comprobar("no hay gradiente miembro inferior frente a superior",
          h8$p[grepl("diferencia", h8$region)][1] > 0.05)

sint <- T("t11_sintesis_hipotesis.csv")
comprobar("la sintesis cubre las ocho hipotesis", nrow(sint) == 8)


# ------------------------------------- CORRECCIONES TRAS LA REVISION POR PARES ---
seccion("Correcciones tras la revision por pares")

aj <- T("t01_ajuste_modelos.csv")
comprobar("el RI-CLPM libre sigue ajustando mejor que el CLPM clasico",
          aj$cfi[grepl("libre", aj$modelo)][1] > aj$cfi[grepl("^CLPM", aj$modelo)][1])
rl <- T("t01_correlacion_rasgo_libre.csv")
comprobar("la correlacion de rasgo sobrevive al modelo LIBRE (el primario)",
          rl$r[1] > 0 && rl$p[1] < 0.05)

vc <- T("t01_direccionalidad_rezagos.csv") |> filter(grepl("COMUN", modelo))
comprobar("el analisis de panel COMUN existe y tiene las dos direcciones",
          nrow(vc) == 2)
comprobar("en el panel comun la direccion motor -> dolor NO alcanza significacion",
          vc$p[grepl("motor -> dolor", vc$modelo)][1] > 0.05)

an <- T("t11_h3_anidado.csv")
comprobar("liberar la covarianza residual dolor-motor sigue SIN mejorar el ajuste",
          an$p[1] > 0.05)
comprobar("el ajuste del modelo de un factor se exporta", nrow(T("t11_h3_ajuste.csv")) == 1)
rz <- T("t11_h3_residuos_z.csv")
comprobar("ningun residuo estandarizado dolor-motor supera |1,96|",
          all(abs(rz$residuo_z) < 1.96))

dg <- T("t09_diferencial_gds.csv")
comprobar("la disociacion del temblor NO es especifica del dolor", {
  dp <- T("t09_dominios_diferencial.csv")
  dg$p[1] < 0.05 && abs(dg$diferencia[1] - dp$diferencia[1]) < 0.10
})

er <- T("t05_estatus_regla.csv")
comprobar("la regla preespecificada del MSM se evalua y se registra", nrow(er) == 1)
comprobar("la regla NO se cumple, y el MSM queda como sensibilidad",
          !er$cumplida[1] && grepl("SENSIBILIDAD|sensibilidad", er$consecuencia[1]))

mw <- T("t04_mixto_ipcw.csv")
comprobar("el modelo ponderado usa varianza robusta (EE mayor que el no ponderado)", {
  mu <- T("t04_mixto.csv")
  mw$ee[grepl("nivel", mw$termino)][1] > mu$ee[grepl("nivel", mu$termino)][1]
})

ctrl <- T("t04_controles_negativos.csv")
comprobar("los DOS controles negativos siguen exportandose", nrow(ctrl) == 2)
comprobar("el control del GDS sigue siendo significativo (control que FALLA)",
          ctrl$p[ctrl$desenlace == "gds_v04"][1] < 0.05)

manu_t <- paste(readLines(file.path(ROOT, "manuscript", "paper.md"), warn = FALSE), collapse = "\n")
comprobar("el manuscrito reporta el control negativo del GDS",
          grepl("ctrl_gds_p", manu_t))
comprobar("el manuscrito ya NO afirma que la disociacion distingue al dolor",
          !grepl("which depression does not show", manu_t))
comprobar("el manuscrito confronta la diferencia clinicamente importante",
          grepl("4.63", manu_t))
comprobar("el titulo del manuscrito sigue siendo sobre DOLOR y sintomas motores",
          grepl("^# Pain and motor severity", manu_t))
comprobar("el manuscrito remite a los DAGs causales", grepl("Figure 7", manu_t))
comprobar("existe la fuente Mermaid de los DAGs longitudinales",
          file.exists(file.path(ROOT, "docs", "dags-longitudinales.md")))
comprobar("existe la version TikZ de los DAGs",
          file.exists(file.path(ROOT, "figuras-tikz", "dags_longitudinales.tex")))
comprobar("la figura de los DAGs esta generada",
          file.exists(file.path(ROOT, "outputs", "paper", "figures", "figure7_dags.pdf")))
comprobar("el manuscrito ya NO usa el residuo por puntuaciones factoriales",
          !grepl("h3_residual_r", manu_t))

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


# --------------------------------- SEGUNDA RONDA DE REVISION POR PARES --------
seccion("Segunda ronda de revision")

fl2 <- T("t12_flujo_poblaciones.csv")
comprobar("las cinco poblaciones estan definidas en un solo sitio", nrow(fl2) == 5)
comprobar("la muestra de 12 meses sigue siendo 711",
          fl2$n[grepl("12 meses", fl2$etiqueta)][1] == 711)
comprobar("las poblaciones siguen anidadas correctamente",
          fl2$n[fl2$etiqueta == "Cohorte basal con ambas medidas"] <=
            fl2$n[fl2$etiqueta == "Cohorte basal"])

mgw <- T("t10_multigrupo_wald.csv")
comprobar("el SEM multigrupo se ajusta y exporta su prueba de Wald", nrow(mgw) == 1)
comprobar("la igualdad de correlaciones entre cohortes NO se rechaza", mgw$p[1] > 0.05)
mgr <- T("t10_multigrupo_rho.csv")
comprobar("el multigrupo da las tres correlaciones con su EE del modelo",
          nrow(mgr) == 3 && all(mgr$ee > 0))
comprobar("el EE del multigrupo es MAYOR que el de Fisher z (que subestimaba)", {
  fz <- T("t10_comparacion_correlaciones.csv") |> filter(grepl("controles", contraste))
  mgd <- T("t10_multigrupo_dif.csv") |> filter(grepl("Controles", contraste))
  (mgd$ic_alto[1] - mgd$ic_bajo[1]) > (fz$ic_alto[1] - fz$ic_bajo[1])
})

ptv <- T("t04_pesos_ipcw_tv.csv")
comprobar("el IPCW secuencial con predictores variables se calcula", nrow(ptv) >= 4)
comprobar("los pesos secuenciales estan MAS dispersos que los basales", {
  pb <- T("t04_pesos_ipcw.csv")
  max(ptv$de) > (max(pb$max) - min(pb$min)) / 20
})
comprobar("los pesos secuenciales siguen centrados cerca de uno",
          all(ptv$media > 0.85 & ptv$media < 1.15))

inv <- T("t13_inventario_resumen.csv")
comprobar("el inventario clasifica los contrastes en tres categorias", nrow(inv) == 3)
comprobar("hay contrastes primarios declarados",
          inv$contrastes[inv$categoria == "primario"] > 0)

refs <- fromJSON(file.path(ROOT, "manuscript", "referencias.json"), simplifyVector = FALSE)
comprobar("la base de referencias existe y no esta vacia", length(refs) > 100)
comprobar("toda referencia lleva PMID o DOI",
          all(vapply(refs, function(r) grepl("PMID|doi:", r), logical(1))))
if (file.exists(manu)) {
  claves <- unique(gsub("^\\[@|\\]$", "",
    unlist(regmatches(txt, gregexpr("\\[@[A-Za-z0-9_]+\\]", txt)))))
  comprobar("el manuscrito ya tiene citas", length(claves) > 20)
  comprobar("toda clave citada existe en la base de referencias",
            length(setdiff(claves, names(refs))) == 0)
  comprobar("el manuscrito declara que el item 1.9 no es un instrumento de dolor",
            grepl("Pain and Other Sensations", txt))
  comprobar("el manuscrito declara el inventario de contrastes",
            grepl("inv_total", txt))
}


# ----------------------------------------- TERCERA RONDA: CORRECCIONES R2 -----
seccion("Correcciones de la ronda 2")

p2 <- T("t02_parte2_vs_parte3.csv")
comprobar("el contraste Parte II frente a Parte III se ejecuta", nrow(p2) == 4)
comprobar("la correlacion de rasgo es MUCHO mayor con la Parte II autoinformada", {
  r3 <- p2$r_rasgo[p2$desenlace == "Parte III (examinador)"][1]
  r2 <- p2$r_rasgo[p2$desenlace == "Parte II (autoinformada)"][1]
  r2 > 2 * r3
})
comprobar("con la Parte II la via que sobrevive es motor -> dolor",
          p2$p[p2$desenlace == "Parte II (autoinformada)" &
                 p2$via == "desenlace(t-1) -> exposicion(t)"][1] < 0.05)

mtv <- T("t04_mixto_ipcw_tv.csv")
comprobar("el modelo con pesos secuenciales SI se ajusta", nrow(mtv) == 3)
comprobar("con pesos secuenciales el nivel sigue y la pendiente sigue nula",
          mtv$p[grepl("nivel", mtv$termino)][1] < 0.05 &&
            mtv$p[grepl("x tiempo", mtv$termino)][1] > 0.05)

comprobar("el multigrupo ya NO restringe la dinamica entre cohortes",
          any(grepl("c\\(a1,a2,a3\\)", readLines(
            file.path(ROOT, "R", "paper", "10_controles_negativos.R"), warn = FALSE))))
comprobar("el multigrupo coincide ahora con el modelo de un grupo", {
  mg <- T("t10_multigrupo_rho.csv"); un <- T("t01_correlacion_rasgo.csv")
  abs(mg$r[grepl("Parkinson", mg$cohorte)][1] - un$r[1]) < 0.02
})

inv <- T("t13_inventario_contrastes.csv")
comprobar("el inventario ya no se cuenta a si mismo", !any(grepl("t13", inv$tabla)))

comprobar("las tablas huerfanas ya no existen",
          !file.exists(file.path(TAB, "t11_h3_residual.csv")) &&
            !file.exists(file.path(TAB, "t10_multigrupo.csv")))

if (file.exists(manu)) {
  comprobar("el manuscrito ya NO afirma que Liu 2020 midiera dolor",
            !grepl("extends a previous report in this cohort that pain did not feature", txt))
  comprobar("el manuscrito ya NO llama formula g a la sustitucion",
            !grepl("cross-checked by g-computation|and g-computation \\{\\{msm_gcomp", txt))
  comprobar("el manuscrito ya NO dice que el efecto sea clinicamente util",
            !grepl("which is clinically useful", txt))
  comprobar("el resumen usa la correlacion del modelo PRIMARIO (libre)",
            grepl("rasgo_libre_r", txt))
  comprobar("la limitacion de fiabilidad esta en Limitaciones",
            grepl("within-person reliability of the exposure is the", txt))
  comprobar("se cita el trabajo competidor de panel cruzado en PPMI",
            grepl("hodgson2026_ppmi_crosslag", txt))
  comprobar("no queda ningun encabezado colisionado con una frase",
            !grepl("[a-z]\\. ### ", txt))
}


# ----------------------------------------------- ANALISIS CLINICOS -----------
seccion("Analisis clinicos")

an <- T("t14_analgesicos.csv")
comprobar("el ajuste por analgesicos se ejecuta con sus cuatro variantes", nrow(an) == 4)
comprobar("la asociacion SOBREVIVE al ajuste por analgesicos",
          an$p[grepl("sin aspirina", an$ajuste)][1] < 0.05)
comprobar("el analgesico atenua, pero menos de la mitad",
          (1 - an$beta_de[2] / an$beta_de[1]) > 0 &&
            (1 - an$beta_de[2] / an$beta_de[1]) < 0.5)
am <- T("t14_analgesico_motor.csv")
comprobar("el analgesico SI predice la severidad motora (es confusor real)",
          am$p[1] < 0.05)

se <- T("t14_sexo_estratos.csv")
comprobar("la asociacion es mayor en mujeres que en varones",
          se$beta_de[1] > se$beta_de[2])
sx <- T("t14_sexo_interaccion.csv")
comprobar("la interaccion por sexo NO alcanza significacion", sx$p[1] > 0.05)

p4 <- T("t14_parte4.csv")
comprobar("la asociacion sobrevive al ajuste por complicaciones motoras",
          p4$p[2] < 0.05)
p4e <- T("t14_parte4_estratos.csv")
comprobar("la asociacion esta presente con y sin complicaciones motoras",
          all(p4e$p < 0.05, na.rm = TRUE))

par <- T("t14_paralelos_parte1.csv")
comprobar("se contrastan cuatro sintomas de la Parte I en paralelo", nrow(par) == 4)
comprobar("el dolor NO destaca sobre los otros sintomas no motores",
          par$r_rasgo[par$sintoma == "dolor"][1] <=
            max(par$r_rasgo[par$sintoma != "dolor"]))
comprobar("al menos otro sintoma de la Parte I supera al dolor",
          any(par$r_rasgo[par$sintoma != "dolor"] > par$r_rasgo[par$sintoma == "dolor"][1]))

if (file.exists(manu)) {
  comprobar("el manuscrito reporta el ajuste por analgesicos",
            grepl("analg_atenua", txt))
  comprobar("el manuscrito reporta que el dolor no destaca entre los no motores",
            grepl("par_insomnio_r", txt))
  comprobar("la carga general se presenta como lo que los datos apoyan",
            grepl("not as an alternative we failed to exclude", txt))
}


# ------------------------------------ VERIFICACION DE LA RONDA 3 --------------
seccion("Verificacion de la ronda 3")

pa <- T("t14_prevalencia_analgesicos.csv")
comprobar("la prevalencia de analgesicos se exporta", nrow(pa) == 3)
comprobar("la prevalencia de analgesicos NO coincide con la retencion", {
  cif <- fromJSON(CIFRAS, simplifyVector = FALSE)
  cif$analg_prev != cif$ret2_pct_V12
})

se <- T("t14_sexo_estratos.csv")
comprobar("la tabla de sexo conserva las etiquetas y no los codigos",
          any(grepl("Mujer|Varon", as.character(se$sexo))))
comprobar("el estrato de mujeres es el mas pequeno de los dos (65 % varones)",
          se$n[grepl("Mujer", as.character(se$sexo))][1] <
            se$n[grepl("Varon", as.character(se$sexo))][1])

inv <- T("t13_inventario_contrastes.csv")
comprobar("el inventario incluye las tablas de los analisis clinicos",
          any(grepl("^t14", inv$tabla)))
comprobar("el inventario captura las p de los sintomas paralelos",
          any(inv$tabla == "t14_paralelos_parte1.csv"))

if (file.exists(manu)) {
  comprobar("el manuscrito ya NO llama confusor al analgesico",
            !grepl("so it is a genuine confounder", txt))
  comprobar("el manuscrito explica que el analgesico es descendiente del dolor",
            grepl("descendant of the exposure", txt))
  comprobar("ya no queda ninguna frase que diga que la carga general no se excluyo",
            !grepl("remains live|burden[^.]{0,80}cannot exclude", txt))
# Esta prueba exigia que el articulo CONCEDIERA el confusor de estilo. Desde que
# se contrasta (R/paper/15_estilo_de_reporte.R), conceder ya no es lo correcto:
# lo correcto es reportar el contraste y declarar lo que sigue sin poder
# descartarse. La prueba se actualiza al estado nuevo, no se revierte el avance.
comprobar("el articulo declara que el confusor de estilo es serio y lo contrasta",
          grepl("most serious alternative explanation", txt) &&
            grepl("We tested it rather than conceding it", txt))
comprobar("el articulo declara lo que el contraste NO descarta",
          grepl("reporting tendency that tracks genuine examined severity", txt))
  comprobar("el resumen incorpora la no especificidad",
            grepl("not specific to pain", substr(txt, 1, 6000)))
  comprobar("el resumen reporta los tres indices de ajuste",
            grepl("fit_ri_libre_rmsea", txt))
  comprobar("las lineas convergentes ya no se presentan como independientes",
            !grepl("five independent line", txt))
}


# ------------------------------ REVISION INDEPENDIENTE (contexto limpio) ------
seccion("Revision independiente")

sl <- T("t01_sem_libre_por_ola.csv")
comprobar("se extraen las vias del modelo PRIMARIO (libre), por ola", nrow(sl) >= 16)
slr <- T("t01_sem_libre_resumen.csv")
comprobar("en el modelo primario la via motor->dolor NO alcanza ninguna ola",
          slr$olas_significativas[grepl("inverso", slr$parametro)][1] == 0)
comprobar("en el modelo primario la via dolor->motor alcanza como mucho una ola",
          slr$olas_significativas[grepl("directo", slr$parametro)][1] <= 1)

ra <- T("t01_correlacion_rasgo_ajustada.csv")
comprobar("la correlacion de rasgo se estima AJUSTADA por las basales", nrow(ra) == 1)
comprobar("la correlacion de rasgo sobrevive al ajuste", ra$p[1] < 0.05)

pw <- T("t04_pesos_ipcw.csv"); ptv <- T("t04_pesos_ipcw_tv.csv")
comprobar("la comparacion de dispersion de pesos es DE frente a DE",
          "de" %in% names(pw) && "de" %in% names(ptv))

comprobar("la figura 2 ya NO lleva cifras de ajuste tecleadas",
          !any(grepl("CFI 0.960 vs 0.877", readLines(
            file.path(ROOT, "R", "paper", "06_figuras.R"), warn = FALSE))))

if (file.exists(manu)) {
  comprobar("Metodos ya NO afirma que todos los modelos lleven covariables",
            !grepl("The adjustment set for all models", txt))
  comprobar("el manuscrito declara que los modelos de panel van sin ajustar",
            grepl("deliberately unadjusted", txt))
  comprobar("la aritmetica de la DMCI ya no dice 'about four points'",
            !grepl("it reaches about four points", txt))
  comprobar("el manuscrito reporta el recorrido completo real (5,58)",
            grepl("mcid_recorrido", txt))
  comprobar("el manuscrito reporta el fallo del control del MoCA a nivel de rasgo",
            grepl("moca_rasgo_r", txt))
  comprobar("el resumen ya no dice 'equal correlation' en controles",
            !grepl("an equal correlation in", txt))
  comprobar("la dispersion del IPCW ya no afirma infraajuste",
            !grepl("so the simpler model was indeed underfit", txt))
}


# ---------------------------- CITAS CORREGIDAS TRAS LA REVISION INDEPENDIENTE --
seccion("Citas corregidas")

refs2 <- fromJSON(file.path(ROOT, "manuscript", "referencias.json"), simplifyVector = FALSE)
for (k in c("zolfaghari2022_selfreport", "silverdale2018_pain_survey",
            "marek2011_ppmi", "yang2023_ppmi_dat", "lin2013_pain_incident_pd")) {
  comprobar(paste("la referencia", k, "esta verificada"),
            !is.null(refs2[[k]]) && grepl("PMID", refs2[[k]]))
}
if (file.exists(manu)) {
  comprobar("VanderWeele 2019 ya no se cita para la escala del E-value",
            !grepl("a distinction that is frequently mishandled", txt))
  comprobar("Pautrat ya no se cita para una afirmacion sobre Braak",
            !grepl("early Braak stages", txt))
  comprobar("la prevalencia se presenta como replica y no como observacion nueva",
            grepl("replicates the 57 per cent", txt))
  comprobar("Ren y Rodriguez-Violante ya no sostienen la prediccion de modificacion",
            grepl("which no prior study has tested", txt))
  comprobar("se cita el confusor de estilo de respuesta en Limitaciones",
            grepl("zolfaghari2022_selfreport", txt))
  comprobar("se cita el comparador mas grande de la literatura",
            grepl("silverdale2018_pain_survey", txt))
  comprobar("el articulo acota su ventana frente a la precedencia prodromica",
            grepl("lin2013_pain_incident_pd", txt))
  comprobar("la fuente de datos de PPMI es la correcta",
            grepl("marek2011_ppmi", txt))
}


# ------------------------------------------- ESTILO DE REPORTE ----------------
seccion("El confusor de estilo de reporte")

ee <- T("t15_estilo_dolor.csv")
comprobar("el indice de estilo se asocia con el dolor (el confusor existe)",
          ee$beta_de[1] > 0.2 && ee$p[1] < 0.001)
es <- T("t15_estabilidad_estilo.csv")
comprobar("el indice de estilo es estable en el tiempo (es un rasgo, no ruido)",
          es$r[1] > 0.5)

d2 <- T("t15_dos_desenlaces.csv")
comprobar("el estilo NO explica la asociacion con la Parte III explorada",
          d2$p_con[grepl("III", d2$desenlace)][1] < 0.05)
comprobar("el estilo SI explica la mayor parte de la asociacion con la Parte II",
          d2$atenuacion_pct[grepl("II \\(auto", d2$desenlace)][1] > 50)
comprobar("la atenuacion es mucho mayor en la autoinformada que en la explorada",
          d2$atenuacion_pct[grepl("II \\(auto", d2$desenlace)][1] >
            d2$atenuacion_pct[grepl("III", d2$desenlace)][1] + 40)

d3 <- T("t15_indice_alternativo.csv")
comprobar("el indice alternativo NO es ortogonal a la Parte III por construccion",
          d3$atenuacion_pct[grepl("III", d3$desenlace)][1] > 0)
comprobar("con el indice alternativo la asociacion explorada sigue en pie",
          d3$p_con[grepl("III", d3$desenlace)][1] < 0.05)
comprobar("con el indice alternativo la atenuacion sigue siendo mayor en la Parte II",
          d3$atenuacion_pct[grepl("II \\(auto", d3$desenlace)][1] >
            d3$atenuacion_pct[grepl("III", d3$desenlace)][1])

if (file.exists(manu)) {
  comprobar("el manuscrito CONTRASTA el estilo de reporte y no solo lo concede",
            grepl("We tested it rather than conceding it", txt))
  comprobar("el manuscrito declara la ortogonalidad por construccion del primer indice",
            grepl("orthogonal to it by construction", txt))
  comprobar("la seccion de la Parte II ya no queda abierta",
            !grepl("Two readings are available and we cannot separate them here", txt))
}

# ============================================================ PENDIENTE ALEATORIA
seccion("El supuesto de pendiente fija del RI-CLPM (ADR 0013)")

pc <- T("t16_pendiente_comparacion.csv")
fila <- function(patron) which(grepl(patron, pc$modelo))[1]
i_ri <- fila("^RI-CLPM"); i_ce <- fila("centradas"); i_ba <- fila("0 a 5")
comprobar("se ajustan las tres especificaciones de la pendiente", nrow(pc) == 3)

pl <- T("t16_pendiente_lrt.csv")
comprobar("el supuesto de pendiente fija ESTA violado: el ajuste mejora",
          pl$p[1] < 0.001 && pl$gl[1] == 7)
comprobar("el modelo con pendiente ajusta mejor en los tres indices",
          pc$cfi[i_ce] > pc$cfi[i_ri] && pc$rmsea[i_ce] < pc$rmsea[i_ri] &&
            pc$srmr[i_ce] < pc$srmr[i_ri])

# Lo que sostiene el articulo es que la violacion no distorsiona el resultado.
comprobar("la correlacion de rasgo se desplaza menos de 0,05 al liberar la pendiente",
          abs(pc$r_rasgo[i_ce] - pc$r_rasgo[i_ri]) < 0.05)
comprobar("la correlacion de rasgo sigue siendo significativa con pendiente libre",
          pc$p_rasgo[i_ce] < 0.05)
comprobar("ninguna via intrapersonal sobrevive al liberar la pendiente",
          pc$p_dolor_motor[i_ce] > 0.05 && pc$p_motor_dolor[i_ce] > 0.05)
comprobar("la via dolor a motor del modelo restringido NO sobrevive",
          pc$p_dolor_motor[i_ri] < 0.05 && pc$p_dolor_motor[i_ce] > 0.05)

pv <- T("t16_varianza_pendientes.csv")
comprobar("la varianza de pendiente es mayor en lo motor que en el dolor",
          pv$varianza[pv$pendiente == "Sm"][1] > pv$varianza[pv$pendiente == "Sd"][1])

# Esta es la prueba que impide que reaparezca el error de centrado del ADR 0010.
comprobar("las dos parametrizaciones de la curva latente son el MISMO modelo",
          abs(pc$aic[i_ce] - pc$aic[i_ba]) < 0.01)
comprobar("y sin embargo dan correlaciones distintas: la cifra depende del origen",
          abs(pc$r_rasgo[i_ba] - pc$r_rasgo[i_ce]) > 0.03)
comprobar("el articulo reporta la centrada, no la mayor de las dos",
          pc$r_rasgo[i_ba] > pc$r_rasgo[i_ce])

if (file.exists(manu)) {
  comprobar("el manuscrito declara que el supuesto de pendiente fija se contrasto",
            grepl("latent curve model with structured residuals", txt))
  comprobar("el manuscrito advierte del artefacto de parametrizacion",
            grepl("property of where the origin of time is placed", txt))
  comprobar("el manuscrito NO reporta la correlacion sin centrar como hallazgo",
            !grepl("trait correlation rose to 0.242", txt))
}

# ------------------------------------------------------------------ CIERRE --
cat("\n", strrep("=", 74), "\n", sep = "")
cat(sprintf("%d pruebas, %d fallos\n", n_ok + n_fallo, n_fallo))
cat(strrep("=", 74), "\n")
if (n_fallo > 0) quit(status = 1)
