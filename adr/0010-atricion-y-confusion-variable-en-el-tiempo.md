# ADR 0010: Atrición y confusión variable en el tiempo

- **Fecha:** 2026-08-07
- **Estado:** Aceptada
- **Afecta a:** Métodos, Resultados, análisis 2 y 3
- **Código:** `R/paper/04_longitudinal.R`, `R/paper/05_msm_ledd.R`

## Contexto

El material preliminar señalaba dos problemas sin resolver: la atrición, que pasa
de 711 participantes en la visita de doce meses a 236 en la de cinco años, y la
dosis dopaminérgica equivalente como confusor variable en el tiempo afectado por
la exposición previa.

## Atrición: qué se encontró

La pérdida de seguimiento **no está asociada con la exposición**. El dolor basal
no predice la permanencia en ninguno de los cinco horizontes (todas las p por
encima de 0,12). Sí lo predice la **severidad motora basal**, con fuerza creciente:
razón de momios de 0,967 por punto en la visita de cinco años (p < 0,001). Los
pacientes más afectados abandonan.

Esa estructura importa. La censura depende del desenlace, no de la exposición, de
modo que sesga las estimaciones de nivel y de pendiente pero no confunde la
asociación entre las dos series de la forma más dañina posible.

**Decisión.** Se aplica ponderación por probabilidad inversa de censura, con pesos
estabilizados y truncado en los percentiles 1 y 99, y se reportan las versiones
ponderada y sin ponderar de cada resultado longitudinal. Los pesos resultan
próximos a uno (media entre 0,966 y 0,999, recorrido de 0,46 a 2,24) y las
estimaciones apenas se mueven, lo cual es coherente con que la censura no dependa
de la exposición.

Reportar los pesos y su recorrido es parte de la decisión: unos pesos cercanos a
uno son un resultado, no una formalidad, porque acotan cuánto puede haber
distorsionado la atrición.

## Confusión variable en el tiempo: qué se encontró

Se comprobó empíricamente el supuesto estructural antes de aplicar el método, en
lugar de darlo por bueno.

- El dolor previo predice la dosis actual condicionando en la dosis previa:
  +18,3 mg (−2,2 a 38,9), p = 0,080.
- La dosis previa predice el dolor actual condicionando en el dolor previo:
  p = 0,031.

Hay retroalimentación en los dos sentidos, débil pero presente, que es exactamente
la estructura para la que la regresión convencional falla.

**Decisión.** Modelo estructural marginal con ponderación por probabilidad inversa
de tratamiento estabilizada, con estimación g por sustitución como comprobación
independiente, porque sus supuestos de modelado son distintos.

| Especificación | Estimación | IC 95 % |
| --- | --- | --- |
| Regresión estándar sin ajustar por la dosis | 2,696 | 1,428 a 3,964 |
| Regresión estándar ajustando por la dosis | 2,612 | 1,336 a 3,887 |
| Modelo estructural marginal | 1,706 | 0,717 a 2,670 |
| Estimación g por sustitución | 1,652 | 0,721 a 2,594 |

Las dos aproximaciones causales coinciden y las dos convencionales sobreestiman en
torno a un 55 %. El diagnóstico de balance confirma que la ponderación funciona: la
diferencia estandarizada de la dosis previa entre expuestos y no expuestos pasa de
0,141 a 0,071.

## Dos decisiones de varianza

**Los intervalos del modelo estructural marginal se calculan por remuestreo de
pacientes, no con el sándwich.** El error estándar sándwich trata los pesos como
conocidos cuando en realidad están estimados, y resulta anticonservador. Se
remuestrean pacientes completos, que son la unidad independiente, y **los pesos se
reestiman dentro de cada réplica**. El intervalo resultante (0,717 a 2,670) es más
estrecho que el sándwich (0,384 a 3,028), lo que indica que aquí domina la
variabilidad del propio ajuste.

**El E-value se calcula sobre la escala estandarizada**, con `evalues.OLS` y la
desviación estándar del desenlace, no sobre el coeficiente crudo. Es un error que
este equipo ya cometió en otro proyecto, donde un E-value de 45,26 resultó ser
2,53 al corregirlo, y no se repite. El valor obtenido es 1,41 puntual y 1,18 en el
límite del intervalo: un factor de confusión no medido de magnitud modesta
bastaría para anular la asociación, y así hay que escribirlo.

## Consecuencias

- Ningún resultado longitudinal del artículo se presenta sin su versión ponderada.
- La afirmación causal se acota expresamente. El dolor es un **estado**, no una
  intervención, y «el efecto de tener dolor» no define un contrafactual sin
  especificar cómo se intervendría. Lo que estos modelos estiman es un contraste
  ponderado bajo una estructura causal explícita, no el efecto de un tratamiento
  asignable. El artículo lo dice.
