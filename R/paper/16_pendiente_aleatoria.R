#!/usr/bin/env Rscript
# =============================================================================
# ARTICULO — El supuesto de pendiente fija del RI-CLPM
#
# LA OBJECION. El modelo de panel cruzado con interceptos aleatorios descompone
# cada serie en un NIVEL propio y estable de la persona, mas desviaciones
# respecto de ese nivel. En una enfermedad que progresa, esa descomposicion es
# incompleta: si las personas difieren no solo en su nivel sino en su VELOCIDAD,
# la variacion entre personas en la pendiente no tiene donde ir y termina dentro
# de las desviaciones "intrapersonales". Entonces esas desviaciones ya no son
# desviaciones respecto de un nivel estable, sino respecto de un nivel mas una
# deriva individual no modelada, y los rezagos cruzados que se estiman sobre
# ellas no significan lo que el articulo dice que significan.
#
# En esta cohorte el motor progresa 2,29 puntos al ano, de modo que la objecion
# no es teorica.
#
# EL REMEDIO ESTANDAR es un modelo de curva latente con residuos estructurados
# (Curran y colaboradores): se anade a cada constructo una PENDIENTE latente
# ademas del intercepto, con cargas fijadas al tiempo, y los rezagos cruzados
# pasan a estimarse sobre las desviaciones respecto de la trayectoria individual.
#
# LAS PREDICCIONES, declaradas antes de mirar:
#   Si el supuesto de pendiente fija estaba distorsionando los resultados, las
#   vias cruzadas y la correlacion de rasgo deben cambiar de forma apreciable.
#   Si no cambian, el supuesto era inocuo aqui y el articulo puede decirlo con
#   una cifra en lugar de con un argumento.
#
# Ejecutar:  Rscript R/paper/16_pendiente_aleatoria.R
# =============================================================================

source(file.path(Sys.getenv("TESIS_ROOT", unset = getwd()), "R", "paper", "00_comun.R"))
suppressPackageStartupMessages({ library(lavaan) })

set.seed(SEED)
titulo("PENDIENTE ALEATORIA: CURVA LATENTE CON RESIDUOS ESTRUCTURADOS")

d <- cargar_largo("off") |> filter(!is.na(UPDRS3) | !is.na(NP1PAIN))
salidas <- list()

ancho <- d |>
  select(PATNO, EVENT_ID, dolor_int, UPDRS3) |>
  pivot_wider(names_from = EVENT_ID, values_from = c(dolor_int, UPDRS3),
              names_sep = "_") |>
  select(PATNO, all_of(paste0("dolor_int_", VISITAS)),
         all_of(paste0("UPDRS3_", VISITAS)))
names(ancho) <- c("PATNO", paste0("d", 1:6), paste0("m", 1:6))

cat(sprintf("\nPacientes en el panel: %d\n", nrow(ancho)))

# ---------------------------------------------------------------------------
# Modelo 1: RI-CLPM, solo intercepto aleatorio. Es el del articulo.
# Modelo 2: curva latente con residuos estructurados, intercepto MAS pendiente.
#
# Las cargas de la pendiente son el horizonte nominal en anios. Se usa el nominal
# y no el tiempo real porque el modelo es de ocasiones fijas: las visitas se
# separan un ano con desviaciones de semanas, comprobado en el analisis 0.
#
# EL CENTRADO DE LAS CARGAS NO ES COSMETICO. Con cargas 0 a 5 el intercepto
# latente deja de ser el nivel medio de la persona y pasa a ser su nivel BASAL,
# porque es el punto donde la pendiente vale cero. La correlacion entre
# interceptos ya no responde entonces a la misma pregunta que el RI-CLPM: pasa a
# ser la correlacion de los niveles iniciales. Con cargas centradas en -2,5 a 2,5
# el intercepto es el nivel a mitad del seguimiento, que es la cantidad
# comparable. Se ajustan las dos parametrizaciones porque el contraste entre
# ellas es informativo, pero solo la centrada responde a la pregunta del
# articulo. Es el mismo error de centrado que ya se corrigio una vez en el
# modelo mixto, donde el efecto de "nivel" resulto ser la seccion transversal
# basal (ADR 0010).
# ---------------------------------------------------------------------------
sintaxis <- function(con_pendiente, centrado = TRUE) {
  ix <- 1:6
  cargas <- if (centrado) (ix - 1) - mean(ix - 1) else ix - 1
  t <- c(
    paste0("RId =~ ", paste(paste0("1*d", ix), collapse = " + ")),
    paste0("RIm =~ ", paste(paste0("1*m", ix), collapse = " + ")))
  if (con_pendiente) {
    t <- c(t,
      paste0("Sd =~ ", paste(sprintf("%s*d%d", cargas, ix), collapse = " + ")),
      paste0("Sm =~ ", paste(sprintf("%s*m%d", cargas, ix), collapse = " + ")))
  }
  t <- c(t,
    paste0("wd", ix, " =~ 1*d", ix), paste0("wm", ix, " =~ 1*m", ix),
    paste0("d", ix, " ~~ 0*d", ix), paste0("m", ix, " ~~ 0*m", ix))
  for (k in 2:6) {
    t <- c(t, sprintf("wd%d ~ a*wd%d + b*wm%d", k, k - 1, k - 1),
              sprintf("wm%d ~ c*wd%d + e*wm%d", k, k - 1, k - 1))
  }
  latentes <- if (con_pendiente) c("RId", "RIm", "Sd", "Sm") else c("RId", "RIm")
  # Las latentes covarian libremente entre si y son ortogonales a la primera ola
  # intrapersonal, que es lo que identifica la descomposicion.
  cov_lat <- character(0)
  for (i in seq_along(latentes)) {
    for (j in seq(i, length(latentes))) {
      cov_lat <- c(cov_lat, sprintf("%s ~~ %s", latentes[i], latentes[j]))
    }
  }
  orto <- sprintf("%s ~~ 0*wd1 + 0*wm1", latentes)
  paste(c(t, cov_lat, orto, paste0("wd", ix, " ~~ wm", ix)), collapse = "\n")
}

