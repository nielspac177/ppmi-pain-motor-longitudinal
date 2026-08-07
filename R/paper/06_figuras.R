#!/usr/bin/env Rscript
# =============================================================================
# ARTICULO — Figuras, estetica JAMA Neurology, en INGLES.
#
# El articulo se escribe en ingles por decision del asesor, de modo que estas
# figuras usan rotulos en ingles y punto decimal, a diferencia de las de la
# tesis, que van en espanol con coma decimal. Las dos convenciones conviven en el
# repositorio y no deben mezclarse dentro de un mismo documento.
#
# Paleta: negro, grises y un solo acento (azul marino #003366).
# Formato: PDF vectorial + PNG a 320 ppp. Cada figura se guarda en dos variantes,
# autonoma (con titulo y pie) y desnuda (para incrustar en el manuscrito).
#
# Ejecutar:  Rscript R/paper/06_figuras.R
# =============================================================================

source(file.path(Sys.getenv("TESIS_ROOT", unset = getwd()), "R", "paper", "00_comun.R"))
suppressPackageStartupMessages({ library(patchwork); library(grid) })

NEGRO <- "#000000"; GRIS_OSC <- "#404040"; GRIS <- "#7A7A7A"; GRIS_CLA <- "#D0D0D0"
MARINO <- "#003366"; MARINO_CLA <- "#E8EDF3"
BASE <- 10

# Punto decimal: el manuscrito va en ingles.
n_en <- function(x, d = 2) formatC(x, format = "f", digits = d, big.mark = ",")
p_en <- function(p) ifelse(p < 0.001, "<0.001", formatC(p, format = "f", digits = 3))
env <- function(x, ancho = 118) paste(strwrap(x, width = ancho), collapse = "\n")

tema <- function(base_size = BASE) {
  theme_classic(base_size = base_size, base_family = "Helvetica") +
    theme(
      text = element_text(colour = NEGRO),
      axis.text = element_text(colour = NEGRO, size = base_size - 0.5),
      axis.title = element_text(colour = NEGRO, size = base_size),
      axis.line = element_line(colour = NEGRO, linewidth = 0.4),
      axis.ticks = element_line(colour = NEGRO, linewidth = 0.4),
      plot.title = element_text(face = "bold", size = base_size + 1, hjust = 0),
      plot.subtitle = element_text(colour = GRIS_OSC, size = base_size - 0.5, hjust = 0),
      plot.caption = element_text(colour = GRIS_OSC, size = base_size - 2.5, hjust = 0),
      plot.tag = element_text(face = "bold", size = base_size + 2),
      strip.background = element_blank(),
      strip.text = element_text(colour = NEGRO, size = base_size - 0.5, face = "bold"),
      legend.position = "none",
      panel.grid = element_blank(),
      # Sin esto el titulo se alinea al PANEL, no al lienzo, y en las figuras con
      # rotulos de eje largos aparece centrado en lugar de a la izquierda.
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.margin = margin(6, 8, 6, 8))
}

# Etiqueta de valor p sin el "p = <0.001" que produce concatenar el prefijo con
# un valor ya formateado como desigualdad.
lab_p <- function(p) ifelse(p < 0.001, "p < 0.001", paste0("p = ", p_en(p)))

guardar <- function(p, anotacion, nombre, ancho, alto) {
  completa <- p + anotacion
  ggsave(file.path(PAPER_FIG, paste0(nombre, ".pdf")), completa,
         width = ancho, height = alto, device = cairo_pdf)
  ggsave(file.path(PAPER_FIG, paste0(nombre, ".png")), completa,
         width = ancho, height = alto, dpi = 320, bg = "white")
  ggsave(file.path(PAPER_FIG, paste0(nombre, "_doc.pdf")), p,
         width = ancho, height = alto * 0.88, device = cairo_pdf)
  ggsave(file.path(PAPER_FIG, paste0(nombre, "_doc.png")), p,
         width = ancho, height = alto * 0.88, dpi = 320, bg = "white")
  cat(sprintf("  %-40s %.1f x %.1f in\n", paste0(nombre, ".{pdf,png}"), ancho, alto))
}

T <- function(f) read_csv(file.path(PAPER_TAB, f), show_col_types = FALSE)
cat("\nGenerating figures...\n")

