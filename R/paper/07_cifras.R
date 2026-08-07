#!/usr/bin/env Rscript
# =============================================================================
# ARTICULO — Exporta TODA cifra que aparece en el manuscrito.
#
# Regla del proyecto: ninguna cifra se teclea a mano en el texto. Todas salen de
# outputs/paper/cifras.json, que genera este script desde las tablas de los
# modelos ajustados. Durante la auditoria de la tesis circulaban cinco tamanos
# muestrales distintos precisamente porque se escribian a mano.
#
# El manuscrito se compone con docx/articulo.js, que sustituye cada marcador
# {{clave}} por su valor y ABORTA si un marcador no existe en este archivo.
#
# Ejecutar:  Rscript R/paper/07_cifras.R
# =============================================================================

source(file.path(Sys.getenv("TESIS_ROOT", unset = getwd()), "R", "paper", "00_comun.R"))
suppressPackageStartupMessages({ library(jsonlite) })

titulo("EXPORTANDO CIFRAS DEL ARTICULO")

T <- function(f) read_csv(file.path(PAPER_TAB, f), show_col_types = FALSE)

# Formato ingles: punto decimal, coma de millar.
n2 <- function(x, d = 2) formatC(as.numeric(x), format = "f", digits = d, big.mark = ",")
ent <- function(x) formatC(as.integer(x), format = "d", big.mark = ",")
pv2 <- function(p) {
  p <- as.numeric(p)
  ifelse(p < 0.001, "<0.001", formatC(p, format = "f", digits = 3))
}
ic2 <- function(lo, hi, d = 2) sprintf("%s to %s", n2(lo, d), n2(hi, d))
pct <- function(x, d = 1) paste0(n2(x, d), "%")

C <- list()
poner <- function(clave, valor) C[[clave]] <<- valor

# ------------------------------------------------------------------ MUESTRA --
flujo <- read_csv(file.path(DATOS, "flow_v04.csv"), show_col_types = FALSE)
fl <- setNames(flujo$n, flujo$step)
for (k in names(fl)) poner(paste0("flow_", k), ent(fl[[k]]))
poner("n_v04", ent(fl[["after_motor_complete"]]))

d <- cargar_largo("off")
dm <- d |> filter(!is.na(UPDRS3), !is.na(NP1PAIN))
poner("n_baseline", ent(sum(d$EVENT_ID == "BL")))
poner("n_pacientes_panel", ent(n_distinct(dm$PATNO)))
poner("n_obs_panel", ent(nrow(dm)))

v04 <- dm |> filter(EVENT_ID == "V04")
poner("edad_media", n2(mean(v04$age_yrs, na.rm = TRUE), 1))
poner("edad_de", n2(sd(v04$age_yrs, na.rm = TRUE), 1))
poner("pct_varones", pct(100 * mean(v04$sex_male, na.rm = TRUE)))
poner("duracion_media", n2(mean(v04$disease_yrs, na.rm = TRUE), 2))
poner("duracion_de", n2(sd(v04$disease_yrs, na.rm = TRUE), 2))
poner("updrs3_medio", n2(mean(v04$UPDRS3, na.rm = TRUE), 1))
poner("updrs3_de", n2(sd(v04$UPDRS3, na.rm = TRUE), 1))
poner("pct_con_dolor", pct(100 * mean(v04$dolor_si, na.rm = TRUE)))
poner("moca_medio", n2(mean(v04$MoCA, na.rm = TRUE), 1))
poner("ledd_mediana", n2(median(v04$LEDD, na.rm = TRUE), 0))

# ------------------------------------------------------------ RETENCION ------
ret <- T("t04_retencion.csv")
for (i in seq_len(nrow(ret))) {
  poner(paste0("ret_n_", ret$EVENT_ID[i]), ent(ret$n_presente[i]))
  poner(paste0("ret_pct_", ret$EVENT_ID[i]), pct(ret$pct[i]))
}

