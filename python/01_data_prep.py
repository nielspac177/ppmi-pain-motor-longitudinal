#!/usr/bin/env python3
"""
Sofia thesis pipeline — Step 1: data prep
Pain (MDS-UPDRS I-1.9, NP1PAIN) x Motor severity (MDS-UPDRS III) in PPMI.

Builds two tidy outputs:
  data/tidy_v04.csv  — V04 cross-sectional (primary, ~1y from baseline, Aim 1-3)
  data/tidy_long.csv — BL..V12 long-format (Aim 4 longitudinal)
  data/flow_v04.csv  — STROBE flow numbers

Inclusion: COHORT == 1 (PD), subgroup not in {LRRK2, SNCA, PRKN, PINK1}.
GBA carriers retained (risk variant, not deterministic monogenic — per protocol decision 2026-05-18).
Exclusion: DBS previo o concurrente a la visita (sin look-ahead); NP1PAIN o updrs3_score ausentes.
"""
import os
import sys
import pandas as pd
from pathlib import Path

# Rutas relativas al repositorio: el script funciona en cualquier máquina.
REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "data"
OUT.mkdir(parents=True, exist_ok=True)

# Los CSV crudos de PPMI se buscan en data/ por defecto (ver data-access.md).
# PPMI_RAW_DIR permite apuntar a otra ubicación sin tocar el código, p. ej.:
#   PPMI_RAW_DIR=~/ruta/a/ppmi python3 python/01_data_prep.py
RAW = Path(os.environ.get("PPMI_RAW_DIR", str(OUT))).expanduser()

CURATED_PATH = RAW / "PPMI_Curated_Data_Cut_Public_20241211.csv"
PARTI_PQ_PATH = RAW / "MDS-UPDRS_Part_I_Patient_Questionnaire_04Nov2024.csv"
DBSYN_PATH = RAW / "PPMI_with_DBSYN.csv"


def check_inputs():
    """Falla pronto y con un mensaje útil si faltan los datos de PPMI."""
    faltan = [p for p in (CURATED_PATH, PARTI_PQ_PATH, DBSYN_PATH) if not p.exists()]
    if faltan:
        print(f"ERROR: faltan archivos de PPMI en {RAW}\n", file=sys.stderr)
        for p in faltan:
            print(f"  - {p.name}", file=sys.stderr)
        print(
            "\nEste repositorio no incluye datos de PPMI: el DUA prohíbe redistribuirlos."
            "\nVer data-access.md para obtenerlos, o usa PPMI_RAW_DIR para indicar dónde están.",
            file=sys.stderr,
        )
        sys.exit(1)

MONOGENIC_EXCLUDE = {
    "LRRK2", "SNCA", "PRKN", "PINK1",
    "LRRK2 + GBA", "LRRK2 + VPS35", "PRKN + RBD", "PARK7 + RBD",
}

KEEP_VISITS = ["BL", "V04", "V06", "V08", "V10", "V12"]
PRIMARY_VISIT = "V04"

CURATED_KEEP = [
    "PATNO", "EVENT_ID", "SITE", "COHORT", "subgroup", "PRIMDIAG", "NSD_Status",
    "visit_date", "YEAR", "age_at_visit", "SEX", "EDUCYRS", "race", "HISPLAT", "BMI",
    "agediag", "ageonset", "duration", "duration_yrs",
    "PDTRTMNT", "LEDD",
    "moca", "gds", "stai", "stai_state", "stai_trait", "ess",
    "scopa", "scopa_gi", "scopa_ur", "scopa_cv", "scopa_therm", "scopa_pm", "scopa_sex",
    "rem", "HIQ_RBD",
    "hy", "hy_on", "NHY", "NHY_ON",
    "updrs1_score", "updrs2_score", "updrs3_score", "updrs3_score_on",
    "updrs4_score", "updrs_totscore", "updrs_totscore_on",
]

PQ_KEEP = ["PATNO", "EVENT_ID", "NP1PAIN", "NP1FATG", "NP1SLPN", "NP1SLPD",
           "NP1URIN", "NP1CNST", "NP1LTHD"]

