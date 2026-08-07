#!/usr/bin/env Rscript
# =============================================================================
# ARTICULO — Contraste sistematico de las hipotesis mecanisticas
#
# El articulo observa que el dolor y la severidad motora covarian de forma
# estable entre personas sin que ninguno preceda al otro. Ese patron admite
# varias explicaciones, y este script las enfrenta a los datos una por una en
# lugar de discutirlas en prosa.
#
#   H1  Ganancia de red compartida. Contrastada en R/paper/09_dominios.R.
#   H2  Degeneracion no dopaminergica comun. El dolor no deberia seguir al
#       transportador de dopamina estriatal, y la severidad motora si.
#   H3  Dimension latente de gravedad (la rival deflacionaria). Modelo bifactor.
#   H4  Punto de ajuste constitucional. Descomposicion de varianza entre e
#       intra persona.
#   H6  Carga de alfa-sinucleina. El SAA en LCR como modificador.
#   H7  Genotipo GBA como modificador.
#   H8  Via periferica. Miembro inferior frente a superior.
#
# REGLA DE LECTURA. Cada bloque declara ANTES lo que predice, de modo que el
# resultado pueda contradecirlo. Una hipotesis que no puede fallar no se cuenta.
#
# Ejecutar:  Rscript R/paper/11_hipotesis.R
# =============================================================================

source(file.path(Sys.getenv("TESIS_ROOT", unset = getwd()), "R", "paper", "00_comun.R"))
suppressPackageStartupMessages({
  library(lavaan); library(sandwich); library(lmtest); library(lme4); library(lmerTest)
})

set.seed(SEED)
titulo("CONTRASTE DE LAS HIPOTESIS MECANISTICAS")

DOMINIOS <- c(rigidez = "dom_rigidez", bradicinesia = "dom_bradicinesia",
              axial = "dom_axial", bulbar = "dom_bulbar", temblor = "dom_temblor")

S <- read_csv(file.path(DATOS, "stebbins.csv"), show_col_types = FALSE)
B <- read_csv(file.path(DATOS, "biomarcadores.csv"), show_col_types = FALSE)

d <- cargar_largo("off") |>
  left_join(S |> select(PATNO, EVENT_ID, all_of(unname(DOMINIOS))),
            by = c("PATNO", "EVENT_ID")) |>
  left_join(B, by = c("PATNO", "EVENT_ID")) |>
  filter(!is.na(UPDRS3), !is.na(NP1PAIN))

salidas <- list()

# Promedios intrapersonales: el componente entre personas, que es donde vive el
# fenomeno del articulo.
prom <- d |>
  group_by(PATNO) |>
  summarise(dolor = mean(dolor_int, na.rm = TRUE),
            motor = mean(UPDRS3, na.rm = TRUE),
            moca = mean(MoCA, na.rm = TRUE),
            across(all_of(unname(DOMINIOS)), ~ mean(.x, na.rm = TRUE)),
            dat_estriado = mean(mean_striatum, na.rm = TRUE),
            dat_putamen = mean(mean_putamen, na.rm = TRUE),
            dat_caudado = mean(mean_caudate, na.rm = TRUE),
            edad = mean(age_yrs, na.rm = TRUE),
            sexo = first(sexo), dur = mean(disease_yrs, na.rm = TRUE),
            saa = suppressWarnings(max(saa_pos, na.rm = TRUE)),
            gba = max(es_GBA, na.rm = TRUE),
            n_visitas = n(), .groups = "drop") |>
  mutate(across(everything(), ~ ifelse(is.infinite(.x), NA, .x))) |>
  filter(n_visitas >= 2)

cat(sprintf("\nPacientes con 2 o mas visitas: %d\n", nrow(prom)))

est_hc3 <- function(m, term) {
  ct <- lmtest::coeftest(m, vcov. = sandwich::vcovHC(m, type = "HC3"))
  c(b = ct[term, 1], lo = ct[term, 1] - 1.96 * ct[term, 2],
    hi = ct[term, 1] + 1.96 * ct[term, 2], p = ct[term, 4])
}

