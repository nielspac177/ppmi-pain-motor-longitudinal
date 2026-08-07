#!/usr/bin/env Rscript
# =============================================================================
# ARTICULO — Analisis clinicos pendientes
#
# Cuatro contrastes que la revision por pares senalo como esperables y que no
# estaban hechos. Cada uno responde a una objecion concreta:
#
#   1  ANALGESICOS. Se miden porque la revision los pidio, PERO no son un
#      confusor: el analgesico se toma A CAUSA del dolor, de modo que es un
#      DESCENDIENTE de la exposicion. Condicionar sobre el hace dos cosas malas
#      a la vez: bloquea la parte del efecto que pasa por el tratamiento
#      (mediacion) y abre un camino de colision Dolor -> Analgesico <- U ->
#      Motor, donde U es cualquier comorbilidad dolorosa que tambien empeore el
#      desempeno motor. La atenuacion resultante NO puede leerse como "esta
#      fraccion era confusion". Se reporta como comprobacion descriptiva: si la
#      asociacion se hubiera anulado, habria sido informativo; no se anula.
#   2  SEXO. El dolor en la EP es mas frecuente e intenso en mujeres, y en esta
#      misma cohorte la carga no motora se asocia con el sexo femenino. Es la
#      interaccion con mejor previo y no estaba contrastada.
#   3  PARTE IV. El articulo advierte que el recuerdo semanal del item de dolor
#      abarca periodos on y off en pacientes con fluctuaciones. La Parte IV mide
#      exactamente eso y convierte un caveat enunciado en uno contrastado.
#   4  OTROS ITEMS DE LA PARTE I. Si la covariacion no es propia del dolor sino
#      de una dimension general de carga, otros sintomas no motores del mismo
#      cuestionario deberian dar una correlacion de rasgo parecida.
#
# Ejecutar:  Rscript R/paper/14_clinicos.R
# =============================================================================

source(file.path(Sys.getenv("TESIS_ROOT", unset = getwd()), "R", "paper", "00_comun.R"))
suppressPackageStartupMessages({
  library(sandwich); library(lmtest); library(lavaan); library(geepack)
})

set.seed(SEED)
titulo("ANALISIS CLINICOS PENDIENTES")

A <- read_csv(file.path(DATOS, "analgesicos.csv"), show_col_types = FALSE)
d <- cargar_largo("off") |>
  left_join(A, by = c("PATNO", "EVENT_ID")) |>
  filter(!is.na(UPDRS3), !is.na(NP1PAIN))
salidas <- list()

est_hc3 <- function(m, term) {
  ct <- lmtest::coeftest(m, vcov. = sandwich::vcovHC(m, type = "HC3"))
  c(b = ct[term, 1], lo = ct[term, 1] - 1.96 * ct[term, 2],
    hi = ct[term, 1] + 1.96 * ct[term, 2], p = ct[term, 4])
}

prom <- d |>
  group_by(PATNO) |>
  summarise(dolor = mean(dolor_int, na.rm = TRUE),
            motor = mean(UPDRS3, na.rm = TRUE),
            analg = max(analgesico_sin_aspirina, na.rm = TRUE),
            analg_todo = max(cualquier_analgesico, na.rm = TRUE),
            opioide = max(opioide, na.rm = TRUE),
            edad = mean(age_yrs, na.rm = TRUE), sexo = first(sexo),
            dur = mean(disease_yrs, na.rm = TRUE), moca = mean(MoCA, na.rm = TRUE),
            n_visitas = n(), .groups = "drop") |>
  # ifelse() descarta atributos, de modo que aplicarlo a todas las columnas
  # convertia el factor `sexo` en sus codigos enteros y la tabla exportada perdia
  # las etiquetas. Se restringe a las columnas numericas.
  mutate(across(where(is.numeric), ~ ifelse(is.infinite(.x), NA, .x))) |>
  filter(n_visitas >= 2)

# Prevalencia de exposicion a analgesicos, que el manuscrito necesita citar.
prev_analg <- tibble(
  medida = c("alguna vez sin aspirina", "alguna vez cualquiera", "alguna vez opioide"),
  proporcion = c(mean(prom$analg, na.rm = TRUE),
                 mean(prom$analg_todo, na.rm = TRUE),
                 mean(prom$opioide, na.rm = TRUE)),
  n = nrow(prom))