def load_data():
    print("Loading PPMI curated...")
    cur = pd.read_csv(CURATED_PATH, low_memory=False, usecols=lambda c: c in CURATED_KEEP)
    print(f"  curated rows={len(cur)}, cols={cur.shape[1]}")

    print("Loading MDS-UPDRS Part I Patient Questionnaire...")
    pq = pd.read_csv(PARTI_PQ_PATH, low_memory=False, usecols=lambda c: c in PQ_KEEP)
    print(f"  PQ rows={len(pq)}")

    print("Loading DBS-yn flag...")
    dbs = pd.read_csv(DBSYN_PATH, low_memory=False)
    if "DBSYN" not in dbs.columns:
        raise RuntimeError("PPMI_with_DBSYN.csv missing DBSYN column")

    # El criterio de exclusion del protocolo es DBS *previo* a la visita.
    # Marcar a todo el que alguna vez reciba DBS (incluso 5 anios despues) seria
    # condicionar sobre el futuro (look-ahead bias): excluiria sistematicamente a
    # los pacientes que mas tarde progresan hasta ser candidatos quirurgicos.
    # Por eso se guarda la FECHA del primer registro con DBSYN==1 y la comparacion
    # con la fecha de la visita se hace en apply_eligibility().
    dbs = dbs.copy()
    dbs["dbs_dt"] = pd.to_datetime(dbs["INFODT_cur"], errors="coerce", format="%m/%d/%y")
    dbs_pt = (dbs.loc[dbs["DBSYN"] == 1]
                 .groupby("PATNO")["dbs_dt"].min()
                 .reset_index().rename(columns={"dbs_dt": "dbs_first_dt"}))
    print(f"  patients ever exposed to DBS: {len(dbs_pt)} "
          f"(la exclusion se aplica solo si la fecha precede a la visita)")
    return cur, pq, dbs_pt

def build_long(cur, pq, dbs_pt):
    df = cur.merge(pq, on=["PATNO", "EVENT_ID"], how="left")
    df = df.merge(dbs_pt, on="PATNO", how="left")

    df["visit_dt"] = pd.to_datetime(df["visit_date"], errors="coerce", format="%b-%y")
    # DBS *previo o concurrente* a la visita. NaT en dbs_first_dt => nunca expuesto.
    df["dbs_before_visit"] = (df["dbs_first_dt"].notna()
                              & (df["dbs_first_dt"] <= df["visit_dt"])).astype(int)

    df["pain_present"] = (df["NP1PAIN"] >= 1).astype("Int64")
    df["pain_present"] = df["pain_present"].where(df["NP1PAIN"].notna())

    df["age_yrs"]      = df["age_at_visit"]
    df["sex_male"]     = (df["SEX"].astype(str).str.upper().isin(["1", "M", "MALE"])).astype(int)
    df["sex"]          = df["SEX"]
    # Definicion del protocolo: "anios desde inicio de sintomas ... fecha de inicio vs.
    # fecha de visita". duration_yrs de PPMI es el tiempo desde el DIAGNOSTICO fijado en
    # la basal: no avanza entre visitas (1.30 anios en BL y 1.32 en V04), asi que usarlo
    # subestimaria la duracion real en ~3 anios. Se recalcula en cada visita.
    df["disease_yrs"]  = df["age_at_visit"] - df["ageonset"]
    df["dx_yrs_bl"]    = df["duration_yrs"]   # duracion desde el diagnostico (referencia)
    df["LEDD"]         = pd.to_numeric(df["LEDD"], errors="coerce")
    df["MoCA"]         = pd.to_numeric(df["moca"], errors="coerce")
    df["GDS"]          = pd.to_numeric(df["gds"], errors="coerce")
    df["STAI_total"]   = pd.to_numeric(df["stai"], errors="coerce")
    df["STAI_state"]   = pd.to_numeric(df["stai_state"], errors="coerce")
    df["STAI_trait"]   = pd.to_numeric(df["stai_trait"], errors="coerce")
    df["RBDSQ"]        = pd.to_numeric(df["rem"], errors="coerce")
    df["SCOPA_AUT"]    = pd.to_numeric(df["scopa"], errors="coerce")
    df["ESS"]          = pd.to_numeric(df["ess"], errors="coerce")
    df["BMI"]          = pd.to_numeric(df["BMI"], errors="coerce")
    df["HY"]           = pd.to_numeric(df["NHY"], errors="coerce")
    df["UPDRS3"]       = pd.to_numeric(df["updrs3_score"], errors="coerce")
    df["UPDRS3_on"]    = pd.to_numeric(df["updrs3_score_on"], errors="coerce")
    df["UPDRS1"]       = pd.to_numeric(df["updrs1_score"], errors="coerce")
    df["UPDRS2"]       = pd.to_numeric(df["updrs2_score"], errors="coerce")
    df["UPDRS_total"]  = pd.to_numeric(df["updrs_totscore"], errors="coerce")
    df["NP1FATG"]      = pd.to_numeric(df["NP1FATG"], errors="coerce")
    df["NP1SLPN"]      = pd.to_numeric(df["NP1SLPN"], errors="coerce")
    df["NP1SLPD"]      = pd.to_numeric(df["NP1SLPD"], errors="coerce")
    df["NP1PAIN"]      = pd.to_numeric(df["NP1PAIN"], errors="coerce")

    df["is_PD"]        = (df["COHORT"] == 1)
    df["is_sporadic_strict"] = ~df["subgroup"].isin(MONOGENIC_EXCLUDE)
    df["is_GBA"]       = df["subgroup"].astype(str).str.contains("GBA", na=False)

    return df

