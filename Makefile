.PHONY: help all synth prep analisis figuras dags tesis test clean check-data check-fenotipo \
        cohortes biomarcadores analgesicos prep-paper paper-dags \
        fenotipo paper paper-analisis paper-figuras paper-cifras paper-texto test-paper

R      := Rscript
PY     := python3
DATA   := data
SYNTH  := data-synth

help:
	@echo "Tesis — Dolor y severidad motora en la enfermedad de Parkinson (PPMI)"
	@echo ""
	@echo "  make all       Pipeline completo sobre los datos reales de PPMI"
	@echo "  make synth     Regenera los datos sintéticos"
	@echo "  make prep      Solo la preparación de datos"
	@echo "  make analisis  Solo el análisis (los 3 objetivos específicos)"
	@echo "  make figuras   Solo las figuras"
	@echo "  make dags      Solo los grafos causales (TikZ)"
	@echo "  make cifras    Cifras y tablas ya formateadas para el documento"
	@echo "  make tesis     Genera el documento Word en formato UCSUR"
	@echo "  make test      Pruebas de regresión sobre los resultados"
	@echo "  make clean     Borra las salidas (no los datos)"
	@echo ""
	@echo "ARTÍCULO longitudinal (en inglés), independiente de la tesis:"
	@echo "  make fenotipo       Construye el fenotipo TD/PIGD de Stebbins"
	@echo "  make paper          Pipeline completo del artículo"
	@echo "  make paper-analisis Los cuatro análisis del artículo"
	@echo "  make paper-figuras  Las seis figuras en inglés"
	@echo "  make paper-cifras   Exporta cifras.json"
	@echo "  make paper-texto    Compone el manuscrito sustituyendo los marcadores"
	@echo "  make test-paper     Pruebas de regresión del artículo"
	@echo ""
	@echo "Los datos de PPMI no vienen en el repositorio — ver data-access.md"

check-data:
	@test -f $(DATA)/tidy_v04.csv || { \
		echo "ERROR: falta $(DATA)/tidy_v04.csv"; \
		echo "Ejecuta primero 'make prep', y lee data-access.md para obtener los datos de PPMI."; \
		exit 1; }

all: prep analisis figuras cifras tesis test

prep:
	$(PY) python/01_data_prep.py

analisis: check-data
	$(R) R/02_analisis_principal.R

figuras: check-data dags
	$(R) R/10_figuras.R

# Los DAGs se escriben una vez en Mermaid (docs/dags-causales.md, fuente de
# verdad versionable) y se tipografian en TikZ para la figura del documento.
dags:
	cd figuras-tikz && lualatex -interaction=nonstopmode dags_figura.tex >/dev/null
	cd figuras-tikz && pdftoppm -png -r 320 dags_figura.pdf ../outputs/figures/figura6_dags_doc
	mv outputs/figures/figura6_dags_doc-1.png outputs/figures/figura6_dags_doc.png
	cp figuras-tikz/dags_figura.pdf outputs/figures/figura6_dags.pdf
	rm -f figuras-tikz/*.aux figuras-tikz/*.log

cifras: check-data
	$(R) R/11_cifras_para_texto.R
	$(R) R/12_tablas_documento.R

tesis: figuras cifras
	npm install --silent
	node docx/tesis.js

# -----------------------------------------------------------------------------
# ARTÍCULO longitudinal. No toca el pipeline de la tesis, que está cerrado y
# reproduce byte a byte: el fenotipo se construye en un archivo aparte y se une
# en R en tiempo de análisis.
# -----------------------------------------------------------------------------
check-fenotipo:
	@test -f $(DATA)/stebbins.csv || { \
		echo "ERROR: falta $(DATA)/stebbins.csv"; \
		echo "Ejecuta primero 'make fenotipo'."; \
		exit 1; }

fenotipo:
	$(PY) python/02_stebbins_phenotype.py

cohortes:
	$(PY) python/03_cohortes_control.py

biomarcadores:
	$(PY) python/04_biomarcadores.py

analgesicos:
	$(PY) python/05_analgesicos.py

prep-paper: fenotipo cohortes biomarcadores analgesicos

paper-analisis: check-data check-fenotipo
	$(R) R/paper/01_direccionalidad.R
	$(R) R/paper/02_refutacion_riclpm.R
	$(R) R/paper/03_fenotipo.R
	$(R) R/paper/04_longitudinal.R
	$(R) R/paper/05_msm_ledd.R
	$(R) R/paper/09_dominios.R
	$(R) R/paper/10_controles_negativos.R
	$(R) R/paper/11_hipotesis.R
	$(R) R/paper/12_flujo.R
	$(R) R/paper/14_clinicos.R
	$(R) R/paper/15_estilo_de_reporte.R
	$(R) R/paper/13_inventario.R

paper-figuras: check-data paper-dags
	$(R) R/paper/06_figuras.R

# Los DAGs se escriben una vez en Mermaid (docs/dags-longitudinales.md, fuente
# de verdad versionable) y se tipografian en TikZ para la figura del manuscrito.
paper-dags:
	cd figuras-tikz && lualatex -interaction=nonstopmode dags_longitudinales.tex >/dev/null
	cd figuras-tikz && pdftoppm -png -r 200 dags_longitudinales.pdf ../outputs/paper/figures/figure7_dags
	mv outputs/paper/figures/figure7_dags-1.png outputs/paper/figures/figure7_dags.png
	cp figuras-tikz/dags_longitudinales.pdf outputs/paper/figures/figure7_dags.pdf
	rm -f figuras-tikz/*.aux figuras-tikz/*.log

paper-cifras: check-data
	$(R) R/paper/07_cifras.R

paper-texto: paper-cifras
	$(R) R/paper/08_componer.R

test-paper:
	$(R) tests/test_paper.R

paper: prep-paper paper-analisis paper-figuras paper-texto test-paper

synth:
	$(PY) python/00_make_synthetic.py

test:
	$(R) tests/test_resultados.R

clean:
	rm -f outputs/tables/*.csv outputs/figures/* outputs/models/*.rds outputs/logs/*
	@echo "Salidas borradas. Los datos en $(DATA)/ no se tocaron."