# =============================================================================
# FIGURE 1 — Methods schematic
# =============================================================================
# Explica de un vistazo por que hacen falta tres aparatos distintos y que
# pregunta responde cada uno. Es la figura que pidio el encargo.

cajas <- tribble(
  ~x, ~y, ~w, ~h, ~txt, ~tipo,
  # fila 1: el problema
  1.0, 5.2, 2.6, 1.0, "Pain and motor severity\nco-occur in PD", "problema",
  4.4, 5.2, 2.6, 1.0, "Which comes first?\nOr neither?", "problema",
  7.8, 5.2, 2.6, 1.0, "Dopaminergic dose\nchanges with both", "problema",
  # fila 2: el aparato
  1.0, 3.4, 2.6, 1.2, "RI-CLPM\nseparates between-person\nfrom within-person", "metodo",
  4.4, 3.4, 2.6, 1.2, "Mixed model + IPCW\nlevel vs slope,\nattrition weighted", "metodo",
  7.8, 3.4, 2.6, 1.2, "MSM (IPTW) + g-formula\ntime-varying confounding\nby prior exposure", "metodo",
  # fila 3: lo que responde
  1.0, 1.6, 2.6, 1.1, "Stable trait covariation\nr = 0.175\nNo temporal precedence", "resultado",
  4.4, 1.6, 2.6, 1.1, "Level effect, not slope\n+1.00 points/pain point\nSlope p = 0.19", "resultado",
  7.8, 1.6, 2.6, 1.1, "Attenuates by ~37%\nbut persists\n1.71 (0.72 to 2.67)", "resultado"
)

flechas <- tribble(
  ~x, ~xend, ~y, ~yend,
  1.0, 1.0, 4.70, 4.05,
  4.4, 4.4, 4.70, 4.05,
  7.8, 7.8, 4.70, 4.05,
  1.0, 1.0, 2.80, 2.18,
  4.4, 4.4, 2.80, 2.18,
  7.8, 7.8, 2.80, 2.18
)

f1 <- ggplot() +
  geom_tile(data = cajas, aes(x, y, width = w, height = h,
                              fill = tipo, colour = tipo), linewidth = 0.5) +
  scale_fill_manual(values = c(problema = "white", metodo = MARINO_CLA,
                               resultado = "white")) +
  scale_colour_manual(values = c(problema = GRIS, metodo = MARINO,
                                 resultado = NEGRO)) +
  geom_text(data = cajas, aes(x, y, label = txt), size = 2.6,
            colour = NEGRO, lineheight = 1.08) +
  geom_segment(data = flechas, aes(x = x, xend = xend, y = y, yend = yend),
               arrow = arrow(length = unit(0.10, "cm"), type = "closed"),
               colour = GRIS_OSC, linewidth = 0.4) +
  annotate("text", x = -0.62, y = 5.2, label = "Question", angle = 90,
           size = 2.5, colour = GRIS_OSC, fontface = "bold") +
  annotate("text", x = -0.62, y = 3.4, label = "Method", angle = 90,
           size = 2.5, colour = MARINO, fontface = "bold") +
  annotate("text", x = -0.62, y = 1.6, label = "Finding", angle = 90,
           size = 2.5, colour = NEGRO, fontface = "bold") +
  coord_cartesian(xlim = c(-0.95, 9.4), ylim = c(0.85, 5.95)) +
  theme_void(base_size = BASE, base_family = "Helvetica") +
  # theme_void NO apaga la leyenda: sin esto aparece una leyenda con los nombres
  # internos de las categorias, en espanol, dentro de una figura en ingles. Es un
  # defecto que solo se ve al abrir la imagen renderizada.
  theme(legend.position = "none",
        plot.title = element_text(face = "bold", size = BASE + 1, family = "Helvetica"),
        plot.caption = element_text(colour = GRIS_OSC, size = BASE - 2.5, hjust = 0,
                                    family = "Helvetica"))

guardar(f1,
        labs(title = "Figure 1. Analytic strategy",
             caption = env(paste(
               "Each column pairs one question with the estimator that answers it and the",
               "finding it produced. RI-CLPM, random-intercept cross-lagged panel model;",
               "IPCW, inverse probability of censoring weighting; MSM, marginal structural",
               "model; IPTW, inverse probability of treatment weighting."))),
        "figure1_methods", 9.0, 5.4)

