#!/usr/bin/env python3
"""
Paper pipeline — Step 5: analgesic exposure from the concomitant medication log.

POR QUE HACE FALTA. El articulo reporta un E-value de 1,41, es decir, que un
confusor no medido de magnitud modesta bastaria para explicar la asociacion. El
uso de analgesicos es exactamente un confusor de ese tamano: se asocia con el
dolor reportado por definicion, y plausiblemente con el desempeno motor medido.
Conceder que un confusor asi bastaria y dejarlo sin medir no es defendible
cuando el dato esta disponible.

Produce data/analgesicos.csv, con una fila por PATNO x EVENT_ID e indicadores de
exposicion ACTIVA en la fecha de la visita.

SOBRE LOS PATRONES. Los nombres vienen en texto libre. Los patrones van anclados
a limites de palabra: sin anclar, "codeine" captura tambien "codeine-free" y
"oxycodone" quedaria contada dos veces por dos patrones distintos. Este proyecto
ya tuvo un fallo de clasificador no anclado en otro analisis y no se repite.

Cada categoria se cuenta UNA vez por registro aunque coincidan varios patrones,
y las categorias son mutuamente excluyentes por prioridad: opioide antes que
antiinflamatorio, y este antes que otros analgesicos, porque un compuesto como
"oxycodone/paracetamol" debe contar como opioide.
"""
import os
import re
import sys
import pandas as pd
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "data"
RAW = Path(os.environ.get("PPMI_RAW_DIR", str(OUT))).expanduser()

CANDIDATOS = [
    RAW / "Concomitant_Medication_Log_04Nov2024.csv",
    RAW / "Propensity score DBS sleep" / "Data I need to merge"
        / "Concomitant_Medication_Log_04Nov2024.csv",
]

KEEP_VISITS = ["BL", "V04", "V06", "V08", "V10", "V12"]

# Los patrones se compilan con \b para que solo casen palabras completas.
OPIOIDES = [
    "oxycodone", "oxycontin", "hydrocodone", "hydromorphone", "morphine",
    "codeine", "tramadol", "fentanyl", "buprenorphine", "methadone",
    "tapentadol", "oxymorphone", "percocet", "vicodin", "norco", "dilaudid",
]
AINE = [
    "ibuprofen", "naproxen", "diclofenac", "celecoxib", "meloxicam",
    "indomethacin", "ketorolac", "etoricoxib", "piroxicam", "nabumetone",
    # "asa" es la forma libre mas frecuente de la aspirina en este registro
    # ("ASA 81 MG"). Sin incluirla aqui, esos registros no casaban con ninguna
    # categoria y quedaban fuera de las DOS variantes en lugar de solo de la que
    # excluye aspirina.
    "aspirin", "acetylsalicylic", "asa", "advil", "motrin", "aleve", "celebrex",
]
OTROS_ANALG = [
    "paracetamol", "acetaminophen", "tylenol", "metamizole", "dipyrone",
    "gabapentin", "pregabalin", "duloxetine", "amitriptyline", "nortriptyline",
    "lidocaine", "capsaicin",
]

def compilar(lst):
    return re.compile(r"\b(" + "|".join(re.escape(x) for x in lst) + r")\b", re.I)

# La aspirina domina la categoria de antiinflamatorios (939 de 2 271 registros),
# y a dosis baja se toma por cardioproteccion, no por dolor. Contarla como
# exposicion analgesica introduciria mas ruido que senal, de modo que se define
# tambien una variante que la excluye, y esa es la primaria para el ajuste.
ASPIRINA = ["aspirin", "acetylsalicylic", "asa"]
AINE_SIN_ASPIRINA = [x for x in AINE if x not in ASPIRINA]

RX = [("opioide", compilar(OPIOIDES)),
      ("aine", compilar(AINE)),
      ("otro_analgesico", compilar(OTROS_ANALG))]
RX_SIN_ASA = [("opioide", compilar(OPIOIDES)),
              ("aine", compilar(AINE_SIN_ASPIRINA)),
              ("otro_analgesico", compilar(OTROS_ANALG))]


