#!/usr/bin/env Rscript
# =============================================================================
# ARTICULO — Analisis 5: controles negativos de cohorte
#
# LA OBJECION QUE SE RESPONDE AQUI. El articulo sostiene que el dolor y la
# severidad motora covarian de forma estable porque comparten sustrato. La
# lectura rival, y es fuerte, es que la covariacion refleja un factor
# inespecifico de "carga" mas varianza de metodo compartida, sin necesidad de
# ninguna neurobiologia comun. Esa lectura predice las seis observaciones del
# articulo igual de bien.
#
# Hay una prueba que las separa: refitear el MISMO modelo en personas SIN la
# enfermedad. Si la correlacion de rasgo aparece tambien alli, la lectura
# deflacionaria gana y la interpretacion de sustrato compartido se cae.
#
# Se anade la cohorte prodromica, que responde a la objecion que el diseno
# principal no puede contestar: que el dolor si preceda a la enfermedad motora,
# pero antes de que se abra la ventana de observacion.
#
#   controles   COHORT == 2, sin enfermedad
#   prodromo    COHORT == 4, hiposmia y trastorno de conducta del sueno REM
#   Parkinson   la muestra del articulo, como referencia
#
# ADVERTENCIA SOBRE EL RECORRIDO. En controles la MDS-UPDRS III tiene media 1,7
# y desviacion 3,1, frente a 26,0 y 11,2 en la cohorte de Parkinson. Una
# correlacion atenuada en controles puede deberse a restriccion del recorrido y
# no a ausencia de mecanismo, de modo que el contraste se acompana de la
# comparacion explicita de varianzas. Esto acota lo que la prueba puede concluir.
#
# Ejecutar:  Rscript R/paper/10_controles_negativos.R
# =============================================================================

source(file.path(Sys.getenv("TESIS_ROOT", unset = getwd()), "R", "paper", "00_comun.R"))
suppressPackageStartupMessages({ library(lavaan) })

set.seed(SEED)
titulo("ANALISIS 5 — CONTROLES NEGATIVOS DE COHORTE")

salidas <- list()

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

cargar_cohorte <- function(archivo) {
  read_csv(file.path(DATOS, archivo), show_col_types = FALSE) |>
    filter(EVENT_ID %in% VISITAS, !is.na(NP1PAIN), !is.na(UPDRS3)) |>
    mutate(dolor_int = as.numeric(NP1PAIN))
}

ajustar_cohorte <- function(d, etiqueta) {
  w <- d |>
    select(PATNO, EVENT_ID, x = dolor_int, y = UPDRS3) |>
    pivot_wider(names_from = EVENT_ID, values_from = c(x, y), names_sep = "_")
  nx <- paste0("x_", VISITAS); ny <- paste0("y_", VISITAS)
  faltan <- setdiff(c(nx, ny), names(w))
  if (length(faltan)) {
    cat(sprintf("  %-24s faltan olas: %s\n", etiqueta, paste(faltan, collapse = ", ")))
    return(NULL)
  }
  w <- w |> select(PATNO, all_of(nx), all_of(ny))
  names(w) <- c("PATNO", paste0("x", 1:6), paste0("y", 1:6))

  fit <- try(lavaan::sem(riclpm_sintaxis(6), data = w, missing = "fiml",
                         estimator = "MLR", fixed.x = FALSE), silent = TRUE)
  if (inherits(fit, "try-error") || !lavaan::lavInspect(fit, "converged")) {
    cat(sprintf("  %-24s NO converge\n", etiqueta))
    return(NULL)
  }
  pe <- lavaan::parameterEstimates(fit, standardized = TRUE)
  ri <- pe[pe$lhs == "RIx" & pe$rhs == "RIy" & pe$op == "~~", ]
  cc <- pe[pe$label == "c" & pe$op == "~", ][1, ]
  bb <- pe[pe$label == "b" & pe$op == "~", ][1, ]
  fm <- lavaan::fitMeasures(fit, c("cfi.robust", "rmsea.robust", "srmr"))

  tibble(
    cohorte = etiqueta,
    n_pacientes = nrow(w),
    n_obs = nrow(d),
    media_motor = mean(d$UPDRS3, na.rm = TRUE),
    de_motor = sd(d$UPDRS3, na.rm = TRUE),
    media_dolor = mean(d$dolor_int, na.rm = TRUE),
    de_dolor = sd(d$dolor_int, na.rm = TRUE),
    r_rasgo = ri$std.all[1], ee_rasgo = ri$se[1], p_rasgo = ri$pvalue[1],
    cruzado_dolor_motor_p = cc$pvalue, cruzado_motor_dolor_p = bb$pvalue,
    cfi = fm[["cfi.robust"]], rmsea = fm[["rmsea.robust"]], srmr = fm[["srmr"]])
}

