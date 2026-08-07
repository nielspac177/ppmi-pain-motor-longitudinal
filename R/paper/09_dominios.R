#!/usr/bin/env Rscript
# =============================================================================
# ARTICULO — Analisis 4: que dominio motor lleva la covariacion con el dolor
#
# LA HIPOTESIS. El artculo encuentra que el dolor y la severidad motora covarian
# de forma estable entre personas sin que ninguno preceda al otro. La explicacion
# mecanistica mas concreta que ofrece la literatura es que ambos son lecturas de
# un mismo estado patologico de red: el patron de descarga en salvas y las
# oscilaciones beta exageradas que producen la rigidez y la bradicinesia son
# tambien las que promueven la sensibilizacion central.
#
# Esa hipotesis hace una prediccion DIFERENCIAL dentro de la misma escala:
#
#   la covariacion con el dolor debe concentrarse en el eje RIGIDEZ-BRADICINESIA,
#   que depende de ese patron, y estar ausente o ser mucho menor en el TEMBLOR,
#   que no depende de el y que responde a un circuito cerebelo-talamo-cortical
#   distinto.
#
# Es una prediccion fuerte porque un artefacto de medida compartido, o una
# dimension inespecifica de "gravedad", afectaria a TODOS los dominios por igual.
# Si el temblor se comporta como los demas, la hipotesis de red compartida pierde
# su apoyo mas directo y gana la explicacion deflacionaria.
#
# Los cinco dominios suman exactamente la MDS-UPDRS III, comprobado en el script
# de preparacion, de modo que la descomposicion es completa y sin solapamiento.
#
# Ejecutar:  Rscript R/paper/09_dominios.R
# =============================================================================

source(file.path(Sys.getenv("TESIS_ROOT", unset = getwd()), "R", "paper", "00_comun.R"))
suppressPackageStartupMessages({
  library(sandwich); library(lmtest); library(lavaan)
})

set.seed(SEED)
titulo("ANALISIS 4 — DESCOMPOSICION POR DOMINIO MOTOR")

DOMINIOS <- c(rigidez = "dom_rigidez", bradicinesia = "dom_bradicinesia",
              axial = "dom_axial", bulbar = "dom_bulbar", temblor = "dom_temblor")

# El cargador comun no trae las subpuntuaciones: se anaden aqui.
d <- cargar_largo("off")
S <- read_csv(file.path(DATOS, "stebbins.csv"), show_col_types = FALSE) |>
  select(PATNO, EVENT_ID, all_of(unname(DOMINIOS)))
d <- d |> left_join(S, by = c("PATNO", "EVENT_ID"))

dm <- d |> filter(!is.na(UPDRS3), !is.na(NP1PAIN))
salidas <- list()

subtitulo("Comprobacion: los dominios suman la puntuacion total")
chk <- dm |>
  mutate(suma = dom_rigidez + dom_bradicinesia + dom_axial + dom_bulbar + dom_temblor,
         dif = suma - UPDRS3) |>
  summarise(n = sum(!is.na(dif)), max_dif = max(abs(dif), na.rm = TRUE))
print(chk)
stopifnot("la descomposicion por dominios no reconstruye la MDS-UPDRS III" =
            chk$max_dif < 1e-8)

# =============================================================================
# 1. COVARIACION ENTRE PERSONAS, POR DOMINIO
# =============================================================================
titulo("1. Covariacion entre personas: promedios intrapersonales")

# El componente entre personas se estima con el promedio de cada serie a lo largo
# del seguimiento. Estandarizar cada dominio hace comparables los coeficientes:
# de otro modo la bradicinesia ganaria por tener mas items y mas recorrido.
prom <- dm |>
  group_by(PATNO) |>
  summarise(across(c(dolor_int, all_of(unname(DOMINIOS)), UPDRS3),
                   ~ mean(.x, na.rm = TRUE)),
            n_visitas = n(), .groups = "drop") |>
  filter(n_visitas >= 2)

bl <- d |> filter(EVENT_ID == "BL") |>
  select(PATNO, edad_bl = age_yrs, sexo, dur_bl = disease_yrs, moca_bl = MoCA)
prom <- prom |> inner_join(bl, by = "PATNO")

cat(sprintf("\nPacientes con 2 o mas visitas: %d\n", nrow(prom)))