def encontrar():
    env = os.environ.get("PPMI_CONMED_PATH")
    if env and Path(env).expanduser().exists():
        return Path(env).expanduser()
    for p in CANDIDATOS:
        if p.exists():
            return p
    print("ERROR: no se encuentra el registro de medicacion concomitante.",
          file=sys.stderr)
    for p in CANDIDATOS:
        print(f"  - {p}", file=sys.stderr)
    print("\nIndicalo con PPMI_CONMED_PATH. Ver data-access.md.", file=sys.stderr)
    sys.exit(1)


def clasificar(nombre, reglas=None):
    """Prioridad opioide > AINE > otro. Devuelve None si no es analgesico."""
    if not isinstance(nombre, str):
        return None
    for etiqueta, rx in (reglas or RX):
        if rx.search(nombre):
            return etiqueta
    return None


def main():
    med = pd.read_csv(encontrar(), low_memory=False)
    med["categoria"] = med["CMTRT"].map(clasificar)
    med["categoria_sin_asa"] = med["CMTRT"].map(
        lambda x: clasificar(x, RX_SIN_ASA))
    analg = med[med["categoria"].notna()].copy()

    # Fechas: el registro usa MM/AAAA. Un tratamiento sin fecha de fin y marcado
    # como continuo se considera activo hasta el final del seguimiento.
    for c, col in (("ini", "STARTDT"), ("fin", "STOPDT")):
        analg[c] = pd.to_datetime(analg[col], errors="coerce", format="%m/%Y")
    # Solo se trata como vigente indefinidamente lo que el registro marca como
    # ONGOING. Una fecha de fin ausente sin esa marca es un dato que falta, no un
    # tratamiento eterno: asumirlo inflaba la exposicion en las visitas tardias.
    ongoing = pd.to_numeric(analg.get("ONGOING"), errors="coerce").fillna(0) == 1
    analg.loc[analg["fin"].isna() & ongoing, "fin"] = pd.Timestamp("2099-12-31")
    analg = analg[analg["fin"].notna()]
    analg = analg[analg["ini"].notna()]

    print(f"Registros de medicacion: {len(med)}")
    print(f"  clasificados como analgesico: {len(analg)} "
          f"({analg['PATNO'].nunique()} pacientes)")
    print("\nPor categoria:")
    print(analg["categoria"].value_counts().to_string())
    print("\nPrincipios activos mas frecuentes por categoria:")
    for cat in ["opioide", "aine", "otro_analgesico"]:
        top = (analg.loc[analg["categoria"] == cat, "CMTRT"]
               .str.upper().value_counts().head(5).to_dict())
        print(f"  {cat}: {top}")

    # Fechas de visita, desde la base analitica ya construida.
    largo = pd.read_csv(OUT / "tidy_long.csv",
                        usecols=["PATNO", "EVENT_ID", "visit_date"])
    largo = largo[largo["EVENT_ID"].isin(KEEP_VISITS)].copy()
    largo["fecha"] = pd.to_datetime(largo["visit_date"], errors="coerce",
                                    format="%b-%y")

    filas = []
    por_paciente = {k: v for k, v in analg.groupby("PATNO")}
    for r in largo.itertuples(index=False):
        sub = por_paciente.get(r.PATNO)
        act = {"opioide": 0, "aine": 0, "otro_analgesico": 0}
        if sub is not None and pd.notna(r.fecha):
            vivo = sub[(sub["ini"] <= r.fecha) & (sub["fin"] >= r.fecha)]
            for cat in act:
                act[cat] = int((vivo["categoria"] == cat).any())
            sin_asa = int(vivo["categoria_sin_asa"].notna().any())
        else:
            sin_asa = 0
        filas.append({"PATNO": r.PATNO, "EVENT_ID": r.EVENT_ID, **act,
                      "cualquier_analgesico": int(any(act.values())),
                      "analgesico_sin_aspirina": sin_asa})

    out = pd.DataFrame(filas)
    ruta = OUT / "analgesicos.csv"
    out.to_csv(ruta, index=False)

    print(f"\nEscrito {ruta}: filas={len(out)}")
    print("\nExposicion ACTIVA en la fecha de la visita, por visita:")
    print(out.groupby("EVENT_ID")[["opioide", "aine", "otro_analgesico",
                                    "cualquier_analgesico",
                                    "analgesico_sin_aspirina"]]
          .mean().reindex(KEEP_VISITS).round(3).to_string())


if __name__ == "__main__":
    main()