# =============================================================================
# FIGURE 2 — Directionality: classic CLPM vs RI-CLPM
# =============================================================================
sem <- T("t01_direccionalidad_sem.csv") |>
  filter(grepl("cruzado", parametro)) |>
  mutate(
    via = if_else(grepl("directo", parametro), "Pain(t-1) -> Motor(t)", "Motor(t-1) -> Pain(t)"),
    modelo = factor(modelo, levels = c("CLPM clasico", "RI-CLPM"),
                    labels = c("Classic CLPM\n(between + within confounded)",
                               "RI-CLPM\n(between and within separated)")),
    signif = p < 0.05)

f2a <- ggplot(sem, aes(x = est_std, y = via)) +
  geom_vline(xintercept = 0, colour = GRIS, linewidth = 0.4, linetype = "22") +
  geom_errorbarh(aes(xmin = est_std - 1.96 * (est_std / pmax(abs(estimacion), 1e-9)) *
                       (estimacion - ic_bajo) / 1.96,
                     xmax = est_std + 1.96 * (est_std / pmax(abs(estimacion), 1e-9)) *
                       (ic_alto - estimacion) / 1.96),
                 height = 0.10, linewidth = 0.45, colour = NEGRO) +
  geom_point(aes(fill = signif), shape = 21, size = 2.6, colour = NEGRO, stroke = 0.5) +
  scale_fill_manual(values = c(`TRUE` = MARINO, `FALSE` = "white")) +
  geom_text(aes(label = lab_p(p)), vjust = -1.35, size = 2.5, colour = GRIS_OSC) +
  facet_wrap(~ modelo, ncol = 2) +
  labs(x = "Standardised cross-lagged coefficient", y = NULL) +
  tema() + theme(axis.text.y = element_text(size = BASE - 0.5))

ri <- T("t01_correlacion_rasgo.csv")
f2b <- ggplot(ri, aes(x = r, y = "Stable between-person\ncorrelation of the two series")) +
  geom_vline(xintercept = 0, colour = GRIS, linewidth = 0.4, linetype = "22") +
  geom_point(shape = 21, size = 3.2, fill = MARINO, colour = NEGRO, stroke = 0.5) +
  geom_text(aes(label = paste0("r = ", n_en(r, 3), ", ", lab_p(p))),
            vjust = -1.4, size = 2.6, colour = GRIS_OSC) +
  coord_cartesian(xlim = c(-0.05, 0.35)) +
  labs(x = "Correlation of random intercepts (RI-CLPM)", y = NULL) +
  tema()

f2 <- f2a / f2b + plot_layout(heights = c(2, 1))

guardar(f2,
        plot_annotation(
          title = "Figure 2. Direction of the pain and motor severity relationship",
          caption = env(paste(
            "Left panels: the classic cross-lagged panel model makes both directions",
            "significant. Right: once stable between-person differences are separated by",
            "random intercepts, the motor-to-pain path is null and only a modest",
            "pain-to-motor path remains, which does not survive the robustness checks",
            "reported in the text. Bottom: the two series covary stably across people.",
            "Filled circles denote p < 0.05. Model fit favours the RI-CLPM",
            "(CFI 0.960 vs 0.877; RMSEA 0.067 vs 0.114).")),
          theme = theme(plot.title = element_text(face = "bold", size = BASE + 1,
                                                  family = "Helvetica"),
                        plot.caption = element_text(colour = GRIS_OSC, size = BASE - 2.5,
                                                    hjust = 0, family = "Helvetica"))),
        "figure2_direction", 9.0, 5.6)

# =============================================================================
# FIGURE 3 — Level, not slope; and attrition
# =============================================================================
mix <- T("t04_mixto.csv") |> mutate(fuente = "Unweighted")
mixw <- T("t04_mixto_ipcw.csv") |>
  mutate(ic_bajo = estimacion - 1.96 * ee, ic_alto = estimacion + 1.96 * ee,
         fuente = "IPCW weighted")
