#!/usr/bin/env Rscript
# =============================================================================
# ARTICULO — Refutacion del RI-CLPM
#
# El script 01 encontro que, al separar la variacion estable entre personas de la
# dinamica intrapersonal, el rezago cruzado motor -> dolor se anula (p = 0,132) y
# sobrevive el de dolor -> motor (p = 0,013), junto con una correlacion de rasgo
# significativa (r = 0,175, p = 0,006).
#
# Antes de quedarse con ese resultado hay que intentar tumbarlo. Este script
# somete el rezago cruzado directo a siete comprobaciones:
#
#   R1  Restricciones de igualdad entre olas: prueba de razon de verosimilitudes
#       del modelo restringido frente al libre.
#   R2  Rezagos cruzados libres por ola: donde esta el efecto.
#   R3  Olas tempranas solamente (BL a V06), donde la atricion es menor.
#   R4  Variables auxiliares para la verosimilitud completa, que hacen mas
#       creible el supuesto de perdida al azar.
#   R5  Dolor dicotomizado, por si el resultado depende de tratar una escala
#       ordinal de cinco niveles como continua.
#   R6  Desenlace motor en estado ON, por si depende del estado de medicacion.
#   R7  Control negativo: se sustituye el desenlace motor por el MoCA. Si el
#       rezago cruzado tambien aparece ahi, no es especifico.
#
# Ejecutar:  Rscript R/paper/02_refutacion_riclpm.R
# =============================================================================

source(file.path(Sys.getenv("TESIS_ROOT", unset = getwd()), "R", "paper", "00_comun.R"))
suppressPackageStartupMessages({ library(lavaan) })

set.seed(SEED)
titulo("REFUTACION DEL RI-CLPM")

d <- cargar_largo("off")

# ---------------------------------------------------------------------------
# Constructor del modelo RI-CLPM para dos series x e y, con n olas.
# `libre = TRUE` levanta las restricciones de igualdad entre olas.
# ---------------------------------------------------------------------------
riclpm_sintaxis <- function(n = 6, libre = FALSE) {
  ix <- seq_len(n)
  L <- function(pref) paste0(pref, ix)
  txt <- c(
    paste0("RIx =~ ", paste(paste0("1*x", ix), collapse = " + ")),
    paste0("RIy =~ ", paste(paste0("1*y", ix), collapse = " + ")),
    paste0("wx", ix, " =~ 1*x", ix),
    paste0("wy", ix, " =~ 1*y", ix),
    paste0("x", ix, " ~~ 0*x", ix),
    paste0("y", ix, " ~~ 0*y", ix)
  )
  for (t in 2:n) {
    a <- if (libre) paste0("a", t) else "a"
    b <- if (libre) paste0("b", t) else "b"
    cc <- if (libre) paste0("c", t) else "c"
    e <- if (libre) paste0("e", t) else "e"
    txt <- c(txt,
      sprintf("wx%d ~ %s*wx%d + %s*wy%d", t, a, t - 1, b, t - 1),
      sprintf("wy%d ~ %s*wx%d + %s*wy%d", t, cc, t - 1, e, t - 1))
  }
  txt <- c(txt,
    "RIx ~~ RIy", "RIx ~~ RIx", "RIy ~~ RIy",
    "RIx ~~ 0*wx1 + 0*wy1", "RIy ~~ 0*wx1 + 0*wy1",
    paste0("wx", ix, " ~~ wy", ix))
  paste(txt, collapse = "\n")
}

# Formato ancho generico: x = exposicion, y = desenlace, mas auxiliares.
a_ancho <- function(datos, var_x, var_y, aux = character(0), visitas = VISITAS) {
  w <- datos |>
    filter(EVENT_ID %in% visitas) |>
    select(PATNO, EVENT_ID, x = all_of(var_x), y = all_of(var_y)) |>
    pivot_wider(names_from = EVENT_ID, values_from = c(x, y), names_sep = "_")
  nx <- paste0("x_", visitas); ny <- paste0("y_", visitas)
  w <- w |> select(PATNO, all_of(nx), all_of(ny))
  names(w) <- c("PATNO", paste0("x", seq_along(visitas)), paste0("y", seq_along(visitas)))
  if (length(aux)) {
    ax <- datos |> filter(EVENT_ID == "BL") |> select(PATNO, all_of(aux))
    w <- left_join(w, ax, by = "PATNO")
  }
  w
}

