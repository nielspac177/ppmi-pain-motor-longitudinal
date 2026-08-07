#!/usr/bin/env python3
"""
Paper pipeline — Step 2: Stebbins TD/PIGD motor phenotype.

Builds data/stebbins.csv, keyed on PATNO x EVENT_ID, with the tremor-dominant /
postural-instability-gait-difficulty classification of Stebbins et al. (2013).

This is a SEPARATE script from python/01_data_prep.py on purpose. The thesis is
closed and its pipeline reproduces byte for byte; adding columns to tidy_long.csv
would break that guarantee. The phenotype is merged in R at analysis time.

Item set (Stebbins 2013, Mov Disord 28:668-670):

  Tremor, 11 items = 10 from Part III + 1 from Part II
    NP3PTRMR NP3PTRML          postural tremor, right / left
    NP3KTRMR NP3KTRML          kinetic tremor, right / left
    NP3RTARU NP3RTALU          rest tremor amplitude, upper right / left
    NP3RTARL NP3RTALL          rest tremor amplitude, lower right / left
    NP3RTALJ                   rest tremor amplitude, lip / jaw
    NP3RTCON                   constancy of rest tremor
    NP2TRMR                    tremor (patient questionnaire, item 2.10)

  PIGD, 5 items = 3 from Part III + 2 from Part II
    NP3GAIT NP3FRZGT NP3PSTBL  gait, freezing of gait, postural stability
    NP2WALK                    walking and balance (item 2.12)
    NP2FREZ                    freezing (item 2.13)

  ratio = mean(tremor items) / mean(PIGD items)
    ratio >= 1.15                     -> TD
    ratio <= 0.90                     -> PIGD
    otherwise                         -> indeterminate
    PIGD mean == 0 and tremor mean > 0 -> TD
    both means == 0                   -> indeterminate

The zero-denominator convention follows Jankovic et al. (1990), which Stebbins
carries over: a patient with no axial signs at all and any tremor is tremor
dominant, and a patient with neither is unclassifiable rather than TD.

Which Part III record. PPMI stores up to two Part III examinations per visit,
PDSTATE == "OFF" and PDSTATE == "ON", plus untreated examinations with PDSTATE
missing. The thesis outcome is the curated updrs3_score, which was verified to
correspond to the {OFF, missing} records (agreement 0.865 and 0.981 at V04, vs
0.070 and 0.982 for updrs3_score_on). The phenotype is therefore built from the
same {OFF, missing} records so that exposure, phenotype and outcome all refer to
one clinical state. The ON records are written out separately for sensitivity.
"""
import os
import sys
import pandas as pd
import numpy as np
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "data"
OUT.mkdir(parents=True, exist_ok=True)

RAW = Path(os.environ.get("PPMI_RAW_DIR", str(OUT))).expanduser()

PART3_PATH = RAW / "MDS-UPDRS_Part_III_04Nov2024.csv"

# La Parte II no esta en el directorio raiz junto a los demas crudos. Se busca en
# las ubicaciones conocidas y se permite sobreescribir con PPMI_PART2_PATH.
PART2_CANDIDATES = [
    RAW / "MDS_UPDRS_Part_II__Patient_Questionnaire_04Nov2024.csv",
    RAW / "MDS-UPDRS_Part_II_04Nov2024.csv",
    RAW / "Propensity score DBS sleep" / "Data I need to merge"
        / "7.MDS_UPDRS_Part_II__Patient_Questionnaire_04Nov2024.csv",
]

TREMOR_P3 = ["NP3PTRMR", "NP3PTRML", "NP3KTRMR", "NP3KTRML",
             "NP3RTARU", "NP3RTALU", "NP3RTARL", "NP3RTALL",
             "NP3RTALJ", "NP3RTCON"]
TREMOR_P2 = ["NP2TRMR"]
PIGD_P3 = ["NP3GAIT", "NP3FRZGT", "NP3PSTBL"]
PIGD_P2 = ["NP2WALK", "NP2FREZ"]

TREMOR_ITEMS = TREMOR_P3 + TREMOR_P2
PIGD_ITEMS = PIGD_P3 + PIGD_P2

KEEP_VISITS = ["BL", "V04", "V06", "V08", "V10", "V12"]

TD_CUT = 1.15
PIGD_CUT = 0.90


