# ADR 0008: Refutación de dos resultados favorables y preespecificación

- **Fecha:** 2026-08-07
- **Estado:** Aceptada
- **Afecta a:** Resultados, Discusión, alcance de las afirmaciones
- **Código:** `R/paper/02_refutacion_riclpm.R`, `R/paper/03_fenotipo.R`

## Contexto

Dos resultados aparecieron con signo favorable a la hipótesis del artículo y
fueron sometidos a refutación antes de aceptarlos. Ninguno de los dos sobrevivió
en la forma en que se presentaba. Este documento registra qué se hizo y qué queda
en pie, porque la decisión de no reportarlos como hallazgos cambia el artículo.

## Resultado 1: la vía intrapersonal de dolor a severidad motora

El modelo de panel cruzado con interceptos aleatorios ([ADR 0006](0006-resolucion-de-la-discrepancia-direccional.md))
dejaba en pie un rezago cruzado intrapersonal de dolor a motor, con
+0,966 (0,204 a 1,727), p = 0,013. Se sometió a siete comprobaciones.

| Comprobación | Resultado |
| --- | --- |
| Restricciones de igualdad entre olas | **Se rechazan** (p = 0,041) |
| Rezago libre por ola | Significativo en **1 de 5** olas, la primera |
| Sólo las tres primeras olas, menos atrición | p = 0,246 |
| Con variables auxiliares basales | p = 0,009 |
| Dolor dicotomizado | p = 0,075 |
| Desenlace motor en estado ON | p = 0,278 |
| Control negativo, MoCA como desenlace | p = 0,391 |

Sobrevive en 2 de 6 especificaciones, y el modelo restringido que lo produce está
formalmente rechazado frente al libre. El efecto se concentra en la transición de
la basal a los 12 meses y desaparece en el resto del seguimiento.

**Decisión.** No se declara establecido. Se reporta con sus siete comprobaciones y
se interpreta como no sostenido. El control negativo sí funciona, lo que respalda
que el aparato no genera señal espuria de forma indiscriminada.

## Resultado 2: la modificación del efecto por fenotipo motor

La hipótesis del plan era que el efecto del dolor sobre la severidad motora sería
mayor en el fenotipo rígido-acinético. Se ejecutó una rejilla de dieciséis
especificaciones, y dos alcanzaban significación, con el signo **contrario** al
esperado: el efecto era mayor en el fenotipo de temblor dominante.

**Preespecificación.** La especificación primaria se declara como la que prescribe
el plan del artículo: desenlace MDS-UPDRS III completa, exposición ordinal,
fenotipo clasificado en la basal. Da −1,276 (−3,653 a 1,101), **p = 0,293**.

**Multiplicidad.** De los ocho contrastes de PIGD frente a temblor dominante, dos
tienen p por debajo de 0,05 sin corregir. Tras Holm no queda ninguno, y tras
Benjamini-Hochberg tampoco.

**Contraste de método.** El resultado nominalmente significativo usaba la razón
construida con los dieciséis ítems. Al reconstruirla sólo con ítems del examinador
(p = 0,655) o sólo con ítems autoinformados (p = 0,564), desaparece en ambos. Un
efecto real debería aparecer al menos en uno de los dos componentes.

**Decisión.** El fenotipo motor **no modifica** la asociación entre dolor y
severidad motora en estos datos. Se reporta como resultado negativo con su
potencia, no como tendencia.

## Lo que sí queda en pie

- El dolor **es más frecuente e intenso en el fenotipo PIGD**: razón de momios
  ordinal 1,49 (1,06 a 2,08), p = 0,022, ajustada. Coincide en dirección con Ren
  2020, con magnitud menor.
- La **correlación de rasgo** entre dolor y severidad motora, r = 0,175, p = 0,006,
  robusta en cuatro de cinco especificaciones sustantivas.
- Condicionar sobre el eje continuo del fenotipo **atenúa esa covariación** entre
  un 23 % y un 40 % según el desenlace, de modo que el fenotipo explica una parte
  y no toda.

## Una limitación que el control negativo obliga a declarar

En el control negativo con el MoCA como desenlace, la correlación de rasgo no es
nula: r = −0,157, p = 0,033. La covariación estable del dolor **no es específica**
de la severidad motora, y se extiende a la función cognitiva.

Eso deja viva la explicación rival de que el dolor marque un perfil general de
mayor afectación y no un vínculo particular con lo motor. El artículo la expone en
la Discusión en lugar de omitirla. Conviene notar que no contradice el control
negativo longitudinal, que es otra cosa: el dolor basal no predice el **cambio**
del MoCA (p = 0,204), pero sí covaría con su **nivel**.

## Consecuencias

- El artículo pasa a tener dos resultados negativos bien caracterizados en lugar
  de dos hallazgos frágiles. Es menos vistoso y más difícil de refutar.
- Toda rejilla de especificaciones que se ejecute en este proyecto debe declarar
  su especificación primaria antes de mirar los resultados y reportar la
  corrección por multiplicidad. Sin excepciones.