# Variables auxiliares por el metodo de correlatos saturados (Graham 2003): se
# correlacionan con los interceptos aleatorios, con los componentes
# intrapersonales de la primera ola y entre si, sin imponerles estructura. Asi la
# verosimilitud completa usa su informacion para hacer mas creible el supuesto de
# perdida al azar, sin alterar el modelo sustantivo.
#
# lavaan no acepta un argumento `auxiliary` en sem(), y semTools no es una
# dependencia de este proyecto, de modo que los correlatos se escriben a mano.
anadir_auxiliares <- function(sintaxis, aux) {
  if (!length(aux)) return(sintaxis)
  lineas <- c(sintaxis)
  for (a in aux) {
    lineas <- c(lineas, sprintf("%s ~~ RIx + RIy + wx1 + wy1", a))
  }
  if (length(aux) > 1) {
    for (i in seq_len(length(aux) - 1)) {
      lineas <- c(lineas, sprintf("%s ~~ %s", aux[i],
                                  paste(aux[(i + 1):length(aux)], collapse = " + ")))
    }
  }
  paste(lineas, collapse = "\n")
}

ajustar <- function(sintaxis, datos, etiqueta, aux = character(0)) {
  sintaxis <- anadir_auxiliares(sintaxis, aux)
  args <- list(model = sintaxis, data = datos, missing = "fiml",
               estimator = "MLR", fixed.x = FALSE)
  fit <- try(do.call(lavaan::sem, args), silent = TRUE)
  if (inherits(fit, "try-error")) {
    cat(sprintf("  %-46s ERROR: %s\n", etiqueta,
                sub("\n.*", "", conditionMessage(attr(fit, "condition")))))
    return(NULL)
  }
  if (!lavaan::lavInspect(fit, "converged")) {
    cat(sprintf("  %-46s NO CONVERGE\n", etiqueta)); return(NULL)
  }
  fit
}

# Extrae el rezago cruzado directo (c: x(t-1) -> y(t)) y el inverso (b).
resumen_cruzados <- function(fit, etiqueta) {
  if (is.null(fit)) return(NULL)
  pe <- lavaan::parameterEstimates(fit, standardized = TRUE)
  fm <- lavaan::fitMeasures(fit, c("cfi.robust", "rmsea.robust", "srmr"))
  saca <- function(lab) {
    f <- pe[pe$label == lab & pe$op == "~", ]
    if (nrow(f) == 0) return(NULL)
    f[1, ]
  }
  ri <- pe[pe$lhs == "RIx" & pe$rhs == "RIy" & pe$op == "~~", ]
  out <- tibble()
  for (lab in c("c", "b")) {
    f <- saca(lab)
    if (is.null(f)) next
    out <- bind_rows(out, tibble(
      comprobacion = etiqueta,
      via = if (lab == "c") "exposicion(t-1) -> desenlace(t)" else "desenlace(t-1) -> exposicion(t)",
      estimacion = f$est, ee = f$se, ic_bajo = f$ci.lower, ic_alto = f$ci.upper,
      p = f$pvalue, est_std = f$std.all,
      r_rasgo = if (nrow(ri)) ri$std.all[1] else NA_real_,
      p_rasgo = if (nrow(ri)) ri$pvalue[1] else NA_real_,
      cfi = fm[["cfi.robust"]], rmsea = fm[["rmsea.robust"]], srmr = fm[["srmr"]]))
  }
  out
}

pruebas <- list()

# =============================================================================
# Modelo de referencia
# =============================================================================
titulo("Modelo de referencia (dolor -> motor, 6 olas, restringido)")
w_base <- a_ancho(d, "dolor_int", "UPDRS3")
fit_base <- ajustar(riclpm_sintaxis(6, libre = FALSE), w_base, "referencia")
ref <- resumen_cruzados(fit_base, "R0 referencia (restringido, 6 olas)")
print(as.data.frame(ref), digits = 4)
pruebas$R0 <- ref

