#!/usr/bin/env Rscript
# =============================================================================
# ARTICULO — Compositor: sustituye cada {{clave}} del manuscrito por su cifra.
#
# ABORTA si el texto usa un marcador que no existe en cifras.json. Es la misma
# salvaguarda que el generador de la tesis aplica a las citas, y existe por la
# misma razon: una cifra tecleada a mano acaba divergiendo de su modelo.
#
# Tambien AVISA de las cifras exportadas que el texto no usa, porque suelen
# indicar una frase que se reescribio y dejo la cifra huerfana.
#
# Ejecutar:  Rscript R/paper/08_componer.R
# =============================================================================

source(file.path(Sys.getenv("TESIS_ROOT", unset = getwd()), "R", "paper", "00_comun.R"))
suppressPackageStartupMessages({ library(jsonlite) })

titulo("COMPONIENDO EL MANUSCRITO")

ENTRADA <- file.path(ROOT, "manuscript", "paper.md")
SALIDA <- file.path(ROOT, "manuscript", "paper-compuesto.md")
CIFRAS <- file.path(ROOT, "outputs", "paper", "cifras.json")

if (!file.exists(ENTRADA)) stop("No existe el manuscrito: ", ENTRADA)
if (!file.exists(CIFRAS)) stop("No existen las cifras. Ejecuta antes R/paper/07_cifras.R")

texto <- readLines(ENTRADA, warn = FALSE)
cifras <- fromJSON(CIFRAS, simplifyVector = FALSE)

completo <- paste(texto, collapse = "\n")
usados <- unique(unlist(regmatches(completo, gregexpr("\\{\\{[a-zA-Z0-9_]+\\}\\}", completo))))
usados <- gsub("[{}]", "", usados)

faltan <- setdiff(usados, names(cifras))
if (length(faltan)) {
  cat("\nERROR. El manuscrito usa marcadores que no existen en cifras.json:\n")
  for (k in faltan) cat("  {{", k, "}}\n", sep = "")
  stop("Marcadores sin cifra: ", length(faltan),
       ". Anadelos en R/paper/07_cifras.R o corrige el texto.")
}

sobran <- setdiff(names(cifras), usados)

for (k in usados) {
  completo <- gsub(paste0("\\{\\{", k, "\\}\\}"), cifras[[k]], completo, perl = TRUE)
}

restantes <- unlist(regmatches(completo, gregexpr("\\{\\{[^}]*\\}\\}", completo)))
if (length(restantes)) stop("Quedaron marcadores sin sustituir: ",
                            paste(unique(restantes), collapse = ", "))

writeLines(completo, SALIDA)

cat(sprintf("\n  marcadores en el texto : %d\n", length(usados)))
cat(sprintf("  cifras exportadas      : %d\n", length(cifras)))
cat(sprintf("  cifras sin usar        : %d\n", length(sobran)))
cat(sprintf("  palabras del manuscrito: %d\n",
            lengths(gregexpr("\\S+", paste(completo, collapse = " ")))))
cat(sprintf("\n  -> %s\n", SALIDA))

# ---------------------------------------------------------------------------
# Comprobaciones de estilo que el asesor detecta.
# ---------------------------------------------------------------------------
subtitulo("Comprobaciones de estilo")

rayas <- lengths(gregexpr("—", completo))
rayas <- if (rayas == 1 && !grepl("—", completo)) 0 else rayas
cat(sprintf("  rayas tipograficas (em dash): %d\n", rayas))

negritas <- lengths(gregexpr("\\*\\*[^*]+\\*\\*", completo))
negritas <- if (negritas == 1 && !grepl("\\*\\*", completo)) 0 else negritas
cat(sprintf("  tramos en negrita            : %d\n", negritas))

# Longitud de parrafo. El patron que delata la escritura automatica es la
# UNIFORMIDAD: un coeficiente de variacion por debajo de 0,20. La variedad es
# senal de escritura humana, de modo que aqui un CV alto es bueno.
parrafos <- strsplit(completo, "\n\\s*\n")[[1]]
parrafos <- parrafos[!grepl("^\\s*[#|\\-]", parrafos)]
largos <- lengths(gregexpr("\\S+", parrafos))
largos <- largos[largos > 15]
cv <- sd(largos) / mean(largos)
cat(sprintf("  parrafos de prosa            : %d\n", length(largos)))
cat(sprintf("  palabras por parrafo         : %.0f (rango %d a %d)\n",
            mean(largos), min(largos), max(largos)))
cat(sprintf("  coeficiente de variacion     : %.2f %s\n", cv,
            if (cv < 0.20) "AVISO: demasiado uniforme" else "(variado, correcto)"))

if (rayas > 0) cat("\n  AVISO: hay rayas tipograficas. Sustituyelas.\n")
if (negritas > 0) cat("  NOTA: las negritas del resumen son estructurales, no de enfasis.\n")

cat("\nListo: R/paper/08_componer.R\n")