mm <- bind_rows(mix, mixw) |>
  filter(termino != "tiempo (pendiente)") |>
  mutate(termino = factor(termino,
                          levels = c("dolor basal (nivel)", "dolor basal x tiempo"),
                          labels = c("Baseline pain: LEVEL\n(points of MDS-UPDRS III per pain point)",
                                     "Baseline pain x time: SLOPE\n(points per pain point per year)")),
         fuente = factor(fuente, levels = c("Unweighted", "IPCW weighted")))

f3a <- ggplot(mm, aes(x = estimacion, y = fuente)) +
  geom_vline(xintercept = 0, colour = GRIS, linewidth = 0.4, linetype = "22") +
  geom_errorbarh(aes(xmin = ic_bajo, xmax = ic_alto), height = 0.11,
                 linewidth = 0.45, colour = NEGRO) +
  geom_point(aes(fill = p < 0.05), shape = 21, size = 2.6, colour = NEGRO, stroke = 0.5) +
  scale_fill_manual(values = c(`TRUE` = MARINO, `FALSE` = "white")) +
  geom_text(aes(label = lab_p(p)), vjust = -1.35, size = 2.4, colour = GRIS_OSC) +
  facet_wrap(~ termino, ncol = 2, scales = "free_x") +
  labs(x = "Estimate (95% CI)", y = NULL) + tema()

ret <- T("t04_retencion.csv") |>
  mutate(EVENT_ID = factor(EVENT_ID, levels = VISITAS))
f3b <- ggplot(ret, aes(x = EVENT_ID, y = pct)) +
  geom_col(fill = GRIS_CLA, colour = GRIS_OSC, width = 0.66, linewidth = 0.35) +
  geom_text(aes(label = paste0(n_presente, "\n(", n_en(pct, 1), "%)")),
            vjust = -0.25, size = 2.4, colour = NEGRO, lineheight = 0.95) +
  scale_y_continuous(limits = c(0, 118), expand = c(0, 0)) +
  labs(x = "Visit", y = "Retained (%)") + tema()

f3 <- f3a / f3b + plot_layout(heights = c(1.15, 1))

guardar(f3,
        plot_annotation(
          title = "Figure 3. Pain marks a level, not a rate of progression",
          caption = env(paste(
            "Top: baseline pain is associated with a persistently higher motor score",
            "across follow-up, but not with a steeper slope. Weighting for attrition by",
            "inverse probability of censoring leaves both conclusions unchanged. Bottom:",
            "retention by visit among the 1,190 participants with a baseline assessment.",
            "Baseline pain did not predict dropout at any horizon (all p > 0.12); baseline",
            "motor severity did (OR 0.967 per point at year 5, p < 0.001).")),
          theme = theme(plot.title = element_text(face = "bold", size = BASE + 1,
                                                  family = "Helvetica"),
                        plot.caption = element_text(colour = GRIS_OSC, size = BASE - 2.5,
                                                    hjust = 0, family = "Helvetica"))),
        "figure3_level_slope", 9.0, 5.4)

# =============================================================================
# FIGURE 4 — Time-varying confounding by dopaminergic dose
# =============================================================================
msm <- T("t05_sintesis_msm.csv") |>
  mutate(especificacion = factor(especificacion,
    levels = rev(c("regresion estandar SIN ajustar por LEDD",
                   "regresion estandar AJUSTANDO por LEDD",
                   "modelo estructural marginal (IPTW estabilizado)",
                   "MSM con IC por remuestreo de pacientes",
                   "estimacion g por sustitucion")),
    labels = rev(c("Standard regression, LEDD not adjusted",
                   "Standard regression, LEDD adjusted",
                   "MSM, stabilised IPTW (sandwich CI)",
                   "MSM, stabilised IPTW (patient bootstrap CI)",
                   "g-formula (substitution estimator)"))),
    familia = if_else(grepl("^Standard", especificacion), "conv", "causal"))