# =============================================================================
titulo("1. El mismo modelo en las tres cohortes")

pd <- cargar_largo("off") |> filter(!is.na(UPDRS3), !is.na(NP1PAIN))
ctrl <- cargar_cohorte("tidy_long_controles.csv")
prod <- cargar_cohorte("tidy_long_prodromo.csv")

comparacion <- bind_rows(
  ajustar_cohorte(pd, "Parkinson (articulo)"),
  ajustar_cohorte(prod, "Prodromica"),
  ajustar_cohorte(ctrl, "Controles sanos")
)

subtitulo("Recorrido de las dos series en cada cohorte")
print(as.data.frame(comparacion |>
  select(cohorte, n_pacientes, n_obs, media_motor, de_motor, media_dolor, de_dolor)),
  digits = 3)

subtitulo("Correlacion de rasgo y rezagos cruzados")
print(as.data.frame(comparacion |>
  select(cohorte, r_rasgo, ee_rasgo, p_rasgo,
         cruzado_dolor_motor_p, cruzado_motor_dolor_p, cfi, rmsea)), digits = 3)

salidas$comparacion <- comparacion

# =============================================================================
titulo("2. Lectura")

r_pd <- comparacion$r_rasgo[comparacion$cohorte == "Parkinson (articulo)"]
r_ct <- comparacion$r_rasgo[comparacion$cohorte == "Controles sanos"]
p_ct <- comparacion$p_rasgo[comparacion$cohorte == "Controles sanos"]
r_pr <- comparacion$r_rasgo[comparacion$cohorte == "Prodromica"]
p_pr <- comparacion$p_rasgo[comparacion$cohorte == "Prodromica"]

cat(sprintf("\n  Parkinson   r = %+.3f (p = %.4f)\n", r_pd,
            comparacion$p_rasgo[comparacion$cohorte == "Parkinson (articulo)"]))
cat(sprintf("  Prodromica  r = %+.3f (p = %.4f)\n", r_pr, p_pr))
cat(sprintf("  Controles   r = %+.3f (p = %.4f)\n", r_ct, p_ct))

# La conclusion NO puede leerse de los valores p. Los tres tamanos muestrales son
# muy distintos (1 174, 1 744 y 307), de modo que una p mayor en controles puede
# ser falta de potencia y no ausencia de correlacion. Confundir "no significativo"
# con "equivalente" es un error que este proyecto ya cometio una vez. Lo que
# decide es la MAGNITUD y su comparacion formal.
n_pd <- comparacion$n_pacientes[comparacion$cohorte == "Parkinson (articulo)"]
n_ct <- comparacion$n_pacientes[comparacion$cohorte == "Controles sanos"]
n_pr <- comparacion$n_pacientes[comparacion$cohorte == "Prodromica"]

fisher_z <- function(r1, n1, r2, n2, et) {
  z1 <- atanh(r1); z2 <- atanh(r2)
  se <- sqrt(1 / (n1 - 3) + 1 / (n2 - 3))
  z <- (z1 - z2) / se
  tibble(contraste = et, r1 = r1, r2 = r2, diferencia = r1 - r2,
         ic_bajo = tanh((z1 - z2) - 1.96 * se), ic_alto = tanh((z1 - z2) + 1.96 * se),
         z = z, p = 2 * pnorm(-abs(z)))
}