def find_part2():
    env = os.environ.get("PPMI_PART2_PATH")
    if env:
        p = Path(env).expanduser()
        if p.exists():
            return p
        print(f"ERROR: PPMI_PART2_PATH apunta a un archivo inexistente: {p}",
              file=sys.stderr)
        sys.exit(1)
    for p in PART2_CANDIDATES:
        if p.exists():
            return p
    print("ERROR: no se encuentra el archivo de la MDS-UPDRS Parte II.\n"
          "Se buscó en:", file=sys.stderr)
    for p in PART2_CANDIDATES:
        print(f"  - {p}", file=sys.stderr)
    print("\nIndica su ubicación con PPMI_PART2_PATH. Ver data-access.md.",
          file=sys.stderr)
    sys.exit(1)


def check_inputs():
    if not PART3_PATH.exists():
        print(f"ERROR: falta {PART3_PATH}\nVer data-access.md.", file=sys.stderr)
        sys.exit(1)


def classify(ratio, tremor_mean, pigd_mean, regla_cero="jankovic"):
    """Regla de Stebbins 2013. `regla_cero` fija que hacer con denominador cero.

    El articulo de Stebbins es de acceso cerrado y no se pudo verificar que
    enuncie una regla para el caso en que la media PIGD sea cero. Una revision
    de los trabajos que aplican el criterio no encontro ninguno que declare una,
    y ninguno que senale la ambiguedad. En esta cohorte de reciente diagnostico
    el caso afecta a cerca de una quinta parte de las visitas, de modo que la
    eleccion no es inocua y se preespecifica con sensibilidad a las tres
    opciones (ver ADR 0007):

      jankovic       media PIGD = 0 y temblor > 0 -> TD; ambas cero -> indeterminado.
                     Es la convencion heredada de Jankovic 1990, y la primaria.
      indeterminado  todo denominador cero -> indeterminado (conservadora).
      excluir        todo denominador cero -> sin clasificar.
    """
    if pd.isna(tremor_mean) or pd.isna(pigd_mean):
        return np.nan
    if pigd_mean == 0:
        if regla_cero == "jankovic":
            return "TD" if tremor_mean > 0 else "Indeterminate"
        if regla_cero == "indeterminado":
            return "Indeterminate"
        return np.nan
    if ratio >= TD_CUT:
        return "TD"
    if ratio <= PIGD_CUT:
        return "PIGD"
    return "Indeterminate"


def build(p3_state):
    """p3_state: 'off' usa PDSTATE in {OFF, NaN}; 'on' usa PDSTATE == 'ON'."""
    p3 = pd.read_csv(PART3_PATH, low_memory=False)
    p3 = p3[p3["EVENT_ID"].isin(KEEP_VISITS)]

    if p3_state == "off":
        sel = p3["PDSTATE"].isna() | (p3["PDSTATE"] == "OFF")
    else:
        sel = p3["PDSTATE"] == "ON"
    p3 = p3[sel].copy()

    # Tres visitas tienen dos registros OFF/NaN duplicados con items identicos.
    # Se ordena de forma determinista y se conserva el primero, para que el
    # resultado no dependa del orden de lectura del archivo.
    p3 = (p3.sort_values(["PATNO", "EVENT_ID", "PDSTATE", "REC_ID"],
                         na_position="last")
            .drop_duplicates(subset=["PATNO", "EVENT_ID"], keep="first"))

    p2_path = find_part2()
    p2 = pd.read_csv(p2_path, low_memory=False)
    p2 = p2[p2["EVENT_ID"].isin(KEEP_VISITS)]
    p2 = (p2.sort_values(["PATNO", "EVENT_ID"])
            .drop_duplicates(subset=["PATNO", "EVENT_ID"], keep="first"))

    df = p3[["PATNO", "EVENT_ID"] + TREMOR_P3 + PIGD_P3].merge(
        p2[["PATNO", "EVENT_ID"] + TREMOR_P2 + PIGD_P2],
        on=["PATNO", "EVENT_ID"], how="left")

    for c in TREMOR_ITEMS + PIGD_ITEMS:
        df[c] = pd.to_numeric(df[c], errors="coerce")

    df["n_tremor_items"] = df[TREMOR_ITEMS].notna().sum(axis=1)
    df["n_pigd_items"] = df[PIGD_ITEMS].notna().sum(axis=1)

    # Primario: los 16 items presentes. La media sobre items disponibles se
    # calcula tambien, para la sensibilidad, pero no es la clasificacion primaria.
    complete = (df["n_tremor_items"] == len(TREMOR_ITEMS)) & \
               (df["n_pigd_items"] == len(PIGD_ITEMS))

    df["tremor_mean_avail"] = df[TREMOR_ITEMS].mean(axis=1, skipna=True)
    df["pigd_mean_avail"] = df[PIGD_ITEMS].mean(axis=1, skipna=True)

    df["tremor_mean"] = df["tremor_mean_avail"].where(complete)
    df["pigd_mean"] = df["pigd_mean_avail"].where(complete)

    with np.errstate(divide="ignore", invalid="ignore"):
        df["td_pigd_ratio"] = df["tremor_mean"] / df["pigd_mean"].replace(0, np.nan)
        df["td_pigd_ratio_avail"] = (df["tremor_mean_avail"]
                                     / df["pigd_mean_avail"].replace(0, np.nan))

    # Sumas de los items de la Parte III que entran en la clasificacion. Sirven
    # para construir una puntuacion motora que EXCLUYA los items usados para
    # definir el fenotipo, y asi contrastar la circularidad parcial de frente en
    # lugar de solo declararla.
    df["np3_tremor_sum"] = df[TREMOR_P3].sum(axis=1, min_count=len(TREMOR_P3))
    df["np3_pigd_sum"] = df[PIGD_P3].sum(axis=1, min_count=len(PIGD_P3))
    df["np3_clasificadores_sum"] = df["np3_tremor_sum"] + df["np3_pigd_sum"]

    df["phenotype"] = [classify(r, t, p) for r, t, p in
                       zip(df["td_pigd_ratio"], df["tremor_mean"], df["pigd_mean"])]
    df["phenotype_avail"] = [classify(r, t, p) for r, t, p in
                             zip(df["td_pigd_ratio_avail"],
                                 df["tremor_mean_avail"], df["pigd_mean_avail"])]
    # Las dos alternativas de la regla de denominador cero, para sensibilidad.
    df["phenotype_cero_indet"] = [classify(r, t, p, "indeterminado") for r, t, p in
                                  zip(df["td_pigd_ratio"], df["tremor_mean"], df["pigd_mean"])]
    df["phenotype_cero_excl"] = [classify(r, t, p, "excluir") for r, t, p in
                                 zip(df["td_pigd_ratio"], df["tremor_mean"], df["pigd_mean"])]
    df["denominador_cero"] = (df["pigd_mean"] == 0).astype("Int64").where(df["pigd_mean"].notna())

    df["items_complete"] = complete.astype(int)
    return df


