#!/usr/bin/env python3
"""
Paper pipeline — Step 4: biomarkers for the hypothesis tests.

Builds data/biomarcadores.csv, keyed on PATNO x EVENT_ID, with the variables the
mechanistic hypotheses need:

  DAT-SPECT       mean_caudate, mean_putamen, mean_striatum and the
                  contralateral/ipsilateral variants. Tests H2: if the shared
                  substrate is non-dopaminergic, pain should NOT track striatal
                  dopamine transporter binding while motor severity should.

  CSF SAA         alpha-synuclein seed amplification assay. Tests H6: does
                  pathology burden modulate the pain and motor covariation.
                  Coded 0 = negative, 1 = positive; other codes are set to
                  missing because they denote inconclusive or non-standard
                  assay results and cannot be ordered on the same scale.

  APOE_e4         carrier status, as a competing genetic liability.

  subgroup        GBA carrier status. Tests H7.

The alpha-synuclein quantitative assay (`asyn`) is read but is available in only
518 patients and mostly at a single visit, so it is exported for completeness and
flagged rather than used as a primary test.
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

KEEP_VISITS = ["BL", "V04", "V06", "V08", "V10", "V12"]

KEEP = [
    "PATNO", "EVENT_ID", "COHORT", "subgroup",
    "DATSCAN_CAUDATE_L", "DATSCAN_CAUDATE_R", "con_caudate", "ips_caudate",
    "mean_caudate", "DATSCAN_PUTAMEN_L", "DATSCAN_PUTAMEN_R", "con_putamen",
    "ips_putamen", "mean_putamen", "con_striatum", "ips_striatum",
    "mean_striatum", "CSFSAA", "CSFSAA_assay", "asyn", "APOE", "APOE_e4",
]

OUT_COLS = [
    "PATNO", "EVENT_ID",
    "mean_caudate", "mean_putamen", "mean_striatum",
    "con_caudate", "con_putamen", "con_striatum",
    "saa_pos", "asyn", "apoe4", "es_GBA",
]


def check_inputs():
    if not CURATED_PATH.exists():
        print(f"ERROR: falta {CURATED_PATH}\nVer data-access.md.", file=sys.stderr)
        sys.exit(1)


def main():
    check_inputs()
    cur = pd.read_csv(CURATED_PATH, low_memory=False,
                      usecols=lambda c: c in KEEP)
    df = cur[cur["EVENT_ID"].isin(KEEP_VISITS)].copy()

    for c in ["mean_caudate", "mean_putamen", "mean_striatum",
              "con_caudate", "con_putamen", "con_striatum", "asyn"]:
        df[c] = pd.to_numeric(df[c], errors="coerce")

    # Solo 0 y 1 son interpretables como negativo y positivo. Los codigos 2 y 3
    # denotan resultados no concluyentes o ensayos distintos: mapearlos a un
    # numero los ordenaria en una escala que no existe.
    saa = pd.to_numeric(df["CSFSAA"], errors="coerce")
    df["saa_pos"] = saa.where(saa.isin([0, 1]))

    ap = pd.to_numeric(df["APOE_e4"], errors="coerce")
    df["apoe4"] = ap.where(ap.isin([0, 1, 2]))

    df["es_GBA"] = df["subgroup"].astype(str).str.contains("GBA", na=False).astype(int)

    out = df[OUT_COLS].copy()
    ruta = OUT / "biomarcadores.csv"
    out.to_csv(ruta, index=False)

    print(f"Escrito {ruta}: filas={len(out)}, pacientes={out['PATNO'].nunique()}")
    print("\nCobertura (filas no ausentes / pacientes distintos):")
    for c in OUT_COLS[2:]:
        s = out[c]
        print(f"  {c:16s} {s.notna().sum():6d} filas   "
              f"{out.loc[s.notna(), 'PATNO'].nunique():5d} pacientes")

    print("\nDAT estriatal por visita (todas las cohortes):")
    print(out.groupby("EVENT_ID")["mean_striatum"]
          .agg(["count", "mean"]).reindex(KEEP_VISITS).round(3).to_string())

    print("\nSAA (0 negativo, 1 positivo):")
    print(out["saa_pos"].value_counts(dropna=False).to_string())


if __name__ == "__main__":
    main()