def apply_eligibility(df, visit_id):
    """Apply full STROBE flow for a given visit. Returns analysis frame + counts dict."""
    counts = {}
    counts["all_curated_rows"] = len(df)
    f = df[df["EVENT_ID"] == visit_id].copy()
    counts["at_visit"] = len(f)
    f = f[f["is_PD"]]
    counts["pd_cohort"] = len(f)
    f = f[f["is_sporadic_strict"]]
    counts["after_monogenic_exclusion"] = len(f)
    f = f[f["dbs_before_visit"] == 0]
    counts["after_dbs_exclusion"] = len(f)
    f = f[f["NP1PAIN"].notna()]
    counts["after_pain_complete"] = len(f)
    f = f[f["UPDRS3"].notna()]
    counts["after_motor_complete"] = len(f)
    return f, counts

def main():
    check_inputs()
    cur, pq, dbs_pt = load_data()
    long_df = build_long(cur, pq, dbs_pt)

    long_keep = long_df[long_df["EVENT_ID"].isin(KEEP_VISITS)].copy()
    long_keep = long_keep[long_keep["is_PD"] & long_keep["is_sporadic_strict"] & (long_keep["dbs_before_visit"] == 0)]
    long_out_cols = [
        "PATNO", "EVENT_ID", "visit_date", "YEAR", "age_yrs", "sex_male", "EDUCYRS",
        "BMI", "disease_yrs", "dx_yrs_bl", "subgroup", "is_GBA",
        "LEDD", "PDTRTMNT", "MoCA",
        "NP1PAIN", "pain_present",
        "GDS", "STAI_total", "STAI_state", "STAI_trait", "RBDSQ", "ESS",
        "SCOPA_AUT", "scopa_gi", "scopa_ur", "scopa_cv", "scopa_therm", "scopa_pm", "scopa_sex",
        "HY", "NHY_ON",
        "UPDRS1", "UPDRS2", "UPDRS3", "UPDRS3_on", "UPDRS_total",
        "NP1FATG", "NP1SLPN", "NP1SLPD",
    ]
    long_out_cols = [c for c in long_out_cols if c in long_keep.columns]
    long_keep[long_out_cols].to_csv(OUT / "tidy_long.csv", index=False)
    print(f"\nWrote {OUT/'tidy_long.csv'}: rows={len(long_keep)}")

    primary, counts = apply_eligibility(long_df, PRIMARY_VISIT)
    primary[long_out_cols].to_csv(OUT / "tidy_v04.csv", index=False)
    print(f"Wrote {OUT/'tidy_v04.csv'}: rows={len(primary)}")

    flow_df = pd.DataFrame({"step": list(counts.keys()), "n": list(counts.values())})
    flow_df.to_csv(OUT / "flow_v04.csv", index=False)
    print(f"Wrote {OUT/'flow_v04.csv'}")
    print("\nSTROBE flow at V04:")
    print(flow_df.to_string(index=False))

    print("\nPrimary V04 analytic sample — key descriptives:")
    print(f"  N = {len(primary)}")
    print(f"  Age (mean ± SD): {primary['age_yrs'].mean():.1f} ± {primary['age_yrs'].std():.1f}")
    print(f"  Sex male (%): {primary['sex_male'].mean()*100:.1f}")
    print(f"  Disease duration yrs (mean ± SD): {primary['disease_yrs'].mean():.2f} ± {primary['disease_yrs'].std():.2f}")
    print(f"  NP1PAIN distribution:")
    print(primary["NP1PAIN"].value_counts().sort_index().to_string())
    print(f"  UPDRS-III (mean ± SD): {primary['UPDRS3'].mean():.1f} ± {primary['UPDRS3'].std():.1f}")
    print(f"  LEDD non-missing: {primary['LEDD'].notna().sum()}/{len(primary)} ({primary['LEDD'].notna().mean()*100:.0f}%)")
    print(f"  GDS non-missing: {primary['GDS'].notna().sum()}/{len(primary)} ({primary['GDS'].notna().mean()*100:.0f}%)")
    print(f"  STAI non-missing: {primary['STAI_total'].notna().sum()}/{len(primary)} ({primary['STAI_total'].notna().mean()*100:.0f}%)")
    print(f"  RBDSQ non-missing: {primary['RBDSQ'].notna().sum()}/{len(primary)} ({primary['RBDSQ'].notna().mean()*100:.0f}%)")
    print(f"  MoCA non-missing: {primary['MoCA'].notna().sum()}/{len(primary)} ({primary['MoCA'].notna().mean()*100:.0f}%)")

if __name__ == "__main__":
    main()