f4 <- ggplot(msm, aes(x = estimacion, y = especificacion)) +
  geom_vline(xintercept = 0, colour = GRIS, linewidth = 0.4, linetype = "22") +
  geom_errorbarh(aes(xmin = ic_bajo, xmax = ic_alto), height = 0.13,
                 linewidth = 0.45, colour = NEGRO) +
  geom_point(aes(fill = familia), shape = 21, size = 2.8, colour = NEGRO, stroke = 0.5) +
  scale_fill_manual(values = c(conv = "white", causal = MARINO)) +
  # Las etiquetas van en una COLUMNA fija a la derecha, no pegadas al punto: con
  # hjust relativo se montan encima de los bigotes y quedan ilegibles. Es un
  # defecto que solo aparece al abrir la imagen.
  geom_text(aes(x = 4.6, label = paste0(n_en(estimacion, 2), " (", n_en(ic_bajo, 2),
                                        " to ", n_en(ic_alto, 2), ")")),
            hjust = 0, size = 2.4, colour = GRIS_OSC) +
  coord_cartesian(xlim = c(-0.2, 7.2)) +
  labs(x = "Difference in MDS-UPDRS III (points) for pain present vs absent",
       y = NULL) +
  tema() + theme(axis.text.y = element_text(size = BASE - 1))

guardar(f4,
        labs(title = "Figure 4. Handling dopaminergic dose as a time-varying confounder",
             caption = env(paste(
               "Dopaminergic dose is affected by prior pain and in turn affects both later",
               "pain and motor severity, so conventional regression is biased whether or not",
               "it is adjusted for. Filled circles are the two causal estimators, which agree",
               "closely with each other and are about 37% smaller than the conventional",
               "estimates. All five models are fitted on the same 1,970 observations from",
               "787 patients. LEDD, levodopa equivalent daily dose."))),
        "figure4_msm", 9.0, 3.4)

# =============================================================================
# FIGURE 5 — Phenotype: prevalence, instability, and the null interaction
# =============================================================================
dist <- T("t03_fenotipo_distribucion.csv") |>
  mutate(EVENT_ID = factor(EVENT_ID, levels = VISITAS),
         fenotipo = factor(fenotipo, levels = c("TD", "Indeterminado", "PIGD"),
                           labels = c("TD", "Indeterminate", "PIGD")))

f5a <- ggplot(dist, aes(x = EVENT_ID, y = pct, fill = fenotipo)) +
  geom_col(width = 0.68, colour = GRIS_OSC, linewidth = 0.3) +
  scale_fill_manual(values = c(TD = "white", Indeterminate = GRIS_CLA, PIGD = MARINO)) +
  scale_y_continuous(expand = c(0, 0)) +
  labs(x = "Visit", y = "Share of sample (%)", subtitle = "A. Phenotype drifts toward PIGD") +
  tema() + theme(legend.position = "right", legend.title = element_blank(),
                 legend.key.size = unit(0.32, "cm"),
                 legend.text = element_text(size = BASE - 2))

est <- T("t03_fenotipo_estabilidad.csv") |>
  mutate(visita = factor(visita, levels = VISITAS))
f5b <- ggplot(est, aes(x = visita)) +
  geom_line(aes(y = concordancia, group = 1), colour = NEGRO, linewidth = 0.5) +
  geom_point(aes(y = concordancia), shape = 21, fill = "white", colour = NEGRO, size = 2.2) +
  geom_line(aes(y = kappa, group = 1), colour = MARINO, linewidth = 0.5, linetype = "22") +
  geom_point(aes(y = kappa), shape = 21, fill = MARINO, colour = NEGRO, size = 2.2) +
  annotate("text", x = 1.3, y = 0.80, label = "Raw agreement", size = 2.4, colour = NEGRO) +
  annotate("text", x = 1.3, y = 0.36, label = "Cohen kappa", size = 2.4, colour = MARINO) +
  scale_y_continuous(limits = c(0, 1)) +
  labs(x = "Visit compared with baseline", y = "Agreement with baseline class",
       subtitle = "B. The class label is not stable") +
  tema()

estr <- T("t03_estratificado.csv") |>
  filter(modelo == "UPDRS3 ~ dolor_int | fenotipo_bl") |>
  mutate(estrato = factor(estrato, levels = c("PIGD", "Indeterminado", "TD"),
                          labels = c("PIGD", "Indeterminate", "TD")))
prim <- T("t03_multiplicidad.csv") |>
  filter(modelo == "UPDRS3 ~ dolor_int x fenotipo_bl")