atr <- T("t04_atricion_predictores.csv")
atr_dolor <- atr |> filter(termino == "dolor_bl")
poner("atricion_dolor_p_min", pv2(min(atr_dolor$p)))
atr_motor_v12 <- atr |> filter(termino == "motor_bl", visita == "V12")
poner("atricion_motor_v12_or", n2(atr_motor_v12$OR[1], 3))
poner("atricion_motor_v12_p", pv2(atr_motor_v12$p[1]))

pw <- T("t04_pesos_ipcw.csv")
poner("ipcw_media_min", n2(min(pw$media), 3))
poner("ipcw_media_max", n2(max(pw$media), 3))
poner("ipcw_min", n2(min(pw$min), 2))
poner("ipcw_max", n2(max(pw$max), 2))

# ------------------------------------------------------ DIRECCIONALIDAD ------
sem <- T("t01_direccionalidad_sem.csv")
saca_sem <- function(mod, et, pref) {
  f <- sem |> filter(modelo == mod, etiqueta == et)
  poner(paste0(pref, "_est"), n2(f$estimacion[1], 3))
  poner(paste0(pref, "_ic"), ic2(f$ic_bajo[1], f$ic_alto[1], 3))
  poner(paste0(pref, "_p"), pv2(f$p[1]))
  poner(paste0(pref, "_std"), n2(f$est_std[1], 3))
}
saca_sem("CLPM clasico", "c", "clpm_dolor_motor")
saca_sem("CLPM clasico", "b", "clpm_motor_dolor")
saca_sem("RI-CLPM", "c", "riclpm_dolor_motor")
saca_sem("RI-CLPM", "b", "riclpm_motor_dolor")

ri <- T("t01_correlacion_rasgo.csv")
poner("rasgo_r", n2(ri$r[1], 3))
poner("rasgo_p", pv2(ri$p[1]))

dm_mod <- readRDS(file.path(PAPER_MOD, "direccionalidad.rds"))
poner("clpm_cfi", n2(dm_mod$clpm_fit[["cfi.robust"]], 3))
poner("clpm_rmsea", n2(dm_mod$clpm_fit[["rmsea.robust"]], 3))
poner("clpm_srmr", n2(dm_mod$clpm_fit[["srmr"]], 3))
poner("riclpm_cfi", n2(dm_mod$riclpm_fit[["cfi.robust"]], 3))
poner("riclpm_rmsea", n2(dm_mod$riclpm_fit[["rmsea.robust"]], 3))
poner("riclpm_srmr", n2(dm_mod$riclpm_fit[["srmr"]], 3))

rez <- T("t01_direccionalidad_rezagos.csv")
vent <- rez |> filter(grepl("Ventana", modelo))
poner("ventana_dolor_motor_est", n2(vent$estimacion[grepl("dolor -> motor", vent$modelo)][1], 3))
poner("ventana_dolor_motor_p", pv2(vent$p[grepl("dolor -> motor", vent$modelo)][1]))
poner("ventana_motor_dolor_p", pv2(vent$p[grepl("motor -> dolor", vent$modelo)][1]))
poner("ventana_n_dolor_motor", ent(vent$n_obs[grepl("dolor -> motor", vent$modelo)][1]))
poner("ventana_n_motor_dolor", ent(vent$n_obs[grepl("motor -> dolor", vent$modelo)][1]))

# ------------------------------------------------------------ REFUTACION -----
ref <- T("t02_refutacion_riclpm.csv")
ref_c <- ref |> filter(via == "exposicion(t-1) -> desenlace(t)")
poner("refut_n_total", ent(nrow(ref_c)))
poner("refut_n_sig", ent(sum(as.numeric(ref_c$p) < 0.05, na.rm = TRUE)))
r1 <- ref |> filter(grepl("^R1", comprobacion))
if (nrow(r1)) poner("refut_lrt_p", pv2(r1$p[1]))
r2 <- ref |> filter(grepl("^R2 rezago", comprobacion))
poner("refut_olas_sig", ent(sum(as.numeric(r2$p) < 0.05, na.rm = TRUE)))
poner("refut_olas_total", ent(nrow(r2)))
r7 <- ref_c |> filter(grepl("^R7", comprobacion))
poner("refut_moca_rasgo_r", n2(r7$r_rasgo[1], 3))
poner("refut_moca_rasgo_p", pv2(r7$p_rasgo[1]))

