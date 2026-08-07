# ADR 0003: Definición de la muestra analítica: N = 711

- **Fecha:** 2026-08-06
- **Estado:** Aceptada
- **Afecta a:** `python/01_data_prep.py`, Tabla 1, diagrama de flujo STROBE, todo el texto

## Contexto

Durante la auditoría circulaban cinco tamaños muestrales distintos en borradores y figuras
(655, 643, ~699, 830, "aprox. 700"). Un jurado que encuentre dos cifras distintas para la
misma muestra dejará de creer el resto del documento. Se congela **un solo N**.

Al reconstruir el flujo aparecieron dos defectos en la definición de la muestra.

## Defecto 1: Exclusión de DBS con información del futuro

El código marcaba `ever_DBS` como el máximo de `DBSYN` sobre **todas** las visitas del
paciente, y excluía a cualquiera con ese indicador. De los 100 pacientes presentes en V04 con
DBS registrado en algún momento, **92 lo recibieron después de V04**, algunos hasta 11 años
más tarde.

El criterio del protocolo es «tratamiento **previo** con estimulación cerebral profunda».
Excluir a alguien en la visita de 12 meses porque será operado en 2024 es condicionar sobre el
futuro (*look-ahead bias*), y además no es inocuo: sesga la muestra sacando sistemáticamente a
los pacientes que más progresan, que son exactamente los candidatos quirúrgicos.

**Corrección.** Se guarda la fecha del primer registro con `DBSYN == 1` y se excluye únicamente
si esa fecha es anterior o igual a la fecha de la visita. En V04 esto excluye a 2 participantes
en lugar de 58.

## Defecto 2: Duración de la enfermedad fijada en la basal

Se usaba `duration_yrs` de la base curada de PPMI. Esa variable no avanza entre visitas:

| Visita | `duration_yrs` medio | `age_at_visit − ageonset` medio |
|---|---|---|
| BL  | 1.30 | 2.91 |
| V04 | 1.32 | 3.94 |
| V06 | 1.34 | 5.00 |

La Tabla 1 anterior declaraba «0.88 años de duración» en una visita de 12 meses de seguimiento,
lo cual es imposible en una cohorte reclutada con enfermedad ya diagnosticada.

**Corrección.** Se aplica la definición literal del protocolo, «años desde inicio de síntomas
… fecha de inicio vs. fecha de visita», es decir `age_at_visit − ageonset`. En V04 la media
pasa a **3.42 años (DE 1.92)**. La variable original se conserva como `dx_yrs_bl` por
trazabilidad.

## Decisión

**N = 711.** Flujo STROBE congelado:

| Paso | n |
|---|---|
| Registros de la base curada | 14 473 |
| En la visita V04 | 2 614 |
| Cohorte de Parkinson (COHORT = 1) | 1 121 |
| Tras excluir formas monogénicas (LRRK2, SNCA, PRKN, PINK1) | 913 |
| Tras excluir DBS previo a la visita | 911 |
| Con dato de dolor (NP1PAIN) | 860 |
| Con dato motor (MDS-UPDRS III): **muestra analítica** | **711** |

Casos completos para el modelo primario (añade edad, duración, H&Y y MoCA): **701 (98.6 %)**.

## Consecuencias

- Toda cifra del documento se deriva de `data/flow_v04.csv`. La prueba de regresión
  `tests/test_resultados.R` falla si `nrow(tidy_v04.csv)` no coincide con el último paso del
  flujo, de modo que las dos no pueden divergir sin que la CI lo detecte.
- Los 149 participantes perdidos entre «con dato de dolor» y «con dato motor» lo son por falta
  del **desenlace**, no de covariables. La imputación múltiple no los recupera y no debe
  presentarse como si lo hiciera: se imputan covariables, nunca el desenlace.
- Se mantienen los portadores de *GBA*: es una variante de riesgo, no una forma monogénica
  determinista, y el protocolo sólo excluye estas últimas.
