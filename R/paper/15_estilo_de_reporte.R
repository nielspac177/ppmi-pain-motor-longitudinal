#!/usr/bin/env Rscript
# =============================================================================
# ARTICULO — El confusor de estilo de reporte
#
# LA OBJECION. Zolfaghari 2022, en esta misma cohorte, muestra que la Parte IB de
# la MDS-UPDRS, que contiene el item de dolor, correlaciona con la discapacidad
# motora AUTOINFORMADA mas fuertemente de lo que correlacionan entre si las
# escalas autoinformada y explorada, y que quienes mas sintomas reportan estan
# igual o menos afectados en la exploracion y en los biomarcadores.
#
# Si existe una tendencia estable de cada persona a reportar sintomas, esa
# tendencia produciria por si sola una correlacion de rasgo entre el dolor y
# cualquier otra medida, la produciria igual en controles sanos, y se amplificaria
# cuando las dos variables son autoinformadas. El articulo observa exactamente
# esas tres cosas. Declararlo en Limitaciones es necesario pero insuficiente:
# se puede CONTRASTAR con los datos que ya hay.
#
# LA OPERACIONALIZACION. Para cada paciente se estima cuanto reporta por encima
# de lo que la exploracion encuentra: el residuo de regresar la Parte II
# (autoinformada) sobre la Parte III (explorada). Un residuo positivo es alguien
# que refiere mas discapacidad de la que el examinador objetiva. El promedio
# intrapersonal de ese residuo es el indice de tendencia a reportar, y NO
# contiene el item de dolor.
#
# LAS DOS PREDICCIONES, declaradas antes de mirar:
#   Si el confusor de estilo explica la covariacion, ajustar por el indice debe
#   ATENUARLA de forma sustancial, y el indice debe asociarse con el dolor.
#   Si la covariacion es sustantiva, debe SOBREVIVIR al ajuste.
#
# Ejecutar:  Rscript R/paper/15_estilo_de_reporte.R
# =============================================================================

source(file.path(Sys.getenv("TESIS_ROOT", unset = getwd()), "R", "paper", "00_comun.R"))
suppressPackageStartupMessages({
  library(sandwich); library(lmtest); library(lavaan)
})

set.seed(SEED)
titulo("EL CONFUSOR DE ESTILO DE REPORTE")

d <- cargar_largo("off") |> filter(!is.na(UPDRS3), !is.na(NP1PAIN))
salidas <- list()

est_hc3 <- function(m, term) {
  ct <- lmtest::coeftest(m, vcov. = sandwich::vcovHC(m, type = "HC3"))
  c(b = ct[term, 1], lo = ct[term, 1] - 1.96 * ct[term, 2],
    hi = ct[term, 1] + 1.96 * ct[term, 2], p = ct[term, 4])
}

# =============================================================================
titulo("1. Construccion del indice de tendencia a reportar")

# El residuo se calcula por VISITA, sobre las observaciones con ambas partes, y
# luego se promedia por paciente. Calcularlo sobre promedios daria el mismo
# residuo medio pero perderia la variacion intrapersonal que lo estabiliza.
obs <- d |> filter(!is.na(UPDRS2), !is.na(UPDRS3))
cat(sprintf("\nObservaciones con Parte II y Parte III: %d en %d pacientes\n",
            nrow(obs), n_distinct(obs$PATNO)))

m_disc <- lm(scale(UPDRS2) ~ scale(UPDRS3), data = obs)
obs$discrepancia <- residuals(m_disc)
cat(sprintf("Correlacion Parte II con Parte III: r = %.3f\n",
            cor(obs$UPDRS2, obs$UPDRS3, use = "complete.obs")))

estilo <- obs |>
  group_by(PATNO) |>
  summarise(estilo = mean(discrepancia, na.rm = TRUE),
            n_obs_estilo = n(), .groups = "drop") |>
  filter(n_obs_estilo >= 2)

cat(sprintf("Pacientes con indice de estilo (2 o mas visitas): %d\n", nrow(estilo)))
cat(sprintf("Indice: media %.3f, DE %.3f, recorrido %.2f a %.2f\n",
            mean(estilo$estilo), sd(estilo$estilo),
            min(estilo$estilo), max(estilo$estilo)))

# La estabilidad del indice es su condicion de validez: si no es estable, no es
# un estilo sino ruido.
ancho_disc <- obs |>
  select(PATNO, EVENT_ID, discrepancia) |>
  pivot_wider(names_from = EVENT_ID, values_from = discrepancia)
if (all(c("BL", "V04") %in% names(ancho_disc))) {
  sub <- ancho_disc |> filter(!is.na(BL), !is.na(V04))
  cat(sprintf("Estabilidad del indice, basal frente a 12 meses: r = %.3f (n = %d)\n",
              cor(sub$BL, sub$V04), nrow(sub)))
  salidas$estabilidad <- tibble(contraste = "discrepancia BL vs V04",
                                r = cor(sub$BL, sub$V04), n = nrow(sub))
}

