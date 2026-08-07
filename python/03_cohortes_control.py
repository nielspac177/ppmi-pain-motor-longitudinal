#!/usr/bin/env python3
"""
Paper pipeline — Step 3: negative-control and prodromal cohorts.

Builds two extra long-format tables with the SAME columns as data/tidy_long.csv,
so the identical models can be refitted on them without touching the code:

  data/tidy_long_controles.csv   PPMI healthy controls (COHORT == 2)
  data/tidy_long_prodromo.csv    PPMI prodromal cohort (COHORT == 4: hyposmia, RBD)

Why these two cohorts answer specific objections:

  HEALTHY CONTROLS are the decisive negative control for the paper's central
  claim. The paper reports a stable between-person correlation between pain and
  MDS-UPDRS III. The strongest deflationary reading is that this reflects a
  generic "burden" factor plus shared method variance rather than anything about
  Parkinson disease. If the same correlation appears in people without the
  disease, that reading wins and the shared-substrate interpretation collapses.
  A reviewer will ask for this, so it is run before submission rather than after.

  THE PRODROMAL COHORT addresses the objection our design cannot otherwise meet:
  that pain does precede motor disease, but earlier than our observation window
  opens. If pain marks something that precedes motor disease, it should already
  covary with subclinical motor signs before diagnosis.

Monogenic carriers are excluded from both, matching the main sample definition
(ADR 0003). DBS exclusion is not applied: it is irrelevant in these cohorts and
applying it would introduce a criterion that never fires.
"""
import os
import sys
import pandas as pd
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "data"
OUT.mkdir(parents=True, exist_ok=True)

RAW = Path(os.environ.get("PPMI_RAW_DIR", str(OUT))).expanduser()
CURATED_PATH = RAW / "PPMI_Curated_Data_Cut_Public_20241211.csv"
PARTI_PQ_PATH = RAW / "MDS-UPDRS_Part_I_Patient_Questionnaire_04Nov2024.csv"

MONOGENIC_EXCLUDE = {
    "LRRK2", "SNCA", "PRKN", "PINK1",
    "LRRK2 + GBA", "LRRK2 + VPS35", "PRKN + RBD", "PARK7 + RBD",
}
KEEP_VISITS = ["BL", "V04", "V06", "V08", "V10", "V12"]

COHORTES = {
    "controles": (2, "Healthy controls"),
    "prodromo": (4, "Prodromal (hyposmia, RBD)"),
}

CURATED_KEEP = [
    "PATNO", "EVENT_ID", "COHORT", "subgroup", "visit_date", "YEAR",
    "age_at_visit", "SEX", "EDUCYRS", "BMI", "ageonset", "duration_yrs",
    "PDTRTMNT", "LEDD", "moca", "gds", "stai", "stai_state", "stai_trait",
    "ess", "scopa", "scopa_gi", "scopa_ur", "scopa_cv", "scopa_therm",
    "scopa_pm", "scopa_sex", "rem", "hy", "NHY", "NHY_ON",
    "updrs1_score", "updrs2_score", "updrs3_score", "updrs3_score_on",
    "updrs_totscore",
]
PQ_KEEP = ["PATNO", "EVENT_ID", "NP1PAIN", "NP1FATG", "NP1SLPN", "NP1SLPD"]

# Mismo orden de columnas que data/tidy_long.csv, para que cargar_largo() y los
# modelos del articulo funcionen sin ningun cambio.
OUT_COLS = [
    "PATNO", "EVENT_ID", "visit_date", "YEAR", "age_yrs", "sex_male", "EDUCYRS",
    "BMI", "disease_yrs", "dx_yrs_bl", "subgroup", "is_GBA",
    "LEDD", "PDTRTMNT", "MoCA", "NP1PAIN", "pain_present",
    "GDS", "STAI_total", "STAI_state", "STAI_trait", "RBDSQ", "ESS",
    "SCOPA_AUT", "scopa_gi", "scopa_ur", "scopa_cv", "scopa_therm",
    "scopa_pm", "scopa_sex", "HY", "NHY_ON",
    "UPDRS1", "UPDRS2", "UPDRS3", "UPDRS3_on", "UPDRS_total",
    "NP1FATG", "NP1SLPN", "NP1SLPD",
]