def report(df, label):
    print(f"\n=== {label} ===")
    print(f"filas: {len(df)}   con los 16 items: {int(df['items_complete'].sum())}")
    print("\nclasificacion primaria (16 items completos) por visita:")
    tab = pd.crosstab(df["EVENT_ID"], df["phenotype"].fillna("(sin dato)"))
    order = [v for v in KEEP_VISITS if v in tab.index]
    print(tab.loc[order].to_string())
    print("\ndenominador PIGD = 0 (regla de Jankovic aplicada): "
          f"{int(((df['pigd_mean'] == 0)).sum())}")
    print("  de ellos con temblor > 0 -> TD: "
          f"{int(((df['pigd_mean'] == 0) & (df['tremor_mean'] > 0)).sum())}")
    print("  de ellos sin temblor -> Indeterminate: "
          f"{int(((df['pigd_mean'] == 0) & (df['tremor_mean'] == 0)).sum())}")
    disc = (df["phenotype"].notna() & df["phenotype_avail"].notna()
            & (df["phenotype"] != df["phenotype_avail"])).sum()
    print(f"discrepancias entre item-completo y media-disponible: {int(disc)}")


def main():
    check_inputs()

    off = build("off")
    report(off, "Estado OFF / no tratado (primario, concuerda con updrs3_score)")
    cols = (["PATNO", "EVENT_ID"] + TREMOR_ITEMS + PIGD_ITEMS
            + ["n_tremor_items", "n_pigd_items", "items_complete",
               "tremor_mean", "pigd_mean", "td_pigd_ratio", "phenotype",
               "tremor_mean_avail", "pigd_mean_avail", "td_pigd_ratio_avail",
               "phenotype_avail", "phenotype_cero_indet", "phenotype_cero_excl",
               "denominador_cero",
               "np3_tremor_sum", "np3_pigd_sum", "np3_clasificadores_sum"])
    off[cols].to_csv(OUT / "stebbins.csv", index=False)
    print(f"\nEscrito {OUT/'stebbins.csv'}: filas={len(off)}")

    on = build("on")
    report(on, "Estado ON (sensibilidad)")
    on[cols].to_csv(OUT / "stebbins_on.csv", index=False)
    print(f"\nEscrito {OUT/'stebbins_on.csv'}: filas={len(on)}")


if __name__ == "__main__":
    main()