ajustar_dominio <- function(var, etiqueta) {
  datos <- prom |> filter(!is.na(.data[[var]]), !is.na(dolor_int), !is.na(moca_bl))
  datos$y <- as.numeric(scale(datos[[var]]))
  datos$x <- as.numeric(scale(datos$dolor_int))
  m <- lm(y ~ x + edad_bl + sexo + dur_bl + moca_bl, data = datos)
  ct <- lmtest::coeftest(m, vcov. = sandwich::vcovHC(m, type = "HC3"))
  tibble(dominio = etiqueta, n = nobs(m),
         beta_de = ct["x", 1], ee = ct["x", 2],
         ic_bajo = ct["x", 1] - 1.96 * ct["x", 2],
         ic_alto = ct["x", 1] + 1.96 * ct["x", 2],
         p = ct["x", 4])
}

entre <- imap_dfr(DOMINIOS, ~ ajustar_dominio(.x, .y)) |>
  bind_rows(ajustar_dominio("UPDRS3", "TOTAL (referencia)")) |>
  mutate(p_holm = p.adjust(p, method = "holm"))

subtitulo("Asociacion entre personas del dolor con cada dominio, en DE")
print(as.data.frame(entre), digits = 4)
salidas$entre <- entre

# =============================================================================
# 2. LA PRUEBA DIFERENCIAL: BRADICINESIA-RIGIDEZ FRENTE A TEMBLOR
# =============================================================================
titulo("2. Prueba diferencial dentro del mismo paciente y la misma escala")

# Se contrasta directamente si el coeficiente del eje rigidez-bradicinesia difiere
# del del temblor. Como los dos se miden en la misma persona y con la misma
# escala, la comparacion controla por definicion cualquier factor que actue sobre
# el instrumento completo. Se remuestrean pacientes para el intervalo de la
# diferencia, que es una funcion de dos coeficientes correlacionados.
prom2 <- prom |>
  mutate(eje_br = dom_rigidez + dom_bradicinesia) |>
  filter(!is.na(eje_br), !is.na(dom_temblor), !is.na(dolor_int), !is.na(moca_bl))

dif_obs <- local({
  z <- prom2 |> mutate(br = as.numeric(scale(eje_br)),
                       tr = as.numeric(scale(dom_temblor)),
                       x = as.numeric(scale(dolor_int)))
  b1 <- coef(lm(br ~ x + edad_bl + sexo + dur_bl + moca_bl, data = z))[["x"]]
  b2 <- coef(lm(tr ~ x + edad_bl + sexo + dur_bl + moca_bl, data = z))[["x"]]
  c(bradi_rigidez = b1, temblor = b2, diferencia = b1 - b2)
})

B <- 2000
idx <- seq_len(nrow(prom2))
boot_dif <- replicate(B, {
  s <- sample(idx, length(idx), replace = TRUE)
  z <- prom2[s, ] |> mutate(br = as.numeric(scale(eje_br)),
                            tr = as.numeric(scale(dom_temblor)),
                            x = as.numeric(scale(dolor_int)))
  b1 <- try(coef(lm(br ~ x + edad_bl + sexo + dur_bl + moca_bl, data = z))[["x"]], silent = TRUE)
  b2 <- try(coef(lm(tr ~ x + edad_bl + sexo + dur_bl + moca_bl, data = z))[["x"]], silent = TRUE)
  if (inherits(b1, "try-error") || inherits(b2, "try-error")) return(NA_real_)
  b1 - b2
})
boot_dif <- boot_dif[is.finite(boot_dif)]
ic_dif <- quantile(boot_dif, c(0.025, 0.975))
# Correccion de Davison-Hinkley: con B replicas la p no puede ser menor que
# 1/(B+1), y reportarla como cero exacto sobreestima la evidencia.
p_dif <- 2 * min((1 + sum(boot_dif <= 0)) / (length(boot_dif) + 1),
                 (1 + sum(boot_dif >= 0)) / (length(boot_dif) + 1))

cat(sprintf("\n  eje rigidez-bradicinesia : %+.4f DE por DE de dolor\n", dif_obs[["bradi_rigidez"]]))
cat(sprintf("  temblor                  : %+.4f DE por DE de dolor\n", dif_obs[["temblor"]]))
cat(sprintf("  DIFERENCIA               : %+.4f (IC 95 %%: %.4f a %.4f), p = %.4f\n",
            dif_obs[["diferencia"]], ic_dif[1], ic_dif[2], p_dif))
cat(sprintf("  replicas validas: %d de %d\n", length(boot_dif), B))

salidas$diferencial <- tibble(
  contraste = "eje rigidez-bradicinesia menos temblor",
  n = nrow(prom2),
  beta_bradi_rigidez = dif_obs[["bradi_rigidez"]],
  beta_temblor = dif_obs[["temblor"]],
  diferencia = dif_obs[["diferencia"]],
  ic_bajo = ic_dif[[1]], ic_alto = ic_dif[[2]], p = p_dif)

