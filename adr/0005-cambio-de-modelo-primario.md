# ADR 0005: Cambio del modelo primario: se retira el estadio de Hoehn & Yahr

- **Fecha:** 2026-08-06
- **Estado:** Aceptada
- **Supera parcialmente a:** [ADR 0002](0002-fidelidad-al-protocolo-registrado.md)
- **Se apoya en:** [ADR 0004](0004-ajuste-por-estadio.md)
- **Decide:** Niels Víctor Pacheco Barrios (asesor)
- **Afecta a:** modelo primario, Resumen, Resultados, Conclusiones, Anexo B

## Contexto

El protocolo registró como modelo primario una regresión logística multinomial
sobre los terciles de la MDS-UPDRS III ajustada por edad, sexo, duración de la
enfermedad, **estadio de Hoehn & Yahr** y MoCA.

El ADR 0002 mantuvo ese modelo como primario por fidelidad al plan preinscrito,
aun reconociendo la objeción de sobreajuste. El ADR 0004 examinó esa objeción con
el marco de inferencia causal de Hernán y Robins y concluyó que la lectura de
sobreajuste es la más plausible, pero dejó el modelo registrado como primario.

Este documento revierte esa última decisión.

## Decisión

**El modelo primario pasa a ser el que NO ajusta por el estadio de Hoehn & Yahr.**
El modelo literalmente registrado, con Hoehn & Yahr, se conserva como **modelo
secundario** y se reporta íntegro, con la misma prominencia, en la Tabla 3 y en la
Figura 4.

## Justificación

El argumento es **estructural y no depende del resultado**:

1. El estadio de Hoehn & Yahr es, por construcción, una estadificación de la
   función motora (lateralidad, compromiso axial e inestabilidad postural) es
   decir, una medición gruesa del propio desenlace. Condicionar sobre una medición
   del desenlace no es control de confusión sino sobreajuste.
2. La pregunta de investigación es el **efecto total** del dolor sobre la
   severidad motora. Un modelo que ajusta por un marcador del desenlace no estima
   ese efecto, sino uno neto del estadio.
3. La dirección del cambio era **predecible de antemano**: retirar del ajuste una
   variable situada en la vía causal aleja la estimación del nulo. No se trata,
   por tanto, de una elección orientada por un resultado sorprendente.

## Lo que hace legítimo este cambio, y lo que no

Cambiar el modelo primario después de ver los resultados es exactamente lo que un
plan de análisis registrado existe para impedir, y conviene decirlo sin rodeos.
Tres condiciones lo hacen aceptable aquí, y las tres deben cumplirse:

- **Se declara.** El cambio consta en el Anexo B de la tesis, en la Figura 2 de
  métodos y en este registro. No es silencioso.
- **Se reportan las dos versiones.** El modelo registrado no desaparece: aparece
  en la misma tabla y en la misma figura que el nuevo primario, y la Figura 4
  muestra las doce especificaciones a la vez. El lector puede reconstruir la
  decisión y discrepar.
- **La justificación es previa a los datos.** El razonamiento sobre qué mide el
  Hoehn & Yahr no depende de qué valor p produzca.

Lo que este cambio **no** autoriza es presentar el resultado como si hubiera sido
el plan desde el principio. La tesis debe decir, y dice, que el protocolo
registraba otro modelo.

## Consecuencias

- El resultado primario pasa a ser: razón de momios de 1,28 (IC 95 %: 0,88 a 1,85)
  para el tercil de severidad leve a media y de 1,47 (1,00 a 2,16; p = 0,048) para
  el de media a severa.
- De las **doce especificaciones** examinadas, **seis rechazan la hipótesis nula**:
  cuatro de las seis sin ajuste por estadio y dos de las seis con él. La Figura 4
  las muestra todas.
- La conclusión del estudio cambia de signo: pasa de «no se detecta asociación
  independiente» a «se detecta una asociación positiva de magnitud pequeña, que se
  atenúa hasta desaparecer al ajustar por una estadificación del propio desenlace».
- La Discusión pasa a organizarse alrededor de los **mecanismos fisiopatológicos
  compartidos** entre el dolor y la severidad motora, que es lo que hace plausible
  la asociación observada y lo que motiva la pregunta de investigación.
- El Anexo B incorpora una entrada específica sobre este cambio.