# ------------------------------------------------------------- FENOTIPO ------
dist <- T("t03_fenotipo_distribucion.csv")
for (v in c("BL", "V12")) {
  sub <- dist |> filter(EVENT_ID == v)
  for (f in c("TD", "PIGD", "Indeterminado")) {
    x <- sub |> filter(fenotipo == f)
    if (nrow(x)) {
      poner(sprintf("fen_%s_%s_n", tolower(f), v), ent(x$n[1]))
      poner(sprintf("fen_%s_%s_pct", tolower(f), v), pct(x$pct[1]))
    }
  }
}

est <- T("t03_fenotipo_estabilidad.csv")
poner("fen_concord_v04", pct(100 * est$concordancia[est$visita == "V04"][1]))
poner("fen_concord_v12", pct(100 * est$concordancia[est$visita == "V12"][1]))
poner("fen_kappa_v04", n2(est$kappa[est$visita == "V04"][1], 3))
poner("fen_kappa_v12", n2(est$kappa[est$visita == "V12"][1], 3))

estc <- T("t03_fenotipo_estabilidad_continua.csv")
poner("fen_spearman_v04", n2(estc$spearman[estc$visita == "V04"][1], 3))
poner("fen_spearman_v12", n2(estc$spearman[estc$visita == "V12"][1], 3))

orp <- T("t03_ordinal_dolor_fenotipo.csv")
pig <- orp |> filter(grepl("PIGD", termino))
poner("fen_or_pigd", n2(pig$OR[1], 2))
poner("fen_or_pigd_ic", ic2(pig$ic_bajo[1], pig$ic_alto[1]))
poner("fen_or_pigd_p", pv2(pig$p[1]))

mult <- T("t03_multiplicidad.csv")
prim <- mult |> filter(modelo == "UPDRS3 ~ dolor_int x fenotipo_bl")
poner("fen_interaccion_est", n2(prim$estimacion[1], 3))
poner("fen_interaccion_p", pv2(prim$p[1]))
poner("fen_contrastes_total", ent(nrow(mult)))
poner("fen_contrastes_sig", ent(sum(mult$p < 0.05)))
poner("fen_contrastes_holm", ent(sum(mult$p_holm < 0.05)))
poner("fen_contrastes_bh", ent(sum(mult$p_bh < 0.05)))

met <- T("t03_contraste_metodo.csv")
poner("fen_metodo_p3_p", pv2(met$p[met$razon == "log_ratio_p3" & met$desenlace == "UPDRS3_resto"][1]))
poner("fen_metodo_p2_p", pv2(met$p[met$razon == "log_ratio_p2" & met$desenlace == "UPDRS3_resto"][1]))

atp <- T("t03_atenuacion_pct.csv")
poner("fen_atenua_total", pct(atp$atenuacion_continuo[atp$desenlace == "motor_medio"][1]))
poner("fen_atenua_resto", pct(atp$atenuacion_continuo[atp$desenlace == "motor_resto_medio"][1]))

# ---------------------------------------------------------- LONGITUDINAL -----
mix <- T("t04_mixto.csv")
niv <- mix |> filter(termino == "dolor basal (nivel)")
pen <- mix |> filter(termino == "dolor basal x tiempo")
poner("mixto_nivel_est", n2(niv$estimacion[1], 3))
poner("mixto_nivel_ic", ic2(niv$ic_bajo[1], niv$ic_alto[1], 3))
poner("mixto_nivel_p", pv2(niv$p[1]))
poner("mixto_pendiente_est", n2(pen$estimacion[1], 3))
poner("mixto_pendiente_ic", ic2(pen$ic_bajo[1], pen$ic_alto[1], 3))
poner("mixto_pendiente_p", pv2(pen$p[1]))