# La z de Fisher NO es valida aqui: su error estandar es el de una correlacion de
# Pearson entre dos variables OBSERVADAS sobre n pares completos independientes,
# mientras que r_rasgo es una covarianza estandarizada entre dos interceptos
# LATENTES, estimada por maxima verosimilitud con informacion completa sobre un
# panel con hasta un 80 % de ausencia en las ultimas olas. Comparando el error
# estandar de Wald implicito en cada p con el de Fisher se ve que este ultimo
# subestima por un factor de unas 2,4 veces.
#
# La prueba correcta es un SEM MULTIGRUPO con la covarianza de los interceptos
# restringida a ser igual entre cohortes, contrastada por razon de
# verosimilitudes escalada. Se hace abajo; la z de Fisher se conserva solo para
# documentar cuanto se habria estrechado el intervalo con el metodo equivocado.
subtitulo("Comparacion formal de las correlaciones entre cohortes (Fisher z, INCORRECTA)")
comp_r <- bind_rows(
  fisher_z(r_pd, n_pd, r_ct, n_ct, "Parkinson vs controles sanos"),
  fisher_z(r_pd, n_pd, r_pr, n_pr, "Parkinson vs prodromica"),
  fisher_z(r_pr, n_pr, r_ct, n_ct, "Prodromica vs controles sanos")
)
print(as.data.frame(comp_r), digits = 3)
salidas$comparacion_r <- comp_r

cat("\n  LECTURA HONESTA.\n")

# No basta con que las p sean mayores que alfa: hay que mirar QUE excluye el
# intervalo de la diferencia. Con 307 controles la comparacion tiene poca
# potencia, y un contraste no significativo con un intervalo ancho no es
# evidencia de equivalencia. Es la misma distincion que la tesis tuvo que hacer
# con su prueba de equivalencia.
pdvc <- comp_r |> filter(contraste == "Parkinson vs controles sanos")
ancho <- pdvc$ic_alto[1] - pdvc$ic_bajo[1]

cat(sprintf("  Parkinson menos controles: %+.3f (IC 95 %%: %.3f a %.3f)\n",
            pdvc$diferencia[1], pdvc$ic_bajo[1], pdvc$ic_alto[1]))

if (all(comp_r$p > ALPHA) && ancho > 0.15) {
  cat("\n  El contraste es NO CONCLUYENTE, no una demostracion de equivalencia.\n",
      "  El intervalo de la diferencia es demasiado ancho: es compatible tanto\n",
      "  con que los controles no tengan ninguna correlacion como con que la\n",
      "  tengan mayor que los pacientes. Con 307 controles no da para mas.\n",
      "\n  Lo que si puede decirse: la estimacion puntual en controles (",
      sprintf("%.3f", r_ct), ")\n",
      "  es NUMERICAMENTE similar a la de Parkinson (", sprintf("%.3f", r_pd), "), y eso\n",
      "  NO es lo que predice una lectura de sustrato especifico de la\n",
      "  enfermedad. El articulo no puede afirmar especificidad apoyandose en\n",
      "  esta prueba, y debe reportarla con su intervalo.\n", sep = "")
} else if (all(comp_r$p > ALPHA)) {
  cat("  Las tres correlaciones son indistinguibles y el intervalo es estrecho:\n",
      "  eso si apoya la lectura deflacionaria.\n", sep = "")
} else {
  cat("  Al menos una comparacion alcanza significacion; ver la tabla.\n", sep = "")
}

cat("\n  Lo que este contraste NO decide. En controles la desviacion de la\n",
    "  MDS-UPDRS III es de ",
    sprintf("%.2f", comparacion$de_motor[comparacion$cohorte == "Controles sanos"]),
    " frente a ",
    sprintf("%.2f", comparacion$de_motor[comparacion$cohorte == "Parkinson (articulo)"]),
    " en Parkinson. La restriccion\n",
    "  del recorrido atenua las correlaciones observadas, de modo que una\n",
    "  correlacion IGUAL en controles pese a un recorrido cuatro veces menor es,\n",
    "  si acaso, evidencia mas fuerte a favor de la lectura deflacionaria y no\n",
    "  mas debil.\n", sep = "")

