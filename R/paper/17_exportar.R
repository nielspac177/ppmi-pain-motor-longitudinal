#!/usr/bin/env Rscript
# =============================================================================
# ARTICULO — Exportacion a Word y a LaTeX
#
# El manuscrito vive en markdown porque es lo que permite sustituir las cifras
# desde los modelos y comprobar que no queda ningun marcador sin resolver. Pero
# ninguna revista acepta markdown, de modo que hace falta una salida en Word y
# otra en LaTeX, y las dos tienen que derivarse del MISMO fichero compuesto para
# que no puedan divergir del texto verificado.
#
# La fuente es manuscript/paper-compuesto.md, que ya trae las 463 cifras
# sustituidas. A el se le anaden las leyendas de figura, que R exporta desde las
# mismas anotaciones que dibuja, y una portada con los metadatos.
#
# NO se incrustan las figuras en el documento. Las revistas las piden como
# ficheros aparte y numerados, que es como estan en outputs/paper/figures.
#
# Ejecutar:  Rscript R/paper/17_exportar.R
# =============================================================================

source(file.path(Sys.getenv("TESIS_ROOT", unset = getwd()), "R", "paper", "00_comun.R"))

titulo("EXPORTACION A WORD Y LATEX")

SALIDA <- file.path(ROOT, "outputs", "paper", "submission")
dir.create(SALIDA, showWarnings = FALSE, recursive = TRUE)

hay <- function(x) nzchar(Sys.which(x))
for (h in c("pandoc")) if (!hay(h)) stop(sprintf("falta la herramienta: %s", h))

md <- file.path(ROOT, "manuscript", "paper-compuesto.md")
ley <- file.path(ROOT, "outputs", "paper", "leyendas.md")
if (!file.exists(md)) stop("falta el manuscrito compuesto: ejecuta 08_componer.R")
if (!file.exists(ley)) stop("faltan las leyendas: ejecuta 06_figuras.R")

texto <- readLines(md, warn = FALSE, encoding = "UTF-8")
leyendas <- readLines(ley, warn = FALSE, encoding = "UTF-8")

# Un marcador sin resolver en el compuesto significa que el compositor no se ha
# ejecutado despues del ultimo cambio. Exportarlo lo llevaria a Word y a LaTeX.
if (any(grepl("\\{\\{", texto)))
  stop("el manuscrito compuesto tiene marcadores sin sustituir")

# Las leyendas van ANTES de las referencias, que es donde las piden las revistas
# que numeran las citas al final.
i_ref <- grep("^## References", texto)
if (length(i_ref) != 1) stop("no se localiza una unica seccion de referencias")
completo <- c(texto[1:(i_ref - 1)], leyendas, "", texto[i_ref:length(texto)])

# El titulo del markdown pasa a metadatos para que Word y LaTeX lo compongan
# como portada en lugar de como un encabezado mas del cuerpo.
titulo_art <- sub("^# ", "", completo[1])
cuerpo <- completo[-1]

# Las reglas horizontales separan secciones al leer el markdown, pero en un
# manuscrito compuesto se imprimen como una raya suelta en mitad de la pagina.
# Solo se ve en el PDF.
cuerpo <- cuerpo[!grepl("^-{3,}\\s*$", cuerpo)]

yaml <- c("---",
  paste0("title: \"", gsub("\"", "\\\\\"", titulo_art), "\""),
  "author: \"Niels Pacheco-Barrios\"",
  "date: \"\"",
  "lang: en",
  "---", "")

fuente <- file.path(SALIDA, "manuscrito.md")
writeLines(c(yaml, cuerpo), fuente, useBytes = TRUE)
cat(sprintf("\n  fuente unificada: %s (%d lineas)\n", basename(fuente),
            length(cuerpo)))

comun <- c("--from", "markdown+superscript+subscript", "--standalone",
           "--wrap=preserve")

# ------------------------------------------------------------------- WORD ---
docx <- file.path(SALIDA, "manuscrito.docx")
r <- system2("pandoc", c(shQuote(fuente), comun, "--to", "docx",
                         "--output", shQuote(docx)), stdout = TRUE, stderr = TRUE)
if (!file.exists(docx)) stop(paste(r, collapse = "\n"))
cat(sprintf("  Word           : %s (%.0f KB)\n", basename(docx),
            file.size(docx) / 1024))

# ------------------------------------------------------------------ LATEX ---
# Doble espacio y numeracion de lineas porque es lo que piden casi todas las
# revistas clinicas para revision. La clase es article y no una plantilla de
# revista concreta, porque la revista objetivo aun no esta decidida.
cabecera <- file.path(SALIDA, "cabecera.tex")
writeLines(c(
  "\\usepackage[margin=2.5cm]{geometry}",
  "\\usepackage{setspace}",
  "\\doublespacing",
  "\\usepackage[left]{lineno}",
  "\\linenumbers",
  "\\usepackage{microtype}",
  "\\usepackage[hidelinks]{hyperref}",
  "\\setlength{\\emergencystretch}{3em}",
  "\\raggedright"), cabecera)

tex <- file.path(SALIDA, "manuscrito.tex")
r <- system2("pandoc", c(shQuote(fuente), comun, "--to", "latex",
                         "--include-in-header", shQuote(cabecera),
                         "--variable", "documentclass=article",
                         "--variable", "fontsize=12pt",
                         "--output", shQuote(tex)), stdout = TRUE, stderr = TRUE)
if (!file.exists(tex)) stop(paste(r, collapse = "\n"))
cat(sprintf("  LaTeX          : %s (%.0f KB)\n", basename(tex),
            file.size(tex) / 1024))

# -------------------------------------------------------------------- PDF ---
if (hay("latexmk")) {
  system2("latexmk", c("-pdf", "-quiet", "-interaction=nonstopmode",
                       paste0("-outdir=", shQuote(SALIDA)), shQuote(tex)),
          stdout = FALSE, stderr = FALSE)
  pdf <- file.path(SALIDA, "manuscrito.pdf")
  if (file.exists(pdf)) {
    cat(sprintf("  PDF            : %s (%.0f KB)\n", basename(pdf),
                file.size(pdf) / 1024))
  } else {
    cat("  PDF            : NO se genero, revisa manuscrito.log\n")
  }
  unlink(list.files(SALIDA, pattern = "\\.(aux|fls|fdb_latexmk|out|log)$",
                    full.names = TRUE))
} else {
  cat("  PDF            : latexmk no disponible, solo .tex\n")
}

cat("\n\nListo: R/paper/17_exportar.R\n")