mixw <- T("t04_mixto_ipcw.csv")
poner("mixto_w_nivel_est", n2(mixw$estimacion[mixw$termino == "dolor basal (nivel)"][1], 3))
poner("mixto_w_nivel_p", pv2(mixw$p[mixw$termino == "dolor basal (nivel)"][1]))
poner("mixto_w_pendiente_p", pv2(mixw$p[mixw$termino == "dolor basal x tiempo"][1]))

lord <- T("t04_lord.csv")
a <- lord |> filter(grepl("ANCOVA", especificacion))
b <- lord |> filter(grepl("cambio", especificacion))
poner("ancova_est", n2(a$estimacion[1], 3))
poner("ancova_ic", ic2(a$ic_bajo[1], a$ic_alto[1], 3))
poner("ancova_p", pv2(a$p[1]))
poner("ancova_n", ent(a$n[1]))
poner("cambio_est", n2(b$estimacion[1], 3))
poner("cambio_ic", ic2(b$ic_bajo[1], b$ic_alto[1], 3))
poner("cambio_p", pv2(b$p[1]))

hor <- T("t04_horizontes.csv")
for (v in unique(hor$visita)) {
  x <- hor |> filter(visita == v, especificacion == "crudo")
  y <- hor |> filter(visita == v, especificacion == "ponderado IPCW")
  poner(paste0("hor_", v, "_est"), n2(x$estimacion[1], 3))
  poner(paste0("hor_", v, "_p"), pv2(x$p[1]))
  poner(paste0("hor_", v, "_n"), ent(x$n[1]))
  poner(paste0("hor_", v, "_w_est"), n2(y$estimacion[1], 3))
  poner(paste0("hor_", v, "_w_p"), pv2(y$p[1]))
}

disc <- T("t04_discriminante.csv")
for (i in seq_len(nrow(disc))) {
  s <- disc$sintoma[i]
  poner(paste0("disc_", s, "_est"), n2(disc$estimacion[i], 3))
  poner(paste0("disc_", s, "_ic"), ic2(disc$ic_bajo[i], disc$ic_alto[i], 3))
  poner(paste0("disc_", s, "_p"), pv2(disc$p[i]))
  poner(paste0("disc_", s, "_bh"), pv2(disc$p_bh[i]))
  poner(paste0("disc_", s, "_holm"), pv2(disc$p_holm[i]))
}

ctrl <- T("t04_controles_negativos.csv")
poner("ctrl_moca_est", n2(ctrl$estimacion[ctrl$desenlace == "moca_v04"][1], 3))
poner("ctrl_moca_ic", ic2(ctrl$ic_bajo[ctrl$desenlace == "moca_v04"][1],
                          ctrl$ic_alto[ctrl$desenlace == "moca_v04"][1], 3))
poner("ctrl_moca_p", pv2(ctrl$p[ctrl$desenlace == "moca_v04"][1]))
poner("ctrl_gds_est", n2(ctrl$estimacion[ctrl$desenlace == "gds_v04"][1], 3))
poner("ctrl_gds_p", pv2(ctrl$p[ctrl$desenlace == "gds_v04"][1]))

ev <- T("t04_evalue.csv")
poner("evalue_puntual", n2(ev$evalue_puntual[1], 2))
poner("evalue_ic", n2(ev$evalue_ic[1], 2))