ajustar <- function(con_pendiente, etiqueta, centrado = TRUE) {
  fit <- try(lavaan::sem(sintaxis(con_pendiente, centrado), data = ancho,
                         missing = "fiml", estimator = "MLR", fixed.x = FALSE),
             silent = TRUE)
  if (inherits(fit, "try-error")) {
    cat(sprintf("  %-46s ERROR: %s\n", etiqueta,
                sub("\n.*", "", conditionMessage(attr(fit, "condition")))))
    return(NULL)
  }
  if (!lavaan::lavInspect(fit, "converged")) {
    cat(sprintf("  %-46s NO CONVERGE\n", etiqueta)); return(NULL)
  }
  # Una solucion impropia invalida la lectura aunque el ajuste sea mejor.
  pe <- lavaan::parameterEstimates(fit)
  vneg <- pe[pe$op == "~~" & pe$lhs == pe$rhs & pe$est < 0, ]
  cat(sprintf("  %-46s OK%s\n", etiqueta,
              if (nrow(vneg)) sprintf("  [%d varianza(s) negativa(s): %s]",
                                      nrow(vneg), paste(vneg$lhs, collapse = ", "))
              else ""))
  attr(fit, "impropia") <- nrow(vneg) > 0
  fit
}

subtitulo("Ajuste de los modelos")
fit_ri <- ajustar(FALSE, "RI-CLPM (el del articulo)")
fit_sr <- ajustar(TRUE,  "Curva latente, cargas centradas (comparable)")
fit_s0 <- ajustar(TRUE,  "Curva latente, cargas 0 a 5 (intercepto = basal)",
                  centrado = FALSE)

resumir <- function(fit, etiqueta) {
  if (is.null(fit)) return(NULL)
  pe <- lavaan::parameterEstimates(fit, standardized = TRUE)
  fm <- lavaan::fitMeasures(fit, c("cfi.robust", "rmsea.robust", "srmr", "aic", "bic"))
  ri <- pe[pe$lhs == "RId" & pe$rhs == "RIm" & pe$op == "~~", ]
  saca <- function(lab) {
    f <- pe[pe$label == lab & pe$op == "~", ]
    if (!nrow(f)) return(c(NA, NA)); c(f$est[1], f$pvalue[1])
  }
  cc <- saca("c"); bb <- saca("b")
  tibble(modelo = etiqueta,
         r_rasgo = ri$std.all[1], p_rasgo = ri$pvalue[1],
         dolor_motor = cc[1], p_dolor_motor = cc[2],
         motor_dolor = bb[1], p_motor_dolor = bb[2],
         cfi = fm[["cfi.robust"]], rmsea = fm[["rmsea.robust"]],
         srmr = fm[["srmr"]], aic = fm[["aic"]], bic = fm[["bic"]])
}

comp <- bind_rows(
  resumir(fit_ri, "RI-CLPM (solo intercepto)"),
  resumir(fit_sr, "Curva latente, cargas centradas"),
  resumir(fit_s0, "Curva latente, cargas 0 a 5"))
subtitulo("Los dos modelos, lado a lado")
print(as.data.frame(comp), digits = 4)
salidas$comparacion <- comp

