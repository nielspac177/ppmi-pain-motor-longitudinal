# Pain and motor severity in early Parkinson disease

Analysis code for a longitudinal study of pain and motor severity in the
Parkinson's Progression Markers Initiative (PPMI), covering six annual
assessments from baseline through year 5.

**Headline finding.** Pain and motor severity covary as stable characteristics of
the patient rather than one preceding the other. Once stable between-person
differences are separated from within-person change, neither direction of
temporal precedence survives, and the reciprocal causation a conventional
cross-lagged model reports on the same data is an artefact of that conflation.

Five converging analyses indicate the covariation is not specific to pain: a
negative control in which pain predicts later depression, a depression exposure
reproducing the pain result, a single general factor leaving no residual
association, an equal correlation in healthy controls, and other non-motor items
covarying with motor severity as strongly or more. The paper reports it as an
index of general early non-motor burden rather than a pain-specific finding.

The manuscript is in [`manuscript/`](manuscript/). Every number in it is
substituted from [`outputs/paper/cifras.json`](outputs/paper/cifras.json), which
R generates from the fitted models; the compositor aborts if the text uses a
placeholder that does not exist.

---

## No participant data in this repository, ever

The PPMI Data Use Agreement prohibits redistributing participant-level data. This
repository contains **code, aggregate results and figures only**. Continuous
integration verifies on every change that no versioned CSV carries a `PATNO`
column and that no raw PPMI file has been committed.