# =============================================================================
# R1 — Tenibilidad de las restricciones de igualdad
# =============================================================================
titulo("R1 — Restricciones de igualdad entre olas")
fit_libre <- ajustar(riclpm_sintaxis(6, libre = TRUE), w_base, "libre")
if (!is.null(fit_base) && !is.null(fit_libre)) {
  cmp <- lavaan::lavTestLRT(fit_base, fit_libre)
  print(cmp)
  p_lrt <- cmp[["Pr(>Chisq)"]][2]
  cat(sprintf("\n  Razon de verosimilitudes restringido vs libre: p = %.4g\n", p_lrt))
  cat(if (is.na(p_lrt) || p_lrt > 0.05)
        "  Las restricciones de igualdad NO se rechazan: el modelo restringido es admisible.\n"
      else
        "  Las restricciones SE RECHAZAN: hay que reportar los rezagos por ola.\n")
  pruebas$R1 <- tibble(comprobacion = "R1 igualdad entre olas (LRT restringido vs libre)",
                       estadistico = cmp[["Chisq diff"]][2], gl = cmp[["Df diff"]][2],
                       p = p_lrt)
}

# =============================================================================
# R2 — Rezagos cruzados libres por ola
# =============================================================================
titulo("R2 — Rezago cruzado directo, libre por ola")
if (!is.null(fit_libre)) {
  pe <- lavaan::parameterEstimates(fit_libre, standardized = TRUE)
  cs <- pe[grepl("^c[2-6]$", pe$label) & pe$op == "~", ]
  r2 <- tibble(comprobacion = paste0("R2 rezago c en la ola ", sub("c", "", cs$label)),
               via = "dolor(t-1) -> motor(t)",
               estimacion = cs$est, ee = cs$se, ic_bajo = cs$ci.lower,
               ic_alto = cs$ci.upper, p = cs$pvalue, est_std = cs$std.all)
  print(as.data.frame(r2), digits = 4)
  pruebas$R2 <- r2
}

# =============================================================================
# R3 — Olas tempranas (BL a V06), menos atricion
# =============================================================================
titulo("R3 — Solo BL, V04 y V06")
w3 <- a_ancho(d, "dolor_int", "UPDRS3", visitas = c("BL", "V04", "V06"))
fit3 <- ajustar(riclpm_sintaxis(3, libre = FALSE), w3, "3 olas")
r3 <- resumen_cruzados(fit3, "R3 solo BL-V04-V06")
print(as.data.frame(r3), digits = 4)
pruebas$R3 <- r3

# =============================================================================
# R4 — Variables auxiliares (verosimilitud completa mas creible bajo MAR)
# =============================================================================
titulo("R4 — Con variables auxiliares basales")
AUX <- c("age_yrs", "sex_male", "disease_yrs", "MoCA", "GDS", "LEDD")
w4 <- a_ancho(d, "dolor_int", "UPDRS3", aux = AUX)
fit4 <- ajustar(riclpm_sintaxis(6, libre = FALSE), w4, "auxiliares", aux = AUX)
r4 <- resumen_cruzados(fit4, "R4 con auxiliares basales")
print(as.data.frame(r4), digits = 4)
pruebas$R4 <- r4

# =============================================================================
# R5 — Dolor dicotomizado
# =============================================================================
titulo("R5 — Exposicion dicotomizada (presencia de dolor)")
w5 <- a_ancho(d, "dolor_si", "UPDRS3")
fit5 <- ajustar(riclpm_sintaxis(6, libre = FALSE), w5, "dicotomica")
r5 <- resumen_cruzados(fit5, "R5 dolor dicotomizado")
print(as.data.frame(r5), digits = 4)
pruebas$R5 <- r5

# =============================================================================
# R6 — Desenlace motor en estado ON
# =============================================================================
titulo("R6 — Desenlace motor en estado ON")
w6 <- a_ancho(d, "dolor_int", "UPDRS3_on")
fit6 <- ajustar(riclpm_sintaxis(6, libre = FALSE), w6, "motor ON")
r6 <- resumen_cruzados(fit6, "R6 motor en estado ON")
print(as.data.frame(r6), digits = 4)
pruebas$R6 <- r6

# =============================================================================
# R7 — Control negativo: el MoCA como desenlace
# =============================================================================
titulo("R7 — Control negativo: MoCA como desenlace")
w7 <- a_ancho(d, "dolor_int", "MoCA")
fit7 <- ajustar(riclpm_sintaxis(6, libre = FALSE), w7, "MoCA")
r7 <- resumen_cruzados(fit7, "R7 control negativo: MoCA")
print(as.data.frame(r7), digits = 4)
pruebas$R7 <- r7