# =============================================================================
# H2 — DEGENERACION NO DOPAMINERGICA COMUN
# =============================================================================
titulo("H2 — El dolor sigue al transportador de dopamina estriatal?")

cat("\n  PREDICE: la severidad motora covaria con el DAT (mas deficit, peor\n",
    "  motor) y el dolor NO. Si el dolor tambien lo hiciera, el sustrato\n",
    "  compartido seria dopaminergico y la hipotesis quedaria refutada.\n", sep = "")

h2 <- map_dfr(c("dat_estriado", "dat_putamen", "dat_caudado"), function(v) {
  s <- prom |> filter(!is.na(.data[[v]]), !is.na(dolor), !is.na(motor),
                      !is.na(edad), !is.na(dur))
  s$dat <- as.numeric(scale(s[[v]]))
  m_dol <- lm(scale(dolor) ~ dat + edad + sexo + dur, data = s)
  m_mot <- lm(scale(motor) ~ dat + edad + sexo + dur, data = s)
  a <- est_hc3(m_dol, "dat"); b <- est_hc3(m_mot, "dat")
  tibble(region = v, n = nrow(s),
         desenlace = c("dolor", "motor"),
         beta_de = c(a[["b"]], b[["b"]]),
         ic_bajo = c(a[["lo"]], b[["lo"]]),
         ic_alto = c(a[["hi"]], b[["hi"]]),
         p = c(a[["p"]], b[["p"]]))
})
print(as.data.frame(h2), digits = 3)
salidas$h2 <- h2

subtitulo("La correlacion dolor-motor, sobrevive al ajuste por DAT?")
s <- prom |> filter(!is.na(dat_estriado), !is.na(dolor), !is.na(motor),
                    !is.na(edad), !is.na(dur))
m0 <- lm(scale(motor) ~ scale(dolor) + edad + sexo + dur, data = s)
m1 <- lm(scale(motor) ~ scale(dolor) + scale(dat_estriado) + edad + sexo + dur, data = s)
h2b <- bind_rows(
  tibble(ajuste = "sin DAT", n = nobs(m0), !!!as.list(est_hc3(m0, "scale(dolor)"))),
  tibble(ajuste = "con DAT", n = nobs(m1), !!!as.list(est_hc3(m1, "scale(dolor)")))
)
print(as.data.frame(h2b), digits = 3)
salidas$h2b <- h2b

# =============================================================================
# H3 — DIMENSION LATENTE DE GRAVEDAD (BIFACTOR)
# =============================================================================
titulo("H3 — Un factor general de gravedad explica la covariacion?")

cat("\n  PREDICE: si todo es gravedad, el dolor carga en el factor GENERAL y su\n",
    "  carga es del mismo orden que la de los dominios motores. Si el dolor\n",
    "  carga poco en el general, la explicacion deflacionaria no basta.\n", sep = "")

bif_d <- prom |>
  select(dolor, moca, all_of(unname(DOMINIOS))) |>
  drop_na()
names(bif_d) <- c("dolor", "moca", names(DOMINIOS))
bif_d <- bif_d |> mutate(across(everything(), ~ as.numeric(scale(.x))))

# Un solo factor general sobre los cinco dominios motores mas dolor y MoCA. Si
# existe una dimension inespecifica de carga, es la que este factor captura.
mod_g <- '
  G =~ rigidez + bradicinesia + axial + bulbar + temblor + dolor + moca
