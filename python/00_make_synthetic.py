#!/usr/bin/env python3
"""
Genera datos SINTÉTICOS con la misma estructura que las tablas analíticas reales.

Motivo: el DUA de PPMI impide versionar datos a nivel de participante, pero el pipeline
tiene que poder ejecutarse de principio a fin sin acceso a PPMI (integración continua,
revisión de código por terceros).

Las distribuciones se calibran contra los estadísticos AGREGADOS publicados en la Tabla 1
de la tesis — que son públicos por definición — nunca contra los registros individuales.

ADVERTENCIA: los resultados que salgan de estos datos NO tienen significado científico.
Sirven para verificar que el código corre, no para obtener los números de la tesis.

Uso:
    python3 python/00_make_synthetic.py
"""
import numpy as np
import pandas as pd
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "data-synth"
OUT.mkdir(parents=True, exist_ok=True)

SEED = 20260518  # fecha de las decisiones metodológicas — semilla fija = reproducible
N = 711
VISITS = ["BL", "V04", "V06", "V08", "V10", "V12"]

rng = np.random.default_rng(SEED)


def clip_round(x, lo, hi, decimals=0):
    return np.round(np.clip(x, lo, hi), decimals)


def make_cross_section(n=N):
    """Corte transversal V04, calibrado contra la Tabla 1 real (medias y DE agregadas)."""
    patno = np.arange(100001, 100001 + n)

    age = clip_round(rng.normal(63.70, 9.58, n), 30, 95, 2)
    sex_male = rng.binomial(1, 0.658, n)
    educ = clip_round(rng.normal(15.5, 3.0, n), 6, 24)
    bmi = clip_round(rng.normal(26.51, 4.73, n), 15, 50, 2)
    duration = clip_round(np.abs(rng.normal(3.42, 1.92, n)), 0, 30, 3)

    # Dolor (exposición). Proporciones tomadas de la distribución real observada
    # en V04 (n = 296 / 293 / 71 / 44 / 7 sobre 711).
    pain = rng.choice([0, 1, 2, 3, 4], size=n,
                      p=[0.4163, 0.4121, 0.0999, 0.0619, 0.0098])

    moca = clip_round(rng.normal(26.67, 2.78, n), 10, 30)
    gds = clip_round(np.abs(rng.normal(2.35, 2.63, n)), 0, 15)
    stai_state = clip_round(rng.normal(31.39, 9.78, n), 20, 80)
    stai_trait = clip_round(rng.normal(32.05, 9.80, n), 20, 80)
    rbdsq = clip_round(np.abs(rng.normal(4.33, 3.17, n)), 0, 13)
    scopa = clip_round(np.abs(rng.normal(11.20, 6.87, n)), 0, 69)
    ess = clip_round(np.abs(rng.normal(5.88, 4.03, n)), 0, 24)
    ledd = clip_round(np.abs(rng.normal(212.99, 272.26, n)), 0, 3000, 1)
    hy = clip_round(rng.normal(1.85, 0.45, n), 0, 5)

    # Desenlace motor. Se inyecta a propósito el efecto del dolor (~+1.1 pts por nivel)
    # para que el pipeline produzca un resultado con la forma esperada.
    # El intercepto está calibrado para que la MEDIA MARGINAL de UPDRS3 reproduzca la de
    # la Tabla 1 real (25.99), no para replicar el intercepto del modelo ajustado.
    updrs3 = (
        23.25
        + 0.86 * pain
        + 0.072 * (age - 63.70)
        + 0.39 * sex_male
        + 0.36 * duration
        - 0.18 * (moca - 26.67)
        + rng.normal(0, 11.0, n)
    )
    updrs3 = clip_round(updrs3, 0, 132)

    updrs1 = clip_round(2.0 + 2.9 * pain + np.abs(rng.normal(0, 3.5, n)), 0, 52)
    updrs2 = clip_round(3.0 + 1.9 * pain + np.abs(rng.normal(0, 4.3, n)), 0, 52)

    df = pd.DataFrame({
        "PATNO": patno,
        "EVENT_ID": "V04",
        "visit_date": "Nov-21",
        "YEAR": 1,
        "age_yrs": age,
        "sex_male": sex_male,
        "EDUCYRS": educ,
        "BMI": bmi,
        "disease_yrs": duration,
        "dx_yrs_bl": clip_round(duration - 2.1, 0, 30, 3),
        "subgroup": "Sporadic PD",
        "is_GBA": False,
        "LEDD": ledd,
        "PDTRTMNT": rng.binomial(1, 0.6, n),
        "MoCA": moca,
        "NP1PAIN": pain,
        "pain_present": (pain >= 1).astype(int),
        "GDS": gds,
        "STAI_total": stai_state + stai_trait,
        "STAI_state": stai_state,
        "STAI_trait": stai_trait,
        "RBDSQ": rbdsq,
        "ESS": ess,
        "SCOPA_AUT": scopa,
        "HY": hy,
        "NHY_ON": hy,
        "UPDRS1": updrs1,
        "UPDRS2": updrs2,
        "UPDRS3": updrs3,
        "UPDRS3_on": updrs3,
        "UPDRS_total": updrs1 + updrs2 + updrs3,
    })

    # Faltantes con los porcentajes de la Tabla 1 real
    for col, pct in [("MoCA", 0.009), ("GDS", 0.005), ("STAI_state", 0.005),
                     ("RBDSQ", 0.003), ("SCOPA_AUT", 0.012), ("BMI", 0.015)]:
        idx = rng.choice(n, size=int(round(pct * n)), replace=False)
        df.loc[idx, col] = np.nan

    return df