# =============================================================================
# =============================================================================
titulo("2b. La prueba correcta: SEM multigrupo con restriccion de igualdad")

grupos <- bind_rows(
  pd   |> select(PATNO, EVENT_ID, dolor_int, UPDRS3) |> mutate(cohorte = "Parkinson"),
  prod |> select(PATNO, EVENT_ID, dolor_int, UPDRS3) |> mutate(cohorte = "Prodromica"),
  ctrl |> select(PATNO, EVENT_ID, dolor_int, UPDRS3) |> mutate(cohorte = "Controles")
) |>
  # Los identificadores se rehacen por cohorte: PATNO es unico en PPMI, pero si
  # una misma persona apareciera en dos marcos la union crearia filas duplicadas.
  mutate(id = paste(cohorte, PATNO, sep = "_"))

w_mg <- grupos |>
  select(id, cohorte, EVENT_ID, x = dolor_int, y = UPDRS3) |>
  pivot_wider(names_from = EVENT_ID, values_from = c(x, y), names_sep = "_")
nx <- paste0("x_", VISITAS); ny <- paste0("y_", VISITAS)
w_mg <- w_mg |> select(id, cohorte, all_of(nx), all_of(ny))
names(w_mg) <- c("id", "cohorte", paste0("x", 1:6), paste0("y", 1:6))

cat("\nPacientes por cohorte en el modelo multigrupo:\n")
print(table(w_mg$cohorte))

# Restringir la COVARIANZA cruda entre grupos seria un contraste espurio: las
# varianzas difieren enormemente entre cohortes (DE motora 11,6 en Parkinson
# frente a 3,1 en controles), de modo que el modelo se rechazaria por la
# diferencia de escala y no por la de asociacion. Lo que hay que contrastar es la
# CORRELACION, que es una funcion de tres parametros. Se etiquetan por grupo, se
# define la correlacion de cada uno con := y se contrasta su igualdad con una
# prueba de Wald sobre los parametros derivados.
# En lavaan multigrupo una etiqueta ESCALAR se replica entre grupos, es decir,
# impone igualdad. La sintaxis compartida usa etiquetas escalares para los
# rezagos (a, b, c, e), de modo que reutilizarla aqui forzaria la misma dinamica
# intrapersonal en pacientes, prodromicos y controles. Eso es sustantivamente
# implausible, porque los controles apenas tienen variacion motora intrapersonal,
# y ademas desplaza la correlacion de rasgo que es el parametro de interes.
# Se reescribe con etiquetas VECTORIALES para que cada grupo tenga la suya.
riclpm_multigrupo <- function(n = 6) {
  ix <- seq_len(n)
  txt <- c(
    paste0("RIx =~ ", paste(paste0("1*x", ix), collapse = " + ")),
    paste0("RIy =~ ", paste(paste0("1*y", ix), collapse = " + ")),
    paste0("wx", ix, " =~ 1*x", ix), paste0("wy", ix, " =~ 1*y", ix),
    paste0("x", ix, " ~~ 0*x", ix), paste0("y", ix, " ~~ 0*y", ix))
  for (t in 2:n) {
    txt <- c(txt,
      sprintf("wx%d ~ c(a1,a2,a3)*wx%d + c(b1,b2,b3)*wy%d", t, t - 1, t - 1),
      sprintf("wy%d ~ c(c1,c2,c3)*wx%d + c(e1,e2,e3)*wy%d", t, t - 1, t - 1))
  }
  paste(c(txt, "RIx ~~ 0*wx1 + 0*wy1", "RIy ~~ 0*wx1 + 0*wy1",
          paste0("wx", ix, " ~~ wy", ix)), collapse = "\n")
}