subtitulo("Prevalencia de exposicion a analgesicos en la muestra analitica")
print(as.data.frame(prev_analg), digits = 3)

# =============================================================================
titulo("1. Ajuste por analgesicos")

cat("\n  ADVERTENCIA DE INTERPRETACION. El analgesico es consecuencia del dolor,\n",
    "  no causa comun de dolor y motor. Ajustar por el atenua la estimacion\n",
    "  HAYA O NO confusion, porque bloquea una via que pasa por el tratamiento,\n",
    "  y ademas puede sesgar en cualquier direccion por colision con una\n",
    "  comorbilidad dolorosa no medida. La estimacion ajustada es una COTA\n",
    "  INFERIOR, no una estimacion descontaminada.\n", sep = "")

s1 <- prom |> drop_na(dolor, motor, edad, dur, moca, analg)
mods <- list(
  "sin ajuste" = lm(scale(motor) ~ scale(dolor) + edad + sexo + dur + moca, data = s1),
  "+ analgesico (sin aspirina)" = lm(scale(motor) ~ scale(dolor) + analg + edad + sexo + dur + moca, data = s1),
  "+ analgesico (cualquiera)" = lm(scale(motor) ~ scale(dolor) + analg_todo + edad + sexo + dur + moca, data = s1),
  "+ opioide" = lm(scale(motor) ~ scale(dolor) + opioide + edad + sexo + dur + moca, data = s1))
h1 <- imap_dfr(mods, function(m, nm) {
  e <- est_hc3(m, "scale(dolor)")
  tibble(ajuste = nm, n = nobs(m), beta_de = e[["b"]],
         ic_bajo = e[["lo"]], ic_alto = e[["hi"]], p = e[["p"]])
})
print(as.data.frame(h1), digits = 3)
at <- 100 * (1 - h1$beta_de[2] / h1$beta_de[1])
cat(sprintf("\n  Atenuacion al ajustar por analgesico (sin aspirina): %.1f %%\n", at))
salidas$analgesicos <- h1

# Este modelo NO adjunta el dolor, de modo que su coeficiente recoge en buena
# parte la propia asociacion dolor-motor expresada a traves de su descendiente.
# No puede citarse como evidencia independiente de que el analgesico afecte al
# desempeno motor. Se conserva solo como descriptivo.
m_a <- lm(scale(motor) ~ analg + edad + sexo + dur + moca, data = s1)
ea <- est_hc3(m_a, "analg")
cat(sprintf("  Analgesico -> motor: %+.3f DE (IC %.3f a %.3f), p = %.4f\n",
            ea[["b"]], ea[["lo"]], ea[["hi"]], ea[["p"]]))
salidas$analg_motor <- tibble(termino = "analgesico -> motor", n = nobs(m_a),
                              beta_de = ea[["b"]], ic_bajo = ea[["lo"]],
                              ic_alto = ea[["hi"]], p = ea[["p"]])

# =============================================================================
titulo("2. Interaccion por sexo")

cat("\n  PREDICE: si la relacion difiere por sexo, el termino de interaccion\n",
    "  entre el dolor y el sexo sobre la severidad motora sera distinto de cero.\n", sep = "")

s2 <- prom |> drop_na(dolor, motor, edad, dur, moca, sexo)
m2 <- lm(scale(motor) ~ scale(dolor) * sexo + edad + dur + moca, data = s2)
ct2 <- lmtest::coeftest(m2, vcov. = sandwich::vcovHC(m2, type = "HC3"))
fila <- grep(":", rownames(ct2), value = TRUE)[1]
h2 <- tibble(termino = fila, n = nobs(m2), estimacion = ct2[fila, 1],
             ic_bajo = ct2[fila, 1] - 1.96 * ct2[fila, 2],
             ic_alto = ct2[fila, 1] + 1.96 * ct2[fila, 2], p = ct2[fila, 4])
print(as.data.frame(h2), digits = 3)