# =============================================================================
titulo("2. El indice se asocia con el dolor? (condicion previa del confusor)")

cat("\n  PREDICE el confusor: si existe una tendencia a reportar, debe asociarse\n",
    "  con el item de dolor, que tambien es autoinformado.\n", sep = "")

prom <- d |>
  group_by(PATNO) |>
  summarise(dolor = mean(dolor_int, na.rm = TRUE),
            motor = mean(UPDRS3, na.rm = TRUE),
            edad = mean(age_yrs, na.rm = TRUE), sexo = first(sexo),
            dur = mean(disease_yrs, na.rm = TRUE), moca = mean(MoCA, na.rm = TRUE),
            n_visitas = n(), .groups = "drop") |>
  filter(n_visitas >= 2) |>
  inner_join(estilo, by = "PATNO") |>
  drop_na(dolor, motor, edad, dur, moca, estilo)

cat(sprintf("\nPacientes en el analisis: %d\n", nrow(prom)))

m_ed <- lm(scale(dolor) ~ scale(estilo) + edad + sexo + dur + moca, data = prom)
e_ed <- est_hc3(m_ed, "scale(estilo)")
cat(sprintf("  estilo -> dolor: %+.3f DE (IC %.3f a %.3f), p = %.4g\n",
            e_ed[["b"]], e_ed[["lo"]], e_ed[["hi"]], e_ed[["p"]]))
salidas$estilo_dolor <- tibble(termino = "estilo de reporte -> dolor",
                               n = nobs(m_ed), beta_de = e_ed[["b"]],
                               ic_bajo = e_ed[["lo"]], ic_alto = e_ed[["hi"]],
                               p = e_ed[["p"]])

# =============================================================================
titulo("3. La covariacion dolor-motor sobrevive al ajuste por el estilo?")

m0 <- lm(scale(motor) ~ scale(dolor) + edad + sexo + dur + moca, data = prom)
m1 <- lm(scale(motor) ~ scale(dolor) + scale(estilo) + edad + sexo + dur + moca,
         data = prom)
comp <- bind_rows(
  tibble(ajuste = "sin ajustar por estilo", n = nobs(m0),
         !!!as.list(est_hc3(m0, "scale(dolor)"))),
  tibble(ajuste = "ajustado por estilo de reporte", n = nobs(m1),
         !!!as.list(est_hc3(m1, "scale(dolor)"))))
print(as.data.frame(comp), digits = 3)
aten <- 100 * (1 - comp$b[2] / comp$b[1])
cat(sprintf("\n  Atenuacion al ajustar por el estilo de reporte: %.1f %%\n", aten))
salidas$comparacion <- comp
salidas$atenuacion <- tibble(medida = "atenuacion por estilo de reporte",
                             porcentaje = aten)

cat("\n  LECTURA. Una atenuacion pequena deja al confusor de estilo sin apoyo\n",
    "  empirico y refuerza la covariacion. Una atenuacion grande, o un cambio de\n",
    "  significacion, indica que buena parte de lo observado es estilo de\n",
    "  reporte y el articulo tendria que decirlo como hallazgo, no como caveat.\n",
    sep = "")

# =============================================================================
titulo("4. El contraste decisivo: Parte III frente a Parte II")

cat("\n  PREDICE el confusor: el ajuste por estilo debe morder MUCHO mas en la\n",
    "  Parte II, que comparte metodo con la exposicion, que en la Parte III, que\n",
    "  no lo comparte. Si muerde igual en las dos, no es estilo de reporte.\n",
    sep = "")

prom2 <- d |>
  group_by(PATNO) |>
  summarise(dolor = mean(dolor_int, na.rm = TRUE),
            p2 = mean(UPDRS2, na.rm = TRUE), p3 = mean(UPDRS3, na.rm = TRUE),
            edad = mean(age_yrs, na.rm = TRUE), sexo = first(sexo),
            dur = mean(disease_yrs, na.rm = TRUE), moca = mean(MoCA, na.rm = TRUE),
            n_visitas = n(), .groups = "drop") |>
  filter(n_visitas >= 2) |>
  inner_join(estilo, by = "PATNO") |>
  drop_na(dolor, p2, p3, edad, dur, moca, estilo)