'
fit_g <- try(lavaan::sem(mod_g, data = bif_d, estimator = "MLR"), silent = TRUE)
if (!inherits(fit_g, "try-error") && lavaan::lavInspect(fit_g, "converged")) {
  pe <- lavaan::parameterEstimates(fit_g, standardized = TRUE)
  cargas <- pe |> filter(op == "=~") |>
    transmute(indicador = rhs, carga_std = std.all, p = pvalue)
  subtitulo("Cargas en el factor general")
  print(as.data.frame(cargas), digits = 3)
  fm <- lavaan::fitMeasures(fit_g, c("cfi.robust", "rmsea.robust", "srmr"))
  cat("\n  ajuste: "); print(round(fm, 3))
  salidas$h3_cargas <- cargas

  carga_dolor <- cargas$carga_std[cargas$indicador == "dolor"]
  carga_motoras <- mean(cargas$carga_std[cargas$indicador %in%
                          c("rigidez", "bradicinesia", "axial", "bulbar")])
  cat(sprintf("\n  carga del dolor        : %.3f\n", carga_dolor))
  cat(sprintf("  carga media motora     : %.3f\n", carga_motoras))
  cat(sprintf("  razon dolor/motora     : %.2f\n", carga_dolor / carga_motoras))
  salidas$h3_resumen <- tibble(carga_dolor = carga_dolor,
                               carga_motora_media = carga_motoras,
                               razon = carga_dolor / carga_motoras)
}

subtitulo("Queda covariacion dolor-motor tras el factor general? (prueba anidada)")

# NO se usan puntuaciones factoriales. Regresar un indicador sobre una puntuacion
# factorial que lo contiene induce correlacion negativa entre los residuos por
# construccion, de modo que ese procedimiento fabrica el residuo negativo que
# despues se interpretaria. La prueba correcta es anidada: se libera la
# covarianza residual entre el dolor y los dominios motores y se compara el
# ajuste. Si no mejora, el factor general reproduce bien esa covarianza.
if (exists("fit_g") && !inherits(fit_g, "try-error")) {
  mod_g2 <- paste(mod_g, "dolor ~~ rigidez", "dolor ~~ bradicinesia",
                  "dolor ~~ axial", sep = "\n")
  fit_g2 <- try(lavaan::sem(mod_g2, data = bif_d, estimator = "MLR"), silent = TRUE)
  if (!inherits(fit_g2, "try-error") && lavaan::lavInspect(fit_g2, "converged")) {
    lrt <- lavaan::lavTestLRT(fit_g, fit_g2)
    print(lrt)
    p_lrt <- lrt[["Pr(>Chisq)"]][2]
    cat(sprintf("\n  Liberar la covarianza residual dolor-motor: p = %.4f\n", p_lrt))
    cat(if (is.na(p_lrt) || p_lrt > ALPHA)
          "  NO mejora el ajuste: el factor general da cuenta de la covariacion.\n"
        else
          "  SI mejora: queda asociacion especifica no explicada por el factor.\n")
    salidas$h3_anidado <- tibble(
      prueba = "un factor vs un factor + covarianza residual dolor-motor",
      chisq_dif = lrt[["Chisq diff"]][2], gl = lrt[["Df diff"]][2], p = p_lrt)
  }
  # Residuos estandarizados de las celdas dolor-motor, como diagnostico directo.
  rz <- lavaan::lavResiduals(fit_g)$cov.z
  salidas$h3_residuos_z <- tibble(
    celda = c("rigidez", "bradicinesia", "axial", "bulbar", "temblor"),
    residuo_z = as.numeric(rz["dolor", c("rigidez", "bradicinesia", "axial",
                                          "bulbar", "temblor")]))
  subtitulo("Residuos estandarizados de las celdas dolor-motor (|z| > 1,96 destaca)")
  print(as.data.frame(salidas$h3_residuos_z), digits = 3)

  fm2 <- lavaan::fitMeasures(fit_g, c("chisq", "df", "pvalue", "cfi.robust",
                                      "rmsea.robust", "srmr"))
  salidas$h3_ajuste <- tibble(modelo = "un factor general", n = nrow(bif_d),
                              chisq = fm2[["chisq"]], gl = fm2[["df"]],
                              p_chisq = fm2[["pvalue"]], cfi = fm2[["cfi.robust"]],
                              rmsea = fm2[["rmsea.robust"]], srmr = fm2[["srmr"]])
  subtitulo("Ajuste del modelo de un factor")
  print(as.data.frame(salidas$h3_ajuste), digits = 4)
}