estr <- s2 |> group_by(sexo) |> group_modify(~ {
  m <- lm(scale(motor) ~ scale(dolor) + edad + dur + moca, data = .x)
  e <- est_hc3(m, "scale(dolor)")
  tibble(n = nrow(.x), beta_de = e[["b"]], ic_bajo = e[["lo"]],
         ic_alto = e[["hi"]], p = e[["p"]])
}) |> ungroup()
subtitulo("Estratificado por sexo")
print(as.data.frame(estr), digits = 3)
salidas$sexo <- h2; salidas$sexo_estratos <- estr

# =============================================================================
titulo("3. Complicaciones motoras (MDS-UPDRS Parte IV)")

cat("\n  PREDICE el caveat: si el recuerdo semanal del item de dolor esta\n",
    "  contaminado por las fluctuaciones, la asociacion deberia cambiar al\n",
    "  ajustar por la Parte IV, o diferir entre quienes tienen complicaciones\n",
    "  motoras y quienes no.\n", sep = "")

cur <- read_csv(file.path(Sys.getenv("PPMI_RAW_DIR", unset = DATOS),
                          "PPMI_Curated_Data_Cut_Public_20241211.csv"),
                show_col_types = FALSE,
                col_select = any_of(c("PATNO", "EVENT_ID", "updrs4_score")))
d4 <- d |> left_join(cur, by = c("PATNO", "EVENT_ID")) |>
  mutate(updrs4 = as.numeric(updrs4_score))

prom4 <- d4 |>
  group_by(PATNO) |>
  summarise(dolor = mean(dolor_int, na.rm = TRUE), motor = mean(UPDRS3, na.rm = TRUE),
            p4 = mean(updrs4, na.rm = TRUE), edad = mean(age_yrs, na.rm = TRUE),
            sexo = first(sexo), dur = mean(disease_yrs, na.rm = TRUE),
            moca = mean(MoCA, na.rm = TRUE), n_visitas = n(), .groups = "drop") |>
  mutate(across(everything(), ~ ifelse(is.infinite(.x), NA, .x))) |>
  filter(n_visitas >= 2)

cat(sprintf("\n  Pacientes con Parte IV: %d de %d\n",
            sum(!is.na(prom4$p4)), nrow(prom4)))
if (sum(!is.na(prom4$p4)) >= 100) {
  s3 <- prom4 |> drop_na(dolor, motor, p4, edad, dur, moca)
  m3a <- lm(scale(motor) ~ scale(dolor) + edad + sexo + dur + moca, data = s3)
  m3b <- lm(scale(motor) ~ scale(dolor) + p4 + edad + sexo + dur + moca, data = s3)
  h3 <- bind_rows(
    tibble(ajuste = "sin Parte IV", n = nobs(m3a), !!!as.list(est_hc3(m3a, "scale(dolor)"))),
    tibble(ajuste = "+ Parte IV", n = nobs(m3b), !!!as.list(est_hc3(m3b, "scale(dolor)"))))
  print(as.data.frame(h3), digits = 3)
  salidas$parte4 <- h3

  s3 <- s3 |> mutate(fluct = factor(as.integer(p4 > 0), levels = c(0, 1),
                                    labels = c("sin complicaciones", "con complicaciones")))
  e4 <- s3 |> group_by(fluct) |> group_modify(~ {
    if (nrow(.x) < 40) return(tibble(n = nrow(.x), b = NA, lo = NA, hi = NA, p = NA))
    m <- lm(scale(motor) ~ scale(dolor) + edad + sexo + dur + moca, data = .x)
    e <- est_hc3(m, "scale(dolor)")
    tibble(n = nrow(.x), b = e[["b"]], lo = e[["lo"]], hi = e[["hi"]], p = e[["p"]])
  }) |> ungroup()
  subtitulo("Estratificado por presencia de complicaciones motoras")
  print(as.data.frame(e4), digits = 3)
  salidas$parte4_estratos <- e4
}

# =============================================================================
titulo("4. Otros sintomas de la Parte I como exposiciones paralelas")

cat("\n  PREDICE la explicacion de carga general: si el fenomeno no es propio del\n",
    "  dolor, otros items del MISMO cuestionario deberian dar una correlacion de\n",
    "  rasgo del mismo orden. Si el dolor destaca, algo especifico queda en pie.\n",
    sep = "")

