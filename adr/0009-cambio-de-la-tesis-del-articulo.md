# ADR 0009: La tesis del artículo cambia

- **Fecha:** 2026-08-07
- **Estado:** Aceptada
- **Se apoya en:** [ADR 0006](0006-resolucion-de-la-discrepancia-direccional.md), [ADR 0008](0008-refutacion-y-preespecificacion.md), [ADR 0010](0010-atricion-y-confusion-variable-en-el-tiempo.md)
- **Afecta a:** título, Resumen, Introducción, Discusión, Conclusiones

## Contexto

El artículo se había planteado para sostener que el dolor predice el deterioro
motor, con el fenotipo rígido-acinético como mecanismo. Los análisis no sostienen
ninguna de las dos cosas.

## Lo que los datos no permiten afirmar

**Que el dolor prediga la progresión motora.** La interacción del dolor basal con
el tiempo en el modelo mixto es nula (p = 0,189; con ponderación por censura,
p = 0,249), y coincide con lo que ya había encontrado el Aim 4.2 por otra vía
(p = 0,557). Tres estimaciones independientes dicen lo mismo.

**Que exista precedencia temporal en ningún sentido.** Ver el ADR 0006.

**Que el fenotipo motor modifique la asociación.** Ver el ADR 0008.

## Lo que sí sostienen

1. El dolor se asocia con un **nivel** de severidad motora consistentemente más
   alto a lo largo de todo el seguimiento: +1,005 puntos por punto de dolor basal
   (p = 0,002), estable bajo ponderación por censura (+1,088, p < 0,001).
2. Existe una **covariación estable entre personas** de las dos series, r = 0,175
   (p = 0,006), que el modelo con interceptos aleatorios separa limpiamente de la
   dinámica intrapersonal.
3. Esa covariación **no desaparece** al tratar la dosis dopaminérgica como
   confusor variable en el tiempo afectado por la exposición previa, aunque se
   reduce en torno a un tercio: de 2,70 en la regresión estándar a 1,71 con
   ponderación por probabilidad inversa de tratamiento, con estimación g
   independiente en 1,65.
4. El dolor es **más frecuente en el fenotipo PIGD** (razón de momios 1,49), y el
   eje continuo del fenotipo explica entre un 23 % y un 40 % de la covariación
   estable, de modo que contribuye sin agotarla.
5. Entre siete síntomas basales, el dolor y las actividades de la vida diaria son
   los únicos que predicen la severidad motora a doce meses. El dolor sobrevive a
   la corrección de Benjamini-Hochberg (p = 0,030) pero no a la de Holm (p = 0,051).

## Decisión

**El artículo pasa a ser sobre coexistencia, no sobre precedencia.**

La afirmación central es que el dolor y la severidad motora covarían de forma
estable entre pacientes, sin que ninguno preceda al otro en la escala temporal
observable, y que esa covariación sobrevive al tratamiento formal de la
confusión variable en el tiempo. El fenotipo motor contribuye a explicarla pero
no la agota.

El artículo es, en buena parte, un artículo de resultados negativos bien
caracterizados. Se presenta como tal.

## Por qué esto es mejor y no un repliegue

- Es más difícil de refutar. Las afirmaciones que se retiran son precisamente las
  que un revisor habría atacado primero.
- El aparato metodológico se convierte en la aportación. La descomposición entre
  personas e intra persona es, según la revisión bibliográfica realizada, la
  primera aplicada a dolor y severidad motora en la enfermedad de Parkinson.
- Aporta un correctivo útil. La literatura de este campo asume dirección con
  frecuencia, casi siempre de lo motor al dolor, y este trabajo muestra que con
  seis olas y mil ciento noventa pacientes esa dirección no se distingue.

## Lo que hay que decir con claridad en el texto

Que la pregunta se replanteó después de ver los resultados. El artículo lo declara
en Métodos, con referencia a este registro, igual que la tesis declaró en su
Anexo B el cambio del modelo primario. La reproducibilidad de este proyecto no se
apoya en haber acertado a la primera sino en dejar rastro de cada cambio.