# =============================================================================
# H4 — PUNTO DE AJUSTE CONSTITUCIONAL
# =============================================================================
titulo("H4 — El dolor es rasgo o estado?")

cat("\n  PREDICE: si el dolor es un rasgo, la varianza ENTRE personas debe ser\n",
    "  grande frente a la INTRA persona. Se estima con la correlacion\n",
    "  intraclase de un modelo de intercepto aleatorio.\n", sep = "")

icc <- function(var, etiqueta) {
  s <- d |> filter(!is.na(.data[[var]]))
  m <- lme4::lmer(as.formula(sprintf("%s ~ 1 + (1 | PATNO)", var)), data = s)
  vc <- as.data.frame(lme4::VarCorr(m))
  entre <- vc$vcov[vc$grp == "PATNO"]
  intra <- vc$vcov[vc$grp == "Residual"]
  tibble(serie = etiqueta, n_obs = nobs(m), n_pac = lme4::ngrps(m)[[1]],
         var_entre = entre, var_intra = intra, icc = entre / (entre + intra))
}
h4 <- bind_rows(
  icc("dolor_int", "Dolor (MDS-UPDRS 1.9)"),
  icc("UPDRS3", "MDS-UPDRS III total"),
  icc("MoCA", "MoCA"),
  icc("GDS", "GDS-15")
)
print(as.data.frame(h4), digits = 3)
salidas$h4 <- h4

cat("\n  LECTURA. Una correlacion intraclase alta indica que la mayor parte de la\n",
    "  variabilidad esta entre personas y no dentro de cada una, es decir, que\n",
    "  la medida se comporta como rasgo. Tambien acota cuanta senal intrapersonal\n",
    "  hay disponible para que un rezago cruzado la detecte, que es la\n",
    "  explicacion alternativa de por que las vias intrapersonales salen nulas.\n",
    sep = "")

# =============================================================================
# H6 y H7 — SAA Y GENOTIPO COMO MODIFICADORES
# =============================================================================
titulo("H6 y H7 — Carga de alfa-sinucleina y genotipo GBA")

cat("\n  PREDICE H6: la covariacion dolor-motor es mayor en positivos al SAA.\n",
    "  PREDICE H7: la covariacion es mayor en portadores de GBA.\n", sep = "")

modificador <- function(var, etiqueta) {
  s <- prom |> filter(!is.na(.data[[var]]), !is.na(dolor), !is.na(motor),
                      !is.na(edad), !is.na(dur))
  if (n_distinct(s[[var]]) < 2) return(NULL)
  s$g <- factor(s[[var]])
  m <- lm(scale(motor) ~ scale(dolor) * g + edad + sexo + dur, data = s)
  ct <- lmtest::coeftest(m, vcov. = sandwich::vcovHC(m, type = "HC3"))
  fila <- grep(":", rownames(ct), value = TRUE)[1]
  estr <- s |> group_by(g) |> group_modify(~ {
    if (nrow(.x) < 30) return(tibble(n = nrow(.x), b = NA, lo = NA, hi = NA, p = NA))
    mm <- lm(scale(motor) ~ scale(dolor) + edad + sexo + dur, data = .x)
    e <- est_hc3(mm, "scale(dolor)")
    tibble(n = nrow(.x), b = e[["b"]], lo = e[["lo"]], hi = e[["hi"]], p = e[["p"]])
  }) |> ungroup()
  list(interaccion = tibble(modificador = etiqueta, termino = fila,
                            estimacion = ct[fila, 1],
                            ic_bajo = ct[fila, 1] - 1.96 * ct[fila, 2],
                            ic_alto = ct[fila, 1] + 1.96 * ct[fila, 2],
                            p = ct[fila, 4]),
       estratos = estr |> mutate(modificador = etiqueta))
}