riclpm <- function(n = 6) {
  ix <- seq_len(n)
  t <- c(paste0("RIx =~ ", paste(paste0("1*x", ix), collapse = " + ")),
         paste0("RIy =~ ", paste(paste0("1*y", ix), collapse = " + ")),
         paste0("wx", ix, " =~ 1*x", ix), paste0("wy", ix, " =~ 1*y", ix),
         paste0("x", ix, " ~~ 0*x", ix), paste0("y", ix, " ~~ 0*y", ix))
  for (k in 2:n) t <- c(t, sprintf("wx%d ~ a*wx%d + b*wy%d", k, k - 1, k - 1),
                           sprintf("wy%d ~ c*wx%d + e*wy%d", k, k - 1, k - 1))
  paste(c(t, "RIx ~~ RIy", "RIx ~~ RIx", "RIy ~~ RIy",
          "RIx ~~ 0*wx1 + 0*wy1", "RIy ~~ 0*wx1 + 0*wy1",
          paste0("wx", ix, " ~~ wy", ix)), collapse = "\n")
}

ITEMS <- c(dolor = "NP1PAIN", fatiga = "NP1FATG",
           insomnio = "NP1SLPN", somnolencia = "NP1SLPD")

paralelos <- imap_dfr(ITEMS, function(v, nm) {
  w <- d |> select(PATNO, EVENT_ID, x = all_of(v), y = UPDRS3) |>
    pivot_wider(names_from = EVENT_ID, values_from = c(x, y), names_sep = "_")
  nx <- paste0("x_", VISITAS); ny <- paste0("y_", VISITAS)
  if (length(setdiff(c(nx, ny), names(w)))) return(NULL)
  w <- w |> select(PATNO, all_of(nx), all_of(ny))
  names(w) <- c("PATNO", paste0("x", 1:6), paste0("y", 1:6))
  f <- try(lavaan::sem(riclpm(6), data = w, missing = "fiml",
                       estimator = "MLR", fixed.x = FALSE), silent = TRUE)
  if (inherits(f, "try-error") || !lavaan::lavInspect(f, "converged")) {
    cat(sprintf("  %-14s no converge\n", nm)); return(NULL)
  }
  pe <- lavaan::parameterEstimates(f, standardized = TRUE)
  ri <- pe[pe$lhs == "RIx" & pe$rhs == "RIy" & pe$op == "~~", ]
  cc <- pe[pe$label == "c" & pe$op == "~", ][1, ]
  bb <- pe[pe$label == "b" & pe$op == "~", ][1, ]
  tibble(sintoma = nm, r_rasgo = ri$std.all[1], p_rasgo = ri$pvalue[1],
         p_sintoma_a_motor = cc$pvalue, p_motor_a_sintoma = bb$pvalue)
})
print(as.data.frame(paralelos), digits = 3)
salidas$paralelos <- paralelos

if (nrow(paralelos) > 1) {
  rd <- paralelos$r_rasgo[paralelos$sintoma == "dolor"]
  otros <- paralelos$r_rasgo[paralelos$sintoma != "dolor"]
  cat(sprintf("\n  Dolor r = %.3f; otros sintomas de la Parte I: %s\n",
              rd, paste(sprintf("%.3f", otros), collapse = ", ")))
  cat(if (rd > max(otros) * 1.5)
        "  El dolor DESTACA sobre los demas: queda algo especifico por explicar.\n"
      else
        "  El dolor NO destaca: la covariacion es del orden de la de otros\n  sintomas no motores, lo que apoya la lectura de carga general.\n")
}

titulo("Guardado")
guardar_tabla(prev_analg, "t14_prevalencia_analgesicos.csv")
guardar_tabla(h1, "t14_analgesicos.csv")
guardar_tabla(salidas$analg_motor, "t14_analgesico_motor.csv")
guardar_tabla(h2, "t14_sexo_interaccion.csv")
guardar_tabla(estr, "t14_sexo_estratos.csv")
if (!is.null(salidas$parte4)) guardar_tabla(salidas$parte4, "t14_parte4.csv")
if (!is.null(salidas$parte4_estratos)) guardar_tabla(salidas$parte4_estratos, "t14_parte4_estratos.csv")
guardar_tabla(paralelos, "t14_paralelos_parte1.csv")
saveRDS(salidas, file.path(PAPER_MOD, "clinicos.rds"))

cat("\n\nListo: R/paper/14_clinicos.R\n")