f5c <- ggplot(estr, aes(x = estimacion, y = estrato)) +
  geom_vline(xintercept = 0, colour = GRIS, linewidth = 0.4, linetype = "22") +
  geom_errorbarh(aes(xmin = ic_bajo, xmax = ic_alto), height = 0.11,
                 linewidth = 0.45, colour = NEGRO) +
  geom_point(aes(fill = p < 0.05), shape = 21, size = 2.6, colour = NEGRO, stroke = 0.5) +
  scale_fill_manual(values = c(`TRUE` = MARINO, `FALSE` = "white")) +
  geom_text(aes(label = paste0("n = ", n)), vjust = -1.35, size = 2.3, colour = GRIS_OSC) +
  labs(x = "MDS-UPDRS III points per pain point (95% CI)", y = NULL,
       subtitle = sprintf("C. Stratified effect. Interaction PIGD vs TD: p = %s",
                          p_en(prim$p[1]))) +
  tema()

f5 <- (f5a | f5b) / f5c + plot_layout(heights = c(1, 0.85))

guardar(f5,
        plot_annotation(
          title = "Figure 5. The motor phenotype does not modify the association",
          caption = env(paste(
            "Pain is more common in the PIGD phenotype (adjusted ordinal OR 1.49,",
            "95% CI 1.06 to 2.08), but the phenotype does not modify the pain and motor",
            "severity association. The pre-specified interaction is null, and across the",
            "eight PIGD versus TD contrasts examined none survives correction for multiple",
            "comparisons. Panel B shows why the class should not be treated as a trait:",
            "agreement with the baseline class falls from 74.0% at one year to 59.5% at",
            "five. TD, tremor dominant; PIGD, postural instability and gait difficulty.")),
          theme = theme(plot.title = element_text(face = "bold", size = BASE + 1,
                                                  family = "Helvetica"),
                        plot.caption = element_text(colour = GRIS_OSC, size = BASE - 2.5,
                                                    hjust = 0, family = "Helvetica"))),
        "figure5_phenotype", 9.0, 6.0)

# =============================================================================
# FIGURE 6 — Discriminant test
# =============================================================================
disc <- T("t04_discriminante.csv") |>
  mutate(sintoma = factor(sintoma,
    levels = rev(c("dolor", "AVD", "autonomico", "somnolencia", "sueno_REM",
                   "depresion", "ansiedad")),
    labels = rev(c("Pain (MDS-UPDRS 1.9)", "Activities of daily living (Part II)",
                   "Autonomic (SCOPA-AUT)", "Daytime sleepiness (ESS)",
                   "REM sleep behaviour (RBDSQ)", "Depression (GDS-15)",
                   "Anxiety (STAI-state)"))),
    destacado = sintoma %in% c("Pain (MDS-UPDRS 1.9)", "Activities of daily living (Part II)"))

f6 <- ggplot(disc, aes(x = estimacion, y = sintoma)) +
  geom_vline(xintercept = 0, colour = GRIS, linewidth = 0.4, linetype = "22") +
  geom_errorbarh(aes(xmin = ic_bajo, xmax = ic_alto), height = 0.12,
                 linewidth = 0.45, colour = NEGRO) +
  geom_point(aes(fill = destacado), shape = 21, size = 2.6, colour = NEGRO, stroke = 0.5) +
  scale_fill_manual(values = c(`TRUE` = MARINO, `FALSE` = "white")) +
  geom_text(aes(x = 2.1, label = paste0(lab_p(p), "   BH ", p_en(p_bh))),
            hjust = 0, size = 2.3, colour = GRIS_OSC) +
  coord_cartesian(xlim = c(-1.5, 4.3)) +
  labs(x = "MDS-UPDRS III points at 12 months per baseline SD (95% CI)", y = NULL) +
  tema() + theme(axis.text.y = element_text(size = BASE - 1))

guardar(f6,
        labs(title = "Figure 6. Which baseline symptoms predict motor severity at 12 months",
             caption = env(paste(
               "All predictors are standardised and all models adjust for baseline motor",
               "score, age, sex, disease duration and MoCA, so the estimate refers to change.",
               "Pain and activities of daily living are the only two associated with the",
               "12-month motor score. Pain survives Benjamini-Hochberg correction",
               "(p = 0.030) but not Holm (p = 0.051), and this should temper the claim.",
               "BH, Benjamini-Hochberg adjusted p value."))),
        "figure6_discriminant", 9.0, 3.6)

cat(sprintf("\nDone. %d files in %s\n",
            length(list.files(PAPER_FIG)), PAPER_FIG))
