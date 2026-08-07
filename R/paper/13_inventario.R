#!/usr/bin/env Rscript
# =============================================================================
# ARTICULO — Inventario completo de contrastes de hipotesis
#
# POR QUE EXISTE. El articulo aplica correccion por multiplicidad dentro de tres
# familias (los siete sintomas de la prueba discriminante, la rejilla de ocho
# contrastes de fenotipo y los cinco dominios motores) y no fuera de ellas. Con
# mas de doscientos valores p exportados, decir en Fortalezas que "la
# multiplicidad se trata explicitamente" seria inexacto si no se declara el
# denominador.
#
# Este script cuenta TODOS los valores p que el pipeline escribe a disco y los
# clasifica en tres categorias declaradas de antemano:
#
#   primario     el contraste que responde a la pregunta del articulo
#   sensibilidad variantes preespecificadas del primario, para robustez
#   exploratorio todo lo demas, incluidos los contrastes de refutacion
#
# El lenguaje de significacion sin matizar se reserva a la categoria primaria.
#
# Ejecutar:  Rscript R/paper/13_inventario.R
# =============================================================================

source(file.path(Sys.getenv("TESIS_ROOT", unset = getwd()), "R", "paper", "00_comun.R"))

titulo("INVENTARIO DE CONTRASTES")

archivos <- list.files(PAPER_TAB, pattern = "\\.csv$", full.names = TRUE)
# La salida del propio inventario tiene una columna n_p que el patron de busqueda
# capturaria como si fueran contrastes. Se excluye para no contarse a si mismo.
archivos <- archivos[!grepl("t13_inventario", basename(archivos))]

# Clasificacion declarada. Cualquier tabla no listada cae en exploratorio, que es
# la categoria conservadora: obliga a justificar la promocion, no la degradacion.
PRIMARIOS <- c(
  "t01_correlacion_rasgo_libre.csv",   # la correlacion de rasgo, modelo primario
  "t01_direccionalidad_sem.csv",       # los rezagos cruzados
  "t04_mixto.csv",                     # nivel frente a pendiente
  "t03_multiplicidad.csv"              # interaccion preespecificada de fenotipo
)
SENSIBILIDAD <- c(
  "t01_direccionalidad_rezagos.csv", "t01_correlacion_rasgo.csv",
  "t04_mixto_ipcw.csv", "t04_lord.csv", "t04_horizontes.csv",
  "t03_sensibilidad_regla_cero.csv", "t03_estratificado.csv",
  "t03_interaccion.csv", "t03_modificador_continuo.csv",
  "t05_sintesis_msm.csv", "t05_dolor_a_ledd.csv", "t05_ledd_a_dolor.csv",
  "t09_dominios_entre.csv", "t09_dominios_diferencial.csv"
)

contar_p <- function(f) {
  x <- suppressWarnings(read_csv(f, show_col_types = FALSE, progress = FALSE))
  # Solo la p CRUDA. Las columnas p_holm y p_bh son la misma familia de
  # contrastes ya corregida: contarlas triplicaria el denominador.
  # Se cuentan las p CRUDAS bajo cualquier nombre (p, p_rasgo, p_sintoma_a_motor),
  # pero NO las ya corregidas (p_holm, p_bh), que son la misma familia.
  cols <- names(x)[grepl("^p$|^pvalue$|^p_", names(x)) &
                     !grepl("holm|bh|_bh$", names(x))]
  if (!length(cols)) return(NULL)
  vals <- unlist(lapply(cols, function(cc) suppressWarnings(as.numeric(x[[cc]]))))
  vals <- vals[is.finite(vals)]
  if (!length(vals)) return(NULL)
  base <- basename(f)
  tibble(tabla = base,
         categoria = if (base %in% PRIMARIOS) "primario"
                     else if (base %in% SENSIBILIDAD) "sensibilidad"
                     else "exploratorio",
         n_p = length(vals),
         n_sig = sum(vals < ALPHA))
}

inv <- map_dfr(archivos, contar_p) |> arrange(categoria, desc(n_p))

subtitulo("Contrastes por tabla")
print(as.data.frame(inv), right = FALSE)

resumen <- inv |>
  group_by(categoria) |>
  summarise(tablas = n(), contrastes = sum(n_p), significativos = sum(n_sig),
            .groups = "drop") |>
  mutate(pct_sig = 100 * significativos / contrastes)

subtitulo("Resumen por categoria")
print(as.data.frame(resumen), digits = 3)

total <- sum(inv$n_p)
esperados <- total * ALPHA
cat(sprintf("\n  TOTAL de contrastes exportados: %d\n", total))
cat(sprintf("  Significativos observados     : %d\n", sum(inv$n_sig)))
cat(sprintf("  Esperados bajo el nulo global : %.0f\n", esperados))
cat("\n  LECTURA. Las tres categorias no son intercambiables y no procede una\n",
    "  correccion global: la mayor parte de los contrastes exploratorios son\n",
    "  intentos deliberados de REFUTAR un resultado, donde el error que importa\n",
    "  es el de tipo II y corregir lo agravaria. Lo que si procede, y es lo que\n",
    "  hace el articulo, es declarar el denominador y reservar el lenguaje de\n",
    "  significacion sin matizar a la categoria primaria.\n", sep = "")

guardar_tabla(inv, "t13_inventario_contrastes.csv")
guardar_tabla(resumen, "t13_inventario_resumen.csv")

cat("\n\nListo: R/paper/13_inventario.R\n")