def check_inputs():
    faltan = [p for p in (CURATED_PATH, PARTI_PQ_PATH) if not p.exists()]
    if faltan:
        print(f"ERROR: faltan archivos de PPMI en {RAW}", file=sys.stderr)
        for p in faltan:
            print(f"  - {p.name}", file=sys.stderr)
        sys.exit(1)


def build(cur, pq, cohort_code):
    df = cur[cur["COHORT"] == cohort_code].copy()
    df = df[~df["subgroup"].isin(MONOGENIC_EXCLUDE)]
    df = df[df["EVENT_ID"].isin(KEEP_VISITS)]
    df = df.merge(pq, on=["PATNO", "EVENT_ID"], how="left")

    df["age_yrs"] = df["age_at_visit"]
    df["sex_male"] = (df["SEX"].astype(str).str.upper()
                      .isin(["1", "M", "MALE"])).astype(int)
    # En controles y prodromicos no hay fecha de inicio motor, de modo que la
    # "duracion de enfermedad" no esta definida. Se deja ausente en lugar de
    # imputar un cero, que el modelo leeria como un dato real.
    df["disease_yrs"] = df["age_at_visit"] - df["ageonset"]
    df["dx_yrs_bl"] = df["duration_yrs"]
    df["is_GBA"] = df["subgroup"].astype(str).str.contains("GBA", na=False)

    ren = {
        "moca": "MoCA", "gds": "GDS", "stai": "STAI_total",
        "stai_state": "STAI_state", "stai_trait": "STAI_trait",
        "rem": "RBDSQ", "ess": "ESS", "scopa": "SCOPA_AUT",
        "NHY": "HY", "updrs1_score": "UPDRS1", "updrs2_score": "UPDRS2",
        "updrs3_score": "UPDRS3", "updrs3_score_on": "UPDRS3_on",
        "updrs_totscore": "UPDRS_total",
    }
    df = df.rename(columns=ren)
    for c in ren.values():
        df[c] = pd.to_numeric(df[c], errors="coerce")
    df["NP1PAIN"] = pd.to_numeric(df["NP1PAIN"], errors="coerce")
    df["pain_present"] = (df["NP1PAIN"] >= 1).astype("Int64").where(df["NP1PAIN"].notna())

    for c in OUT_COLS:
        if c not in df.columns:
            df[c] = pd.NA
    return df[OUT_COLS]


def main():
    check_inputs()
    cur = pd.read_csv(CURATED_PATH, low_memory=False,
                      usecols=lambda c: c in CURATED_KEEP)
    pq = pd.read_csv(PARTI_PQ_PATH, low_memory=False,
                     usecols=lambda c: c in PQ_KEEP)

    for nombre, (codigo, etiqueta) in COHORTES.items():
        out = build(cur, pq, codigo)
        ruta = OUT / f"tidy_long_{nombre}.csv"
        out.to_csv(ruta, index=False)
        con_ambos = out[out["NP1PAIN"].notna() & out["UPDRS3"].notna()]
        print(f"\n{etiqueta} (COHORT == {codigo})")
        print(f"  {ruta.name}: filas={len(out)}, pacientes={out['PATNO'].nunique()}")
        print(f"  con dolor Y motor: filas={len(con_ambos)}, "
              f"pacientes={con_ambos['PATNO'].nunique()}")
        print("  por visita:")
        print(con_ambos.groupby("EVENT_ID").size()
              .reindex(KEEP_VISITS).fillna(0).astype(int).to_string())
        print(f"  MDS-UPDRS III medio: {con_ambos['UPDRS3'].mean():.2f} "
              f"(DE {con_ambos['UPDRS3'].std():.2f})")
        print(f"  con dolor presente : {100 * con_ambos['pain_present'].mean():.1f} %")


if __name__ == "__main__":
    main()