cat("\n  LECTURA. Si la diferencia excluye el cero, la covariacion del dolor NO\n",
    " es uniforme dentro de la escala motora: se concentra en el eje que depende\n",
    " del estado de red patologico y no en el temblor. Eso es lo que predice la\n",
    " hipotesis de sustrato compartido y lo que NO predice una dimension\n",
    " inespecifica de gravedad, que afectaria a todos los dominios por igual.\n", sep = "")

# =============================================================================
# 3. CORRELACION DE RASGO POR DOMINIO (RI-CLPM)
# =============================================================================
titulo("3. Correlacion de rasgo por dominio, con el mismo modelo del articulo")

riclpm_sintaxis <- function(n = 6) {
  ix <- seq_len(n)
  txt <- c(
    paste0("RIx =~ ", paste(paste0("1*x", ix), collapse = " + ")),
    paste0("RIy =~ ", paste(paste0("1*y", ix), collapse = " + ")),
    paste0("wx", ix, " =~ 1*x", ix), paste0("wy", ix, " =~ 1*y", ix),
    paste0("x", ix, " ~~ 0*x", ix), paste0("y", ix, " ~~ 0*y", ix))
  for (t in 2:n) {
    txt <- c(txt,
      sprintf("wx%d ~ a*wx%d + b*wy%d", t, t - 1, t - 1),
      sprintf("wy%d ~ c*wx%d + e*wy%d", t, t - 1, t - 1))
  }
  c(txt, "RIx ~~ RIy", "RIx ~~ RIx", "RIy ~~ RIy",
    "RIx ~~ 0*wx1 + 0*wy1", "RIy ~~ 0*wx1 + 0*wy1",
    paste0("wx", ix, " ~~ wy", ix)) |> paste(collapse = "\n")
}

rasgo_dominio <- function(var, etiqueta) {
  w <- dm |>
    select(PATNO, EVENT_ID, x = dolor_int, y = all_of(var)) |>
    pivot_wider(names_from = EVENT_ID, values_from = c(x, y), names_sep = "_")
  nx <- paste0("x_", VISITAS); ny <- paste0("y_", VISITAS)
  faltan <- setdiff(c(nx, ny), names(w))
  if (length(faltan)) return(NULL)
  w <- w |> select(PATNO, all_of(nx), all_of(ny))
  names(w) <- c("PATNO", paste0("x", 1:6), paste0("y", 1:6))
  fit <- try(lavaan::sem(riclpm_sintaxis(6), data = w, missing = "fiml",
                         estimator = "MLR", fixed.x = FALSE), silent = TRUE)
  if (inherits(fit, "try-error") || !lavaan::lavInspect(fit, "converged")) {
    cat(sprintf("  %-16s no converge\n", etiqueta)); return(NULL)
  }
  pe <- lavaan::parameterEstimates(fit, standardized = TRUE)
  ri <- pe[pe$lhs == "RIx" & pe$rhs == "RIy" & pe$op == "~~", ]
  fm <- lavaan::fitMeasures(fit, c("cfi.robust", "rmsea.robust"))
  tibble(dominio = etiqueta, r_rasgo = ri$std.all[1], p = ri$pvalue[1],
         cfi = fm[["cfi.robust"]], rmsea = fm[["rmsea.robust"]])
}

rasgos <- imap_dfr(DOMINIOS, ~ rasgo_dominio(.x, .y)) |>
  bind_rows(rasgo_dominio("UPDRS3", "TOTAL (referencia)"))
subtitulo("Correlacion de los interceptos aleatorios, dolor con cada dominio")
print(as.data.frame(rasgos), digits = 4)
salidas$rasgos <- rasgos

# =============================================================================
# 4. CONTROL: EL MISMO CONTRASTE PARA UN SINTOMA NO MOTOR SIN LA HIPOTESIS
# =============================================================================
titulo("4. Control: la depresion, muestra el mismo patron diferencial?")

# Si el patron diferencial fuese generico de cualquier sintoma no motor, la
# depresion deberia producirlo tambien. Si es especifico del dolor, no.
prom_gds <- dm |>
  group_by(PATNO) |>
  summarise(gds = mean(GDS, na.rm = TRUE),
            across(all_of(unname(DOMINIOS)), ~ mean(.x, na.rm = TRUE)),
            n_visitas = n(), .groups = "drop") |>
  filter(n_visitas >= 2) |>
  inner_join(bl, by = "PATNO")