# Meses de visita, para que `visit_date` tenga el formato "Mon-yy" que el
# pipeline del articulo parsea al calcular el tiempo REAL entre visitas.
MESES = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
         "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]


def make_long(cross):
    """Formato largo BL..V12 a partir del corte transversal, con deriva temporal.

    Lleva TODAS las columnas que necesita el pipeline del articulo, no solo las
    de la tesis: sin `visit_date` no se puede calcular el tiempo real entre
    visitas, y sin las escalas no motoras no corre la prueba discriminante.
    """
    rows = []
    for _, r in cross.iterrows():
        n_visits = rng.integers(2, len(VISITS) + 1)
        # Mes de reclutamiento propio de cada paciente: asi las visitas no quedan
        # artificialmente alineadas y el intervalo real varia, como en PPMI.
        mes0 = int(rng.integers(0, 12))
        anio0 = int(rng.integers(11, 16))
        for j, ev in enumerate(VISITS[:n_visits]):
            year = [0, 1, 2, 3, 4, 5][j]
            # Desviacion de hasta dos meses respecto del aniversario nominal.
            desfase = int(rng.integers(-2, 3)) if year > 0 else 0
            total_meses = mes0 + 12 * year + desfase
            mes = MESES[total_meses % 12]
            anio = anio0 + total_meses // 12
            pain = clip_round(r["NP1PAIN"] + rng.normal(0.05 * year, 0.6), 0, 4)
            updrs3 = clip_round(r["UPDRS3"] + 2.5 * year + rng.normal(0, 6), 0, 132)
            rows.append({
                "PATNO": r["PATNO"],
                "EVENT_ID": ev,
                "visit_date": f"{mes}-{anio:02d}",
                "YEAR": year,
                "age_yrs": r["age_yrs"] + year,
                "sex_male": r["sex_male"],
                "EDUCYRS": r["EDUCYRS"],
                "BMI": r["BMI"],
                "disease_yrs": r["disease_yrs"] + year,
                "dx_yrs_bl": r["dx_yrs_bl"],
                "subgroup": r["subgroup"],
                "is_GBA": r["is_GBA"],
                "NP1PAIN": pain,
                "pain_present": int(pain >= 1),
                "UPDRS3": updrs3,
                # El estado ON puntua algo mejor que el OFF, como en la cohorte real.
                "UPDRS3_on": clip_round(updrs3 - np.abs(rng.normal(3, 3)), 0, 132),
                "UPDRS1": clip_round(r["UPDRS1"] + 0.6 * year + rng.normal(0, 2), 0, 52),
                "UPDRS2": clip_round(r["UPDRS2"] + 0.9 * year + rng.normal(0, 2), 0, 52),
                "UPDRS_total": np.nan,
                "MoCA": r["MoCA"],
                "GDS": r["GDS"],
                "STAI_total": r["STAI_total"],
                "STAI_state": r["STAI_state"],
                "STAI_trait": r["STAI_trait"],
                "RBDSQ": r["RBDSQ"],
                "ESS": r["ESS"],
                "SCOPA_AUT": r["SCOPA_AUT"],
                "HY": r["HY"],
                "NHY_ON": r["NHY_ON"],
                "PDTRTMNT": r["PDTRTMNT"],
                "LEDD": clip_round(r["LEDD"] + 90 * year + rng.normal(0, 60), 0, 4000, 1),
            })
    df = pd.DataFrame(rows)
    df["UPDRS_total"] = df["UPDRS1"] + df["UPDRS2"] + df["UPDRS3"]
    return df