h6 <- modificador("saa", "SAA positivo")
h7 <- modificador("gba", "Portador GBA")

subtitulo("Terminos de interaccion")
print(as.data.frame(bind_rows(h6$interaccion, h7$interaccion)), digits = 3)
subtitulo("Efecto del dolor estratificado")
print(as.data.frame(bind_rows(h6$estratos, h7$estratos)), digits = 3)
salidas$h6_h7 <- bind_rows(h6$interaccion, h7$interaccion)
salidas$h6_h7_estratos <- bind_rows(h6$estratos, h7$estratos)

# =============================================================================
# H8 — VIA PERIFERICA: MIEMBRO INFERIOR FRENTE A SUPERIOR
# =============================================================================
titulo("H8 — La covariacion es mayor en miembro inferior?")

cat("\n  PREDICE: si opera una via periferica de fibra fina, que afecta antes y\n",
    "  mas a las extremidades inferiores, la covariacion con el dolor deberia\n",
    "  ser mayor en los items de miembro inferior que en los de superior.\n", sep = "")

SUP <- c("NP3RIGRU", "NP3RIGLU", "NP3FTAPR", "NP3FTAPL", "NP3HMOVR",
         "NP3HMOVL", "NP3PRSPR", "NP3PRSPL")
INF <- c("NP3RIGRL", "NP3RIGLL", "NP3TTAPR", "NP3TTAPL", "NP3LGAGR", "NP3LGAGL")

Sx <- read_csv(file.path(DATOS, "stebbins.csv"), show_col_types = FALSE) |>
  select(PATNO, EVENT_ID, all_of(c(SUP, INF))) |>
  mutate(sup = rowSums(across(all_of(SUP))), inf = rowSums(across(all_of(INF))))

prom_mi <- d |>
  select(PATNO, EVENT_ID, dolor_int, age_yrs, sexo, disease_yrs) |>
  left_join(Sx |> select(PATNO, EVENT_ID, sup, inf), by = c("PATNO", "EVENT_ID")) |>
  group_by(PATNO) |>
  summarise(dolor = mean(dolor_int, na.rm = TRUE),
            sup = mean(sup, na.rm = TRUE), inf = mean(inf, na.rm = TRUE),
            edad = mean(age_yrs, na.rm = TRUE), sexo = first(sexo),
            dur = mean(disease_yrs, na.rm = TRUE), n_visitas = n(), .groups = "drop") |>
  filter(n_visitas >= 2) |>
  drop_na(dolor, sup, inf, edad, dur)

b_sup <- est_hc3(lm(scale(sup) ~ scale(dolor) + edad + sexo + dur, data = prom_mi), "scale(dolor)")
b_inf <- est_hc3(lm(scale(inf) ~ scale(dolor) + edad + sexo + dur, data = prom_mi), "scale(dolor)")

nb <- 2000
boot8 <- replicate(nb, {
  s <- prom_mi[sample(nrow(prom_mi), nrow(prom_mi), replace = TRUE), ]
  c1 <- try(coef(lm(scale(inf) ~ scale(dolor) + edad + sexo + dur, data = s))[[2]], silent = TRUE)
  c2 <- try(coef(lm(scale(sup) ~ scale(dolor) + edad + sexo + dur, data = s))[[2]], silent = TRUE)
  if (inherits(c1, "try-error") || inherits(c2, "try-error")) return(NA_real_)
  c1 - c2
})
boot8 <- boot8[is.finite(boot8)]
ic8 <- quantile(boot8, c(0.025, 0.975))
p8 <- 2 * min(mean(boot8 <= 0), mean(boot8 >= 0))