To reproduce the analysis you need your own PPMI account and your own signed
agreement. See [Reproducing](#reproducing) below.

`data-synth/` holds **simulated** data with the same column structure, calibrated
against published aggregate statistics and never against individual records. It
exists so that the pipeline can run end to end, and be reviewed by a third party,
without PPMI access. Results computed from it have no scientific meaning.

---

## What the analysis does

The design question is not whether pain and motor severity are associated, which
is well established, but whether one precedes the other. Three obstacles make
that hard, and the code addresses each with a separate estimator.

| Question | Estimator | Script |
| --- | --- | --- |
| Does either precede the other? | Random-intercept cross-lagged panel model, contrasted with the classic model | `01_direccionalidad.R` |
| Does the surviving path hold up? | Eight adversarial robustness checks, including two negative controls | `02_refutacion_riclpm.R` |
| Does motor phenotype modify it? | Stebbins TD/PIGD classification, pre-specified interaction plus strata | `03_fenotipo.R` |
| Level or slope, and what about dropout? | Mixed model plus weighted GEE with inverse probability of censoring weights | `04_longitudinal.R` |
| What about dopaminergic dose? | Marginal structural model with stabilised IPTW | `05_msm_ledd.R` |
| Which motor domain carries it? | Decomposition into five domains that sum to the total | `09_dominios.R` |
| Is it specific to the disease? | Same model refitted in healthy control and prodromal cohorts | `10_controles_negativos.R` |
| Eight mechanistic hypotheses | DAT-SPECT, general factor, ICC, CSF alpha-synuclein, GBA, limb gradient | `11_hipotesis.R` |
| Is the participant flow consistent? | All five populations derived from one place | `12_flujo.R` |
| How many tests were run? | Full inventory, classified primary / sensitivity / exploratory | `13_inventario.R` |
| Analgesics, sex, motor complications, other non-motor items | Four clinical analyses requested at peer review | `14_clinicos.R` |

The random-intercept model is the load-bearing piece. A conventional cross-lagged
panel model on these data reports significant paths in **both** directions, which
would support reciprocal causation. That pattern is what stable between-person
covariation produces when the model cannot separate it from within-person change.
Once separated, the motor-to-pain path vanishes and what remains is a stable
correlation between the two series across patients.

### Results that did not survive

Two findings we initially favoured were subjected to deliberate attempts at
refutation and did not hold. Both are reported as negative results rather than
quietly dropped:

- The **within-person pain-to-motor path** survived only 2 of 6 robustness
  specifications and only 1 of 5 waves, and the equality constraints producing it
  were formally rejected.
- The **phenotype effect modification** hypothesis failed. Pain is more common in
  the PIGD phenotype (adjusted ordinal OR 1.49), but the phenotype does not modify
  the association; no contrast survived correction for multiplicity, and the two
  nominally significant ones did not reappear when the classifier was rebuilt from
  either of its two item sources.

The reasoning is in [`adr/0008`](adr/0008-refutacion-y-preespecificacion.md).

---

## Reproducing

### With synthetic data, no PPMI account needed

```bash
python3 python/00_make_synthetic.py
DATOS_DIR=$PWD/data-synth Rscript R/paper/01_direccionalidad.R
DATOS_DIR=$PWD/data-synth Rscript R/paper/03_fenotipo.R
DATOS_DIR=$PWD/data-synth Rscript R/paper/04_longitudinal.R
```

This verifies the code runs. It does not reproduce the paper's numbers, and is
not meant to.

### With real PPMI data

Download from [ppmi-info.org](https://www.ppmi-info.org) after signing the Data
Use Agreement. You need:

```
PPMI_Curated_Data_Cut_Public_20241211.csv
MDS-UPDRS_Part_I_Patient_Questionnaire_04Nov2024.csv
MDS-UPDRS_Part_II__Patient_Questionnaire_04Nov2024.csv
MDS-UPDRS_Part_III_04Nov2024.csv
PPMI_with_DBSYN.csv
Concomitant_Medication_Log_04Nov2024.csv
```

Then:

```bash
export PPMI_RAW_DIR=/path/to/your/ppmi/files
make prep-paper   # analytic tables, phenotype, control cohorts, biomarkers, analgesics
make paper        # 14 analyses, figures, numbers, manuscript, tests
Rscript tests/test_paper.R   # 153 regression tests
```

Part II lives in a different directory in some PPMI exports; set
`PPMI_PART2_PATH` if the script cannot find it.

### Requirements

Python 3.11 with `pandas` and `numpy`. R 4.4 or later with `tidyverse`, `lavaan`,
`lme4`, `lmerTest`, `geepack`, `sandwich`, `lmtest`, `broom`, `EValue`,
`patchwork`, `jsonlite`, `MASS`.

---

## How this repository keeps itself honest

Four mechanical safeguards, each added after a specific failure:

1. **No number is typed by hand.** `R/paper/07_cifras.R` exports every figure
   used in the text; `R/paper/08_componer.R` substitutes them and aborts on any
   placeholder without a value. An earlier audit on the companion project found
   five different sample sizes circulating in drafts because they were typed.
2. **153 regression tests** recompute or re-read every published result and fail if
   it moves. When a method changes a number, the test fails, which is the point:
   the test and the decision record are updated together.
3. **Every decision that changed a result is recorded** in a dated architecture
   decision record in [`adr/`](adr/), including the ones that seemed obvious.
4. **Continuous integration checks for data leakage** on every change: no
   versioned CSV may carry a `PATNO` column, and no raw PPMI file may be
   committed.

### Independent review

`docs/04-prompt-para-revision-independiente.md` is a self-contained brief for a
reviewer with no prior involvement, listing what three internal rounds already
fixed so the work is not repeated, and what remains open. It is written in
Spanish, the project's working language.

### Decision records

| ADR | What it decides |
| --- | --- |
| [0003](adr/0003-definicion-de-la-muestra.md) | Sample definition; removing look-ahead bias in the deep brain stimulation exclusion |
| [0004](adr/0004-ajuste-por-estadio.md) | Whether Hoehn and Yahr stage is a confounder or a descendant of the outcome |
| [0005](adr/0005-cambio-de-modelo-primario.md) | Dropping Hoehn and Yahr from the primary model |
| [0006](adr/0006-resolucion-de-la-discrepancia-direccional.md) | Resolving a contradiction between two earlier directional analyses |
| [0007](adr/0007-regla-de-denominador-cero-de-stebbins.md) | The undefined case in the Stebbins ratio, affecting a fifth of the sample |
| [0008](adr/0008-refutacion-y-preespecificacion.md) | Refuting two favourable results; pre-specification and multiplicity |
| [0009](adr/0009-cambio-de-la-tesis-del-articulo.md) | Reframing the paper after the results |
| [0010](adr/0010-atricion-y-confusion-variable-en-el-tiempo.md) | Attrition weighting and time-varying confounding |
| [0011](adr/0011-el-mecanismo-no-es-dopaminergico-ni-especifico.md) | The covariation is not explained by dopaminergic loss, and specificity cannot be claimed |

The decision records are in Spanish, the working language of the project. The
manuscript, the figures and this README are in English.

---

## Relationship to the companion undergraduate thesis

This analysis grew out of a cross-sectional undergraduate thesis on the same
question, which is closed and reported separately. That work established a small
association at a single visit; this one asks whether the relationship has a
direction in time. The thesis pipeline is untouched by anything here and still
reproduces byte for byte, which is why the phenotype is built in a separate file
and merged at analysis time rather than added to the shared analytic table.

---

## Licence and citation

Code is released under the MIT Licence (see [LICENSE](LICENSE)). Data remain
governed by the PPMI Data Use Agreement.

Data used in the preparation of this article were obtained from the Parkinson's
Progression Markers Initiative database. For up-to-date information on the study,
visit [ppmi-info.org](https://www.ppmi-info.org). PPMI is sponsored and partially
funded by the Michael J. Fox Foundation for Parkinson's Research and funding
partners listed at [ppmi-info.org/about-ppmi/who-we-are/study-sponsors](https://www.ppmi-info.org/about-ppmi/who-we-are/study-sponsors).