dos <- map_dfr(c("p3", "p2"), function(v) {
  a <- lm(as.formula(sprintf("scale(%s) ~ scale(dolor) + edad + sexo + dur + moca", v)),
          data = prom2)
  b <- lm(as.formula(sprintf(
    "scale(%s) ~ scale(dolor) + scale(estilo) + edad + sexo + dur + moca", v)),
    data = prom2)
  ea <- est_hc3(a, "scale(dolor)"); eb <- est_hc3(b, "scale(dolor)")
  tibble(desenlace = if (v == "p3") "Parte III (explorada)" else "Parte II (autoinformada)",
         n = nobs(a), sin_estilo = ea[["b"]], p_sin = ea[["p"]],
         con_estilo = eb[["b"]], p_con = eb[["p"]],
         atenuacion_pct = 100 * (1 - eb[["b"]] / ea[["b"]]))
})
print(as.data.frame(dos), digits = 3)
salidas$dos_desenlaces <- dos

cat("\n  LECTURA. Si la atenuacion es mucho mayor en la Parte II, el exceso de\n",
    "  correlacion que el articulo observa con esa escala se explica por metodo\n",
    "  compartido, que es justo lo que el manuscrito dice no poder distinguir.\n",
    "  Este contraste lo distingue.\n", sep = "")

# =============================================================================
titulo("Guardado")
guardar_tabla(salidas$estilo_dolor, "t15_estilo_dolor.csv")
guardar_tabla(comp, "t15_ajuste_por_estilo.csv")
guardar_tabla(dos, "t15_dos_desenlaces.csv")
if (!is.null(salidas$estabilidad)) guardar_tabla(salidas$estabilidad, "t15_estabilidad_estilo.csv")
saveRDS(salidas, file.path(PAPER_MOD, "estilo_de_reporte.rds"))

cat("\n\nListo: R/paper/15_estilo_de_reporte.R\n")

# =============================================================================
titulo("5. Un indice que NO sea ortogonal a la Parte III por construccion")

cat("\n  LA OBJECION A LO ANTERIOR. El indice se define como el residuo de la\n",
    "  Parte II sobre la Parte III, de modo que es ortogonal a la Parte III POR\n",
    "  CONSTRUCCION. Que ajustar por el no reduzca la asociacion con la Parte III\n",
    "  esta en parte garantizado, y un revisor lo dira. Hace falta un segundo\n",
    "  indice construido sin esa propiedad.\n",
    "  Se usa la suma de los OTROS items no motores del mismo cuestionario\n",
    "  (fatiga, insomnio y somnolencia), que comparten metodo y perspectiva con\n",
    "  el dolor y no estan definidos en relacion con nada motor.\n", sep = "")

prom3 <- d |>
  group_by(PATNO) |>
  summarise(dolor = mean(dolor_int, na.rm = TRUE),
            p3 = mean(UPDRS3, na.rm = TRUE), p2 = mean(UPDRS2, na.rm = TRUE),
            otros_p1 = mean(NP1FATG + NP1SLPN + NP1SLPD, na.rm = TRUE),
            edad = mean(age_yrs, na.rm = TRUE), sexo = first(sexo),
            dur = mean(disease_yrs, na.rm = TRUE), moca = mean(MoCA, na.rm = TRUE),
            n_visitas = n(), .groups = "drop") |>
  filter(n_visitas >= 2) |>
  drop_na(dolor, p3, p2, otros_p1, edad, dur, moca)

cat(sprintf("\nPacientes: %d\n", nrow(prom3)))
cat(sprintf("Correlacion del indice con la Parte III: r = %.3f (no es cero)\n",
            cor(prom3$otros_p1, prom3$p3)))

dos2 <- map_dfr(c("p3", "p2"), function(v) {
  a <- lm(as.formula(sprintf("scale(%s) ~ scale(dolor) + edad + sexo + dur + moca", v)),
          data = prom3)
  b <- lm(as.formula(sprintf(
    "scale(%s) ~ scale(dolor) + scale(otros_p1) + edad + sexo + dur + moca", v)),
    data = prom3)
  ea <- est_hc3(a, "scale(dolor)"); eb <- est_hc3(b, "scale(dolor)")
  tibble(desenlace = if (v == "p3") "Parte III (explorada)" else "Parte II (autoinformada)",
         n = nobs(a), sin_indice = ea[["b"]], p_sin = ea[["p"]],
         con_indice = eb[["b"]], p_con = eb[["p"]],
         atenuacion_pct = 100 * (1 - eb[["b"]] / ea[["b"]]))
})
subtitulo("Ajuste por los otros items no motores del mismo cuestionario")
print(as.data.frame(dos2), digits = 3)
salidas$indice_alternativo <- dos2
guardar_tabla(dos2, "t15_indice_alternativo.csv")

cat("\n  LECTURA. Este indice SI comparte varianza con la Parte III, de modo que\n",
    "  el contraste ya no esta garantizado por construccion. Si la asociacion\n",
    "  con la Parte III sigue en pie tras ajustarlo, la explicacion de estilo de\n",
    "  reporte queda sin apoyo para el desenlace primario.\n", sep = "")
