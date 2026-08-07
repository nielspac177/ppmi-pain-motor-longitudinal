.PHONY: help synth analisis figuras cifras texto test paper clean

R  := Rscript
PY := python3

help:
	@echo "Pain and motor severity in early Parkinson disease (PPMI)"
	@echo ""
	@echo "  make synth      Regenerate the synthetic data (no PPMI needed)"
	@echo "  make analisis   Run the five analyses"
	@echo "  make figuras    Build the six figures"
	@echo "  make cifras     Export every number used in the manuscript"
	@echo "  make texto      Compose the manuscript, substituting placeholders"
	@echo "  make test       Regression tests"
	@echo "  make paper      Everything above, in order"
	@echo ""
	@echo "With real PPMI data, set PPMI_RAW_DIR and run the two prep scripts"
	@echo "first; see README.md. To run against the synthetic data instead:"
	@echo "  DATOS_DIR=\$$PWD/data-synth make analisis"

synth:
	$(PY) python/00_make_synthetic.py

analisis:
	$(R) R/paper/01_direccionalidad.R
	$(R) R/paper/02_refutacion_riclpm.R
	$(R) R/paper/03_fenotipo.R
	$(R) R/paper/04_longitudinal.R
	$(R) R/paper/05_msm_ledd.R

figuras:
	$(R) R/paper/06_figuras.R

cifras:
	$(R) R/paper/07_cifras.R

texto: cifras
	$(R) R/paper/08_componer.R

test:
	$(R) tests/test_paper.R

paper: analisis figuras texto test

clean:
	rm -f outputs/paper/tables/*.csv outputs/paper/figures/* outputs/paper/cifras.json
	@echo "Outputs removed. Nothing in data/ was touched."