ctrl <- imap_dfr(DOMINIOS, function(var, et) {
  datos <- prom_gds |> filter(!is.na(.data[[var]]), !is.na(gds), !is.na(moca_bl))
  datos$y <- as.numeric(scale(datos[[var]]))
  datos$x <- as.numeric(scale(datos$gds))
  m <- lm(y ~ x + edad_bl + sexo + dur_bl + moca_bl, data = datos)
  ct <- lmtest::coeftest(m, vcov. = sandwich::vcovHC(m, type = "HC3"))
  tibble(dominio = et, n = nobs(m), beta_de = ct["x", 1],
         ic_bajo = ct["x", 1] - 1.96 * ct["x", 2],
         ic_alto = ct["x", 1] + 1.96 * ct["x", 2], p = ct["x", 4])
})
subtitulo("Depresion (GDS-15) con cada dominio motor, entre personas")
print(as.data.frame(ctrl), digits = 4)
salidas$control_gds <- ctrl

# El MISMO contraste diferencial, con la depresion como exposicion. Si la
# disociacion del temblor no es propia del dolor, la hipotesis de red compartida
# pierde su apoyo mas directo, y hay que decirlo con el mismo estadistico y no
# con una comparacion informal de tablas.
subtitulo("Contraste diferencial con la DEPRESION como exposicion")
prom_g2 <- prom_gds |>
  mutate(eje_br = dom_rigidez + dom_bradicinesia) |>
  filter(!is.na(eje_br), !is.na(dom_temblor), !is.na(gds), !is.na(moca_bl))

dif_gds <- local({
  z <- prom_g2 |> mutate(br = as.numeric(scale(eje_br)),
                         tr = as.numeric(scale(dom_temblor)),
                         x = as.numeric(scale(gds)))
  b1 <- coef(lm(br ~ x + edad_bl + sexo + dur_bl + moca_bl, data = z))[["x"]]
  b2 <- coef(lm(tr ~ x + edad_bl + sexo + dur_bl + moca_bl, data = z))[["x"]]
  c(br = b1, tr = b2, dif = b1 - b2)
})
idx2 <- seq_len(nrow(prom_g2))
bg <- replicate(2000, {
  s2 <- prom_g2[sample(idx2, length(idx2), replace = TRUE), ] |>
    mutate(br = as.numeric(scale(eje_br)), tr = as.numeric(scale(dom_temblor)),
           x = as.numeric(scale(gds)))
  b1 <- try(coef(lm(br ~ x + edad_bl + sexo + dur_bl + moca_bl, data = s2))[["x"]], silent = TRUE)
  b2 <- try(coef(lm(tr ~ x + edad_bl + sexo + dur_bl + moca_bl, data = s2))[["x"]], silent = TRUE)
  if (inherits(b1, "try-error") || inherits(b2, "try-error")) return(NA_real_)
  b1 - b2
})
bg <- bg[is.finite(bg)]
icg <- quantile(bg, c(0.025, 0.975))
# Correccion de Davison-Hinkley: evita informar p = 0 por resolucion del remuestreo.
pg <- 2 * min((1 + sum(bg <= 0)) / (length(bg) + 1),
              (1 + sum(bg >= 0)) / (length(bg) + 1))
cat(sprintf("  depresion: eje %+.4f, temblor %+.4f, diferencia %+.4f (IC %.4f a %.4f), p = %.4f\n",
            dif_gds[["br"]], dif_gds[["tr"]], dif_gds[["dif"]], icg[1], icg[2], pg))
cat("\n  LECTURA. Si la diferencia tambien es distinta de cero para la depresion,\n",
    "  la disociacion del temblor NO es propia del dolor y el articulo no puede\n",
    "  apoyarse en ella como firma de un mecanismo especifico.\n", sep = "")
salidas$diferencial_gds <- tibble(
  exposicion = "depresion (GDS-15)", n = nrow(prom_g2),
  beta_eje = dif_gds[["br"]], beta_temblor = dif_gds[["tr"]],
  diferencia = dif_gds[["dif"]], ic_bajo = icg[[1]], ic_alto = icg[[2]], p = pg)

# =============================================================================
titulo("Guardado")
guardar_tabla(entre, "t09_dominios_entre.csv")
guardar_tabla(salidas$diferencial, "t09_dominios_diferencial.csv")
guardar_tabla(rasgos, "t09_dominios_rasgo.csv")
guardar_tabla(ctrl, "t09_dominios_control_gds.csv")
guardar_tabla(salidas$diferencial_gds, "t09_diferencial_gds.csv")
saveRDS(salidas, file.path(PAPER_MOD, "dominios.rds"))

cat("\n\nListo: R/paper/09_dominios.R\n")