sint_mg <- paste(
  riclpm_multigrupo(6),
  "RIx ~~ c(cxy1, cxy2, cxy3)*RIy",
  "RIx ~~ c(vx1, vx2, vx3)*RIx",
  "RIy ~~ c(vy1, vy2, vy3)*RIy",
  "rho1 := cxy1 / sqrt(vx1 * vy1)",
  "rho2 := cxy2 / sqrt(vx2 * vy2)",
  "rho3 := cxy3 / sqrt(vx3 * vy3)",
  "d12 := rho1 - rho2",
  "d13 := rho1 - rho3",
  sep = "\n")

mg <- try(lavaan::sem(sint_mg, data = w_mg, group = "cohorte",
                      missing = "fiml", estimator = "MLR", fixed.x = FALSE),
          silent = TRUE)

if (!inherits(mg, "try-error") && lavaan::lavInspect(mg, "converged")) {
  pe_mg <- lavaan::parameterEstimates(mg)
  grupos_orden <- lavaan::lavInspect(mg, "group.label")
  rho <- pe_mg |> filter(op == ":=", grepl("^rho", lhs)) |>
    transmute(cohorte = grupos_orden[as.integer(sub("rho", "", lhs))],
              r = est, ee = se, ic_bajo = ci.lower, ic_alto = ci.upper, p = pvalue)
  subtitulo("Correlacion de rasgo por cohorte, con su error estandar CORRECTO")
  print(as.data.frame(rho), digits = 3)

  dif <- pe_mg |> filter(op == ":=", grepl("^d1", lhs)) |>
    transmute(contraste = ifelse(lhs == "d12",
                                 paste(grupos_orden[1], "menos", grupos_orden[2]),
                                 paste(grupos_orden[1], "menos", grupos_orden[3])),
              diferencia = est, ee = se, ic_bajo = ci.lower, ic_alto = ci.upper,
              p = pvalue)
  subtitulo("Diferencias entre cohortes (delta, con error estandar del modelo)")
  print(as.data.frame(dif), digits = 3)

  wald <- lavaan::lavTestWald(mg, constraints = "rho1 == rho2\nrho1 == rho3")
  cat(sprintf("\n  Prueba de Wald conjunta de igualdad de las tres correlaciones:\n"))
  cat(sprintf("    chi2 = %.3f, gl = %d, p = %.4f\n", wald$stat, wald$df, wald$p.value))
  cat(if (wald$p.value > ALPHA)
        "  NO se rechaza la igualdad. Las tres cohortes son compatibles con la\n  MISMA correlacion de rasgo, de modo que el articulo no puede afirmar que\n  la covariacion sea propia de la enfermedad.\n"
      else
        "  SE rechaza la igualdad: la correlacion difiere entre cohortes.\n")

  salidas$multigrupo_rho <- rho
  salidas$multigrupo_dif <- dif
  salidas$multigrupo_wald <- tibble(
    prueba = "Wald, igualdad de la correlacion de rasgo entre las tres cohortes",
    chisq = wald$stat, gl = wald$df, p = wald$p.value)
  guardar_tabla(rho, "t10_multigrupo_rho.csv")
  guardar_tabla(dif, "t10_multigrupo_dif.csv")
  guardar_tabla(salidas$multigrupo_wald, "t10_multigrupo_wald.csv")
} else {
  cat("\n  El modelo multigrupo no converge; se reporta solo la comparacion aproximada.\n")
}

# =============================================================================
titulo("3. Gradiente: la correlacion sigue al grado de enfermedad?")

# Si el mecanismo es propio de la enfermedad, la correlacion deberia ordenarse
# Parkinson > prodromica > controles. Si fuese un factor generico de carga,
# no deberia haber gradiente.
grad <- comparacion |>
  select(cohorte, de_motor, r_rasgo, p_rasgo) |>
  arrange(desc(de_motor))
print(as.data.frame(grad), digits = 3)
salidas$gradiente <- grad

titulo("Guardado")
guardar_tabla(comparacion, "t10_controles_negativos.csv")
saveRDS(salidas, file.path(PAPER_MOD, "controles_negativos.rds"))

cat("\n\nListo: R/paper/10_controles_negativos.R\n")