if (!is.null(fit_ri) && !is.null(fit_sr)) {
  subtitulo("Comparacion formal de ajuste")
  lrt <- lavaan::lavTestLRT(fit_ri, fit_sr)
  print(lrt)
  p_lrt <- lrt[["Pr(>Chisq)"]][2]
  salidas$lrt <- tibble(prueba = "RI-CLPM frente a curva latente con residuos",
                        chisq_dif = lrt[["Chisq diff"]][2],
                        gl = lrt[["Df diff"]][2], p = p_lrt)
  cat(sprintf("\n  Anadir las pendientes latentes: p = %.4g\n", p_lrt))

  # La varianza de la pendiente es la cantidad que decide si el supuesto de
  # pendiente fija era violado: si es cero, no habia nada que modelar.
  pe_sr <- lavaan::parameterEstimates(fit_sr, standardized = TRUE)
  vs <- pe_sr[pe_sr$op == "~~" & pe_sr$lhs == pe_sr$rhs &
                pe_sr$lhs %in% c("Sd", "Sm"), ]
  subtitulo("Varianza de las pendientes latentes")
  print(as.data.frame(vs |> transmute(pendiente = lhs, varianza = est,
                                      ee = se, p = pvalue)), digits = 4)
  salidas$varianza_pendientes <- vs |>
    transmute(pendiente = lhs, varianza = est, ee = se, p = pvalue)

  cat("\n  LECTURA. Si la varianza de las pendientes es distinta de cero, las\n",
      "  personas SI difieren en velocidad y el supuesto del articulo estaba\n",
      "  violado. Lo que decide si eso importa es si los rezagos cruzados y la\n",
      "  correlacion de rasgo cambian al liberarlo.\n", sep = "")

  if (nrow(comp) >= 2) {
    cat(sprintf("\n  Correlacion de rasgo: %.4f -> %.4f (centrada)\n",
                comp$r_rasgo[1], comp$r_rasgo[2]))
    cat(sprintf("  Via dolor -> motor  : p = %.4f -> p = %.4f\n",
                comp$p_dolor_motor[1], comp$p_dolor_motor[2]))
    cat(sprintf("  Via motor -> dolor  : p = %.4f -> p = %.4f\n",
                comp$p_motor_dolor[1], comp$p_motor_dolor[2]))
    cambio <- abs(comp$r_rasgo[2] - comp$r_rasgo[1])
    cat(if (cambio < 0.05)
          "\n  La correlacion de rasgo apenas se mueve: el supuesto era inocuo\n  aqui, y el articulo puede decirlo con esta cifra.\n"
        else
          "\n  La correlacion de rasgo se mueve de forma apreciable: hay que\n  reportarlo, decidiendo antes cual de las dos parametrizaciones\n  responde a la pregunta del articulo.\n")
  }

  # Las dos parametrizaciones de la curva latente son el MISMO modelo con otra
  # base para el tiempo: deben dar identico ajuste. Si el ajuste coincide y la
  # correlacion no, la correlacion depende de donde se ponga el origen, y decir
  # "la pendiente aleatoria sube la correlacion" seria una afirmacion sobre la
  # parametrizacion y no sobre los datos.
  if (!is.null(fit_s0)) {
    dif_ajuste <- abs(comp$aic[2] - comp$aic[3])
    subtitulo("Las dos parametrizaciones de la curva latente")
    cat(sprintf("  Diferencia de AIC entre ellas: %.6f (deben ser el mismo modelo)\n",
                dif_ajuste))
    cat(sprintf("  Correlacion con cargas centradas: %.4f (p = %.4f)\n",
                comp$r_rasgo[2], comp$p_rasgo[2]))
    cat(sprintf("  Correlacion con cargas 0 a 5    : %.4f (p = %.4f)\n",
                comp$r_rasgo[3], comp$p_rasgo[3]))
    salidas$parametrizacion <- tibble(
      dif_aic = dif_ajuste,
      r_centrada = comp$r_rasgo[2], p_centrada = comp$p_rasgo[2],
      r_basal = comp$r_rasgo[3], p_basal = comp$p_rasgo[3])
    if (dif_ajuste < 0.01)
      cat("\n  Mismo ajuste, distinta correlacion: la cifra depende del origen\n",
          "  del tiempo. Solo la centrada es comparable con el RI-CLPM.\n", sep = "")
  }
}

titulo("Guardado")
guardar_tabla(comp, "t16_pendiente_comparacion.csv")
if (!is.null(salidas$lrt)) guardar_tabla(salidas$lrt, "t16_pendiente_lrt.csv")
if (!is.null(salidas$varianza_pendientes))
  guardar_tabla(salidas$varianza_pendientes, "t16_varianza_pendientes.csv")
saveRDS(salidas, file.path(PAPER_MOD, "pendiente_aleatoria.rds"))

cat("\n\nListo: R/paper/16_pendiente_aleatoria.R\n")