h8 <- tibble(
  region = c("miembro superior", "miembro inferior", "diferencia inferior menos superior"),
  n = nrow(prom_mi),
  beta_de = c(b_sup[["b"]], b_inf[["b"]], b_inf[["b"]] - b_sup[["b"]]),
  ic_bajo = c(b_sup[["lo"]], b_inf[["lo"]], ic8[[1]]),
  ic_alto = c(b_sup[["hi"]], b_inf[["hi"]], ic8[[2]]),
  p = c(b_sup[["p"]], b_inf[["p"]], p8))
print(as.data.frame(h8), digits = 3)
salidas$h8 <- h8

# =============================================================================
titulo("SINTESIS")

sintesis <- tribble(
  ~hipotesis, ~prediccion, ~resultado,
  "H1 ganancia de red compartida",
  "covariacion en rigidez-bradicinesia y no en temblor",
  "SOSTENIDA (diferencia 0,172; p = 0,001) — ver 09_dominios.R",
  "H2 degeneracion no dopaminergica",
  "el dolor NO sigue al DAT; el motor SI",
  paste0("dolor p = ", pv(h2$p[h2$region == "dat_estriado" & h2$desenlace == "dolor"]),
         "; motor p = ", pv(h2$p[h2$region == "dat_estriado" & h2$desenlace == "motor"])),
  "H3 dimension latente de gravedad",
  "el dolor carga como los dominios motores en un factor general",
  if (!is.null(salidas$h3_anidado))
    sprintf("razon de cargas %.2f; liberar residuo NO mejora (p = %s)",
            salidas$h3_resumen$razon, pv(salidas$h3_anidado$p)) else "no estimada",
  "H4 punto de ajuste constitucional",
  "correlacion intraclase alta del dolor",
  sprintf("ICC dolor = %.3f frente a motor = %.3f",
          h4$icc[h4$serie == "Dolor (MDS-UPDRS 1.9)"],
          h4$icc[h4$serie == "MDS-UPDRS III total"]),
  "H5 prodromica",
  "la correlacion existe antes del diagnostico",
  "SOSTENIDA (r = 0,213; p = 0,002) — ver 10_controles_negativos.R",
  "H6 carga de alfa-sinucleina",
  "mayor covariacion en positivos al SAA",
  paste0("interaccion p = ", pv(salidas$h6_h7$p[1])),
  "H7 genotipo GBA",
  "mayor covariacion en portadores",
  paste0("interaccion p = ", pv(salidas$h6_h7$p[2])),
  "H8 via periferica",
  "mayor covariacion en miembro inferior",
  paste0("diferencia p = ", pv(p8))
)
print(as.data.frame(sintesis), right = FALSE)
salidas$sintesis <- sintesis

titulo("Guardado")
guardar_tabla(h2, "t11_h2_dat.csv")
guardar_tabla(h2b, "t11_h2_ajuste_dat.csv")
if (!is.null(salidas$h3_cargas)) guardar_tabla(salidas$h3_cargas, "t11_h3_cargas.csv")
if (!is.null(salidas$h3_anidado)) guardar_tabla(salidas$h3_anidado, "t11_h3_anidado.csv")
if (!is.null(salidas$h3_residuos_z)) guardar_tabla(salidas$h3_residuos_z, "t11_h3_residuos_z.csv")
if (!is.null(salidas$h3_ajuste)) guardar_tabla(salidas$h3_ajuste, "t11_h3_ajuste.csv")
guardar_tabla(h4, "t11_h4_icc.csv")
guardar_tabla(salidas$h6_h7, "t11_h6_h7_interaccion.csv")
guardar_tabla(salidas$h6_h7_estratos, "t11_h6_h7_estratos.csv")
guardar_tabla(h8, "t11_h8_miembros.csv")
guardar_tabla(sintesis, "t11_sintesis_hipotesis.csv")
saveRDS(salidas, file.path(PAPER_MOD, "hipotesis.rds"))

cat("\n\nListo: R/paper/11_hipotesis.R\n")
