# ADR 0001: Desviaciones respecto al plan de análisis del protocolo registrado

- **Fecha:** 2026-05-18 (decisiones), 2026-08-04 (registro formal)
- **Estado:** **SUPERADA por [ADR 0002](0002-fidelidad-al-protocolo-registrado.md)** (2026-08-06)
- **Decide:** Niels Pacheco-Barrios (asesor)
- **Afecta a:** capítulo de Métodos de la tesis; `R/02_aim1_crosssectional.R`

> **Aviso.** Esta decisión ya no está vigente. Al ejecutarse el análisis se comprobó que
> dos de sus premisas eran falsas: (a) la correlación entre Hoehn & Yahr y la MDS-UPDRS III
> es ρ = 0.559 (moderada), no "la misma medida"; y (b) apartarse del modelo registrado
> cambiaba la conclusión del estudio, que es exactamente lo que un plan de análisis
> registrado existe para impedir. Se conserva el documento porque el registro de una
> decisión revocada forma parte de la trazabilidad. Ver ADR 0002.

## Contexto

El protocolo aprobado (`EP_version_limpia.docx`, sección 4.7) comprometió un plan de análisis
concreto. Al implementarlo aparecieron tres problemas metodológicos que obligaban a apartarse
de él. Este documento registra qué se cambió, por qué, y qué se conserva como análisis de
sensibilidad, para que la desviación sea **declarada** y no silenciosa.

Una desviación justificada y declarada es metodológicamente correcta. Una desviación no
declarada es un defecto de integridad, y el jurado puede legítimamente preguntar
"prometiste X, ¿dónde está?".

---

## Decisión 1: regresión lineal como modelo primario, no multinomial

**Protocolo:** regresión logística multinomial sobre terciles de MDS-UPDRS III (baja / leve a
media / media a severa), categoría de referencia = severidad baja.

**Implementado:** regresión lineal múltiple sobre el puntaje continuo de MDS-UPDRS III.
El modelo multinomial por terciles se conserva como **análisis de sensibilidad**.

**Razones:**

1. **Pérdida de información.** Categorizar en terciles una variable continua descarta la
   variación dentro de cada categoría y reduce la potencia estadística. Es una práctica
   desaconsejada de forma consistente en la literatura de bioestadística.
2. **Puntos de corte dependientes de la muestra.** Los terciles se definen sobre la
   distribución observada en esta muestra concreta, por lo que no son comparables con ninguna
   otra población y no tienen interpretación clínica externa.
3. **Interpretabilidad.** El coeficiente lineal se lee directamente como "puntos de MDS-UPDRS III
   por cada nivel de dolor", que es la escala en la que se discute la relevancia clínica
   (la diferencia mínima clínicamente importante de la MDS-UPDRS III ronda los 3–5 puntos).

**Qué se conserva:** el modelo multinomial se reporta completo como sensibilidad
(`outputs/tables/model1c_multinomial_tertile.csv`), cumpliendo el compromiso del protocolo.

---

## Decisión 2: se elimina Hoehn & Yahr del ajuste

**Protocolo:** ajustar por edad, sexo, duración de la enfermedad, **estadio Hoehn & Yahr** y MoCA.

**Implementado:** se **excluye** Hoehn & Yahr del modelo. Se conserva en la Tabla 1 descriptiva.

**Razón, sobreajuste estructural.** El estadio de Hoehn & Yahr no es un confusor: es una
medida de la **misma severidad motora** que constituye el desenlace, en escala ordinal gruesa.
La MDS-UPDRS III y el H&Y miden el mismo constructo con distinto instrumento.

Ajustar por él equivale a controlar por el desenlace, lo que sesga el coeficiente del dolor
hacia el nulo y produce una subestimación de la asociación. En la terminología de grafos
causales, H&Y está en la vía causal entre exposición y desenlace (o es un marcador del propio
desenlace), no fuera de ella; condicionar sobre él es un caso de *overadjustment bias*.

---

## Decisión 3: se añaden covariables de afecto y sueño

**Protocolo:** el modelo de la sección 4.7 no incluía covariables psicoafectivas.

**Implementado:** se añaden **GDS** (depresión), **STAI-estado** (ansiedad) y **RBDSQ**
(trastorno conductual del sueño REM).

**Razón, confusión no controlada.** La percepción y el reporte de dolor en la enfermedad de
Parkinson están fuertemente influidos por el estado afectivo. Sin ajustar por depresión y
ansiedad, parte de la asociación observada entre dolor y severidad motora sería atribuible al
afecto, no al dolor. La Tabla 1 lo confirma en esta muestra: los participantes con dolor
tienen puntajes significativamente mayores en GDS, STAI-estado, STAI-rasgo y RBDSQ
(todos p < 0.001).

Omitir estas variables habría producido una estimación sesgada al alza.

---

## Decisión 4: la LEDD se trata como mediador, no como confusor

**Protocolo:** no especificaba el rol de la dosis equivalente de levodopa (LEDD).

**Implementado:** LEDD **no** entra en el modelo primario. Se analiza por separado como
posible mediador.

**Razón.** La medicación dopaminérgica es consecuencia de la severidad de la enfermedad y a su
vez modifica tanto el dolor como la función motora: es una variable intermedia. Incluirla como
covariable en el modelo primario bloquearía parte del efecto que se quiere estimar.

---

## Consecuencias

- El capítulo de Métodos **debe declarar explícitamente** estas cuatro desviaciones y su
  justificación. No basta con implementarlas.
- Los análisis prometidos por el protocolo y no adoptados como primarios (multinomial por
  terciles, logística binaria agrupando los dos terciles superiores) se reportan igualmente
  como sensibilidad, de modo que ningún compromiso del protocolo queda sin cumplir.
- Los supuestos que el protocolo comprometió verificar (VIF < 5, IIA por Hausman-McFadden,
  proporcionalidad de odds por test de Brant) se verifican y reportan aunque el modelo
  primario haya cambiado, porque siguen aplicando a los análisis de sensibilidad.