# =============================================================================
titulo("4. El patron por dominio, es especifico de la enfermedad?")

# La covariacion global resulto no ser propia de la enfermedad. Queda una
# pregunta mas fina y potencialmente decisiva: el PATRON entre dominios si lo es?
# El analisis 4 mostro que en Parkinson el dolor covaria con rigidez,
# bradicinesia y axial pero NO con temblor. Un factor inespecifico de carga o de
# estilo de respuesta no tiene por que respetar esa estructura, de modo que si el
# patron diferencial aparece solo en la enfermedad, algo especifico queda en pie
# aunque la correlacion global no lo sea.
DOMINIOS <- c(rigidez = "dom_rigidez", bradicinesia = "dom_bradicinesia",
              axial = "dom_axial", bulbar = "dom_bulbar", temblor = "dom_temblor")

S <- read_csv(file.path(DATOS, "stebbins.csv"), show_col_types = FALSE) |>
  select(PATNO, EVENT_ID, all_of(unname(DOMINIOS)))

perfil_dominios <- function(d, etiqueta) {
  z <- d |>
    left_join(S, by = c("PATNO", "EVENT_ID")) |>
    group_by(PATNO) |>
    summarise(dolor = mean(dolor_int, na.rm = TRUE),
              across(all_of(unname(DOMINIOS)), ~ mean(.x, na.rm = TRUE)),
              edad = mean(age_yrs, na.rm = TRUE),
              sexo = first(sex_male),
              n_visitas = n(), .groups = "drop") |>
    filter(n_visitas >= 2)
  imap_dfr(DOMINIOS, function(v, nm) {
    s <- z |> filter(!is.na(.data[[v]]), !is.na(dolor), !is.na(edad))
    if (nrow(s) < 40 || sd(s[[v]], na.rm = TRUE) == 0) {
      return(tibble(cohorte = etiqueta, dominio = nm, n = nrow(s),
                    beta_de = NA_real_, ic_bajo = NA_real_, ic_alto = NA_real_,
                    p = NA_real_))
    }
    s$y <- as.numeric(scale(s[[v]])); s$x <- as.numeric(scale(s$dolor))
    m <- lm(y ~ x + edad + sexo, data = s)
    ct <- lmtest::coeftest(m, vcov. = sandwich::vcovHC(m, type = "HC3"))
    tibble(cohorte = etiqueta, dominio = nm, n = nobs(m),
           beta_de = ct["x", 1],
           ic_bajo = ct["x", 1] - 1.96 * ct["x", 2],
           ic_alto = ct["x", 1] + 1.96 * ct["x", 2], p = ct["x", 4])
  })
}

suppressPackageStartupMessages({ library(sandwich); library(lmtest) })
perfiles <- bind_rows(
  perfil_dominios(pd, "Parkinson"),
  perfil_dominios(prod, "Prodromica"),
  perfil_dominios(ctrl, "Controles sanos")
)
subtitulo("Asociacion del dolor con cada dominio motor, por cohorte (en DE)")
print(as.data.frame(perfiles |>
  select(cohorte, dominio, n, beta_de, ic_bajo, ic_alto, p)), digits = 3)
salidas$perfiles <- perfiles

subtitulo("El temblor, sigue siendo el unico dominio nulo en cada cohorte?")
resumen <- perfiles |>
  group_by(cohorte) |>
  summarise(
    beta_temblor = beta_de[dominio == "temblor"],
    p_temblor = p[dominio == "temblor"],
    beta_medio_resto = mean(beta_de[dominio != "temblor"], na.rm = TRUE),
    n_resto_sig = sum(p[dominio != "temblor"] < ALPHA, na.rm = TRUE),
    .groups = "drop")
print(as.data.frame(resumen), digits = 3)
salidas$resumen_dominios <- resumen

guardar_tabla(perfiles, "t10_perfiles_dominio_cohorte.csv")
guardar_tabla(comp_r, "t10_comparacion_correlaciones.csv")
saveRDS(salidas, file.path(PAPER_MOD, "controles_negativos.rds"))