def make_stebbins(long):
    """Fenotipo TD/PIGD sintetico, con la misma estructura que data/stebbins.csv.

    Se generan los 16 items y se aplica la MISMA regla de clasificacion que
    python/02_stebbins_phenotype.py, de modo que el pipeline del articulo pueda
    correr entero sin acceso a PPMI. La proporcion de denominador cero se calibra
    para que aparezca el caso que motiva el ADR 0007.
    """
    n = len(long)
    # La carga axial crece con la severidad motora, como en la cohorte real: eso
    # reproduce la deriva del fenotipo hacia PIGD a lo largo del seguimiento.
    intensidad_pigd = np.clip((long["UPDRS3"].to_numpy() - 20) / 40, 0, 1)
    lam_pigd = 0.15 + 0.9 * intensidad_pigd
    lam_trem = 0.55

    items = {}
    trem_cols = ["NP3PTRMR", "NP3PTRML", "NP3KTRMR", "NP3KTRML", "NP3RTARU",
                 "NP3RTALU", "NP3RTARL", "NP3RTALL", "NP3RTALJ", "NP3RTCON", "NP2TRMR"]
    pigd_cols = ["NP3GAIT", "NP3FRZGT", "NP3PSTBL", "NP2WALK", "NP2FREZ"]
    for c in trem_cols:
        items[c] = np.minimum(rng.poisson(lam_trem, n), 4)
    for c in pigd_cols:
        items[c] = np.minimum(rng.poisson(lam_pigd, n), 4)

    df = pd.DataFrame(items)
    df.insert(0, "EVENT_ID", long["EVENT_ID"].to_numpy())
    df.insert(0, "PATNO", long["PATNO"].to_numpy())

    trem_mean = df[trem_cols].mean(axis=1)
    pigd_mean = df[pigd_cols].mean(axis=1)
    ratio = trem_mean / pigd_mean.replace(0, np.nan)

    def clasifica(r, t, p, regla):
        if p == 0:
            if regla == "jankovic":
                return "TD" if t > 0 else "Indeterminate"
            if regla == "indeterminado":
                return "Indeterminate"
            return np.nan
        if r >= 1.15:
            return "TD"
        if r <= 0.90:
            return "PIGD"
        return "Indeterminate"

    z = zip(ratio, trem_mean, pigd_mean)
    df["tremor_mean"] = trem_mean
    df["pigd_mean"] = pigd_mean
    df["td_pigd_ratio"] = ratio
    df["phenotype"] = [clasifica(r, t, p, "jankovic") for r, t, p in
                       zip(ratio, trem_mean, pigd_mean)]
    df["phenotype_cero_indet"] = [clasifica(r, t, p, "indeterminado") for r, t, p in
                                  zip(ratio, trem_mean, pigd_mean)]
    df["phenotype_cero_excl"] = [clasifica(r, t, p, "excluir") for r, t, p in
                                 zip(ratio, trem_mean, pigd_mean)]
    df["denominador_cero"] = (pigd_mean == 0).astype(int)
    df["items_complete"] = 1
    df["n_tremor_items"] = len(trem_cols)
    df["n_pigd_items"] = len(pigd_cols)
    df["np3_tremor_sum"] = df[[c for c in trem_cols if c.startswith("NP3")]].sum(axis=1)
    df["np3_pigd_sum"] = df[[c for c in pigd_cols if c.startswith("NP3")]].sum(axis=1)
    df["np3_clasificadores_sum"] = df["np3_tremor_sum"] + df["np3_pigd_sum"]
    return df


def main():
    cross = make_cross_section()
    long = make_long(cross)

    stebbins = make_stebbins(long)

    cross.to_csv(OUT / "tidy_v04.csv", index=False)
    long.to_csv(OUT / "tidy_long.csv", index=False)
    stebbins.to_csv(OUT / "stebbins.csv", index=False)
    # El pipeline lee stebbins_on.csv en las sensibilidades de estado ON.
    stebbins.to_csv(OUT / "stebbins_on.csv", index=False)

    flow = pd.DataFrame({
        "step": ["all_curated_rows", "at_visit", "pd_cohort", "after_monogenic_exclusion",
                 "after_dbs_exclusion", "after_pain_complete", "after_motor_complete"],
        "n": [14473, 2614, 1121, 913, 911, 860, N],
    })
    flow.to_csv(OUT / "flow_v04.csv", index=False)

    print(f"Datos sintéticos escritos en {OUT}")
    print(f"  tidy_v04.csv   {len(cross):>5} filas")
    print(f"  tidy_long.csv  {len(long):>5} filas")
    print(f"  flow_v04.csv   {len(flow):>5} filas")
    print(f"  stebbins.csv   {len(stebbins):>5} filas")
    print(f"\nSemilla = {SEED} (fija, reproducible)")
    print("ADVERTENCIA: datos sin significado científico. Solo para pruebas.")


if __name__ == "__main__":
    main()