# =============================================================================
# SINTESIS
# =============================================================================
titulo("Sintesis de la refutacion")

tab <- bind_rows(pruebas[c("R0", "R3", "R4", "R5", "R6", "R7")]) |>
  filter(via == "exposicion(t-1) -> desenlace(t)")

subtitulo("Via intrapersonal dolor(t-1) -> motor(t): sobrevive o no")
print(as.data.frame(tab |> select(comprobacion, estimacion, ic_bajo, ic_alto, p, est_std)),
      digits = 4)

n_sig <- sum(tab$p < ALPHA, na.rm = TRUE)
cat(sprintf("\n  Especificaciones en que la via intrapersonal alcanza significacion: %d de %d\n",
            n_sig, nrow(tab)))
if (!is.null(pruebas$R2)) {
  cat(sprintf("  Olas en que el rezago libre alcanza significacion: %d de %d\n",
              sum(pruebas$R2$p < ALPHA, na.rm = TRUE), nrow(pruebas$R2)))
}

subtitulo("Correlacion de rasgo (interceptos aleatorios): sobrevive o no")
print(as.data.frame(tab |> select(comprobacion, r_rasgo, p_rasgo, cfi, rmsea, srmr)), digits = 4)

cat("\n  Atencion: el control negativo R7 usa el MoCA como desenlace. Si su\n",
    " correlacion de rasgo tambien es distinta de cero, la covariacion estable\n",
    " del dolor NO es especifica de la severidad motora, y esa es una\n",
    " explicacion rival que el articulo debe tratar de frente.\n", sep = "")

todo <- bind_rows(lapply(names(pruebas), function(k) {
  x <- pruebas[[k]]
  if (is.null(x)) return(NULL)
  x |> mutate(across(everything(), as.character))
}))
guardar_tabla(todo, "t02_refutacion_riclpm.csv")
saveRDS(pruebas, file.path(PAPER_MOD, "refutacion_riclpm.rds"))

cat("\n\nListo: R/paper/02_refutacion_riclpm.R\n")

# =============================================================================
# R8 — DESENLACE AUTOINFORMADO FRENTE A DESENLACE DEL EXAMINADOR
# =============================================================================
titulo("R8 — MDS-UPDRS Parte II (autoinformada) como desenlace paralelo")

cat("\n  LA PREGUNTA. La exposicion es autoinformada y el desenlace primario lo\n",
    "  puntua un examinador, lo que descarta varianza de metodo compartida pero\n",
    "  tambien introduce una asimetria: si la relacion entre dolor y funcion\n",
    "  motora vive en la EXPERIENCIA del paciente y no en el signo explorado,\n",
    "  aparecera con la Parte II y no con la Parte III.\n",
    "  Es una prediccion diferencial, no una repeticion: las dos partes miden el\n",
    "  mismo dominio motor por vias distintas.\n", sep = "")

w8 <- a_ancho(d, "dolor_int", "UPDRS2")
fit8 <- ajustar(riclpm_sintaxis(6, libre = FALSE), w8, "Parte II autoinformada")
r8 <- resumen_cruzados(fit8, "R8 desenlace Parte II (autoinformado)")
print(as.data.frame(r8), digits = 4)
pruebas$R8 <- r8

subtitulo("Contraste directo: Parte II frente a Parte III")
if (!is.null(r8) && !is.null(pruebas$R0)) {
  comp8 <- bind_rows(
    pruebas$R0 |> mutate(desenlace = "Parte III (examinador)"),
    r8 |> mutate(desenlace = "Parte II (autoinformada)")
  ) |>
    select(desenlace, via, estimacion, ic_bajo, ic_alto, p, est_std, r_rasgo, p_rasgo)
  print(as.data.frame(comp8), digits = 4)
  pruebas$comparacion_partes <- comp8
  guardar_tabla(comp8, "t02_parte2_vs_parte3.csv")

  cat("\n  LECTURA. Si la via intrapersonal aparece con la Parte II y no con la\n",
      "  Parte III, el hallazgo deja de ser un nulo: la relacion existe en la\n",
      "  funcion que el paciente refiere y no en el signo que el clinico explora.\n",
      "  Si no aparece en ninguna, el nulo se refuerza y no es un artefacto de\n",
      "  haber elegido un desenlace poco sensible.\n", sep = "")
}