# ------------------------------------------------------------------- MSM -----
msm <- T("t05_sintesis_msm.csv")
saca_msm <- function(patron, pref) {
  f <- msm |> filter(grepl(patron, especificacion, fixed = TRUE))
  poner(paste0(pref, "_est"), n2(f$estimacion[1], 3))
  poner(paste0(pref, "_ic"), ic2(f$ic_bajo[1], f$ic_alto[1], 3))
  if (!is.na(f$p[1])) poner(paste0(pref, "_p"), pv2(f$p[1]))
}
saca_msm("SIN ajustar", "msm_crudo")
saca_msm("AJUSTANDO", "msm_ajustado")
saca_msm("modelo estructural marginal", "msm_iptw")
saca_msm("remuestreo", "msm_boot")
saca_msm("estimacion g", "msm_gcomp")

reduccion <- 100 * (1 - as.numeric(msm$estimacion[grepl("marginal", msm$especificacion)][1]) /
                      as.numeric(msm$estimacion[grepl("SIN ajustar", msm$especificacion)][1]))
poner("msm_reduccion", pct(reduccion, 0))

dl <- T("t05_dolor_a_ledd.csv")
poner("ledd_dolor_est", n2(dl$estimacion[1], 1))
poner("ledd_dolor_ic", ic2(dl$ic_bajo[1], dl$ic_alto[1], 1))
poner("ledd_dolor_p", pv2(dl$p[1]))
ld <- T("t05_ledd_a_dolor.csv")
poner("dolor_ledd_p", pv2(ld$p[1]))

bal <- T("t05_balance.csv")
poner("balance_sin", n2(bal$sin_ponderar[1], 3))
poner("balance_con", n2(bal$ponderada[1], 3))

pi <- T("t05_pesos_iptw.csv")
poner("iptw_media", n2(mean(pi$media), 3))
poner("iptw_min", n2(min(pi$min), 2))
poner("iptw_max", n2(max(pi$max), 2))

msm_mod <- readRDS(file.path(PAPER_MOD, "msm_ledd.rds"))
poner("msm_n_obs", ent(msm_mod$comparacion$n_obs[1]))
poner("msm_n_pac", ent(msm_mod$comparacion$n_pac[1]))

# --------------------------------------------------------- DENOMINADOR 0 -----
S <- read_csv(file.path(DATOS, "stebbins.csv"), show_col_types = FALSE)
v4s <- read_csv(file.path(DATOS, "tidy_v04.csv"), show_col_types = FALSE) |>
  left_join(S, by = c("PATNO", "EVENT_ID"))
poner("cero_denom_n", ent(sum(v4s$denominador_cero == 1, na.rm = TRUE)))
poner("cero_denom_pct", pct(100 * mean(v4s$denominador_cero == 1, na.rm = TRUE)))

sc <- T("t03_sensibilidad_regla_cero.csv")
poner("cero_jankovic_p", pv2(sc$p[sc$modelo == "UPDRS3 | regla: jankovic"][1]))
poner("cero_indet_p", pv2(sc$p[sc$modelo == "UPDRS3 | regla: cero_indeterminado"][1]))
poner("cero_excl_p", pv2(sc$p[sc$modelo == "UPDRS3 | regla: cero_excluido"][1]))

# ---------------------------------------------------------------- ESCRITURA --
ruta <- file.path(ROOT, "outputs", "paper", "cifras.json")
write_json(C, ruta, auto_unbox = TRUE, pretty = TRUE)
cat(sprintf("\n  %d cifras -> %s\n", length(C), ruta))

# Toda cifra debe ser una cadena ya formateada: si alguna queda como numero, el
# compositor la imprimiria con el formato por defecto de R y se colaria un
# separador decimal equivocado en el texto.
malas <- names(C)[!vapply(C, is.character, logical(1))]
if (length(malas)) stop("Cifras sin formatear: ", paste(malas, collapse = ", "))
vacias <- names(C)[vapply(C, function(x) is.na(x) || x == "" || grepl("NA", x), logical(1))]
if (length(vacias)) {
  cat("\n  AVISO, cifras con valor ausente:\n")
  for (k in vacias) cat("    ", k, " = ", C[[k]], "\n", sep = "")
}
cat("\nListo: R/paper/07_cifras.R\n")
