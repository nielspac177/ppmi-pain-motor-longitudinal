# ADR 0004: El ajuste por el estadio de Hoehn & Yahr: qué se decide y qué no

- **Fecha:** 2026-08-06
- **Estado:** Aceptada
- **Complementa a:** [ADR 0002](0002-fidelidad-al-protocolo-registrado.md)
- **Afecta a:** interpretación del modelo primario; §4.1 y §4.3 de la Discusión

## Contexto

El resultado del estudio cambia según se incluya o no el estadio de Hoehn & Yahr
entre las covariables. Con él, la presencia de dolor no se asocia con la severidad
motora (β = +0,85; p = 0,228). Sin él, sí (β = +1,94; p = 0,022).

El ADR 0002 dejó la disyuntiva abierta y resolvió el conflicto por fidelidad al
protocolo. Este documento la analiza como lo que es: una cuestión de estructura
causal, no de preferencia estadística.

## Las dos lecturas posibles

**(a) Sobreajuste.** El Hoehn & Yahr está en la vía causal entre el dolor y la
puntuación motora, o es un marcador descendente del propio desenlace. Ajustar por
él bloquea parte del efecto que se quiere estimar y sesga hacia el nulo
(Schisterman 2009; Hernán y Robins, fig. 18.4).

**(b) Confusor sustituto.** Existe una severidad latente que causa a la vez el
dolor y la puntuación motora. El Hoehn & Yahr es una medida imperfecta de esa
severidad, y ajustar por él controla parcialmente la confusión, dejando confusión
residual (Hernán y Robins, §9.3 y Fine Point 7.2).

## Por qué los datos no lo resuelven

Hernán y Robins son explícitos: dada una terna de variables sin independencias, la
distribución conjunta es compatible con varios grafos causales, de modo que **la
decisión de ajustar debe apoyarse en información externa a los datos**. Añaden que
esto vale incluso cuando se conoce el orden temporal.

En este estudio la restricción es mayor: el dolor, el estadio y la puntuación
motora se miden en la misma visita. No hay orden temporal que invocar.

## La información externa disponible

1. **Por construcción**, el Hoehn & Yahr es una estadificación de la función
   motora: lateralidad, compromiso axial e inestabilidad postural (Hoehn y Yahr,
   1967). No es una causa separada del desenlace sino una medición gruesa del
   mismo constructo. Condicionar sobre una medición del desenlace no es control de
   confusión.
2. **La correlación observada (ρ = 0,559)** es demasiado alta para tratarlo como
   covariable independiente y demasiado baja para que el ajuste controle la
   severidad latente por completo. Bajo la lectura (b) quedaría confusión
   residual, de modo que ninguna de las dos lecturas justifica interpretar el
   modelo ajustado como el efecto total.
3. **El estadio de Hoehn & Yahr fue el único término que incumplió
   individualmente el supuesto de odds proporcionales** (p = 0,006), lo que indica
   que no se comporta como una covariable ordinaria en este modelo.

## Evidencia longitudinal (fuera del alcance de la tesis)

Un análisis exploratorio con la estructura longitudinal de PPMI, realizado para
orientar la interpretación y **no incluido en la tesis**, encontró asimetría
direccional: el dolor basal predice el estadio a los 12 meses ajustando por el
estadio basal (p = 0,016), mientras que el estadio basal no predice el dolor
(p = 0,42). Y entre los siete síntomas basales examinados, el dolor fue el único
no motor que predijo la puntuación motora futura; depresión, ansiedad, sueño,
disfunción autonómica y somnolencia fueron todos nulos.

Ese material es **sugestivo, no concluyente**: los horizontes largos son
inconsistentes, la comparación entre ANCOVA y puntuación de cambio indica que
parte del efecto es regresión a la media, la interacción dolor × tiempo en el
modelo mixto es nula, y los *E-values* son bajos. Se documenta aquí porque
informa la decisión, y corresponde al análisis longitudinal previsto como trabajo
posterior.

## Decisión

1. **El modelo primario sigue siendo el registrado**, con Hoehn & Yahr. La
   fidelidad al plan preinscrito no se negocia por un argumento posterior, por
   sólido que parezca.
2. **La interpretación se corrige.** El modelo primario no estima el efecto total
   que plantea el objetivo del estudio, sino un efecto neto del estadio. Lo que
   muestra es que *el dolor no aporta información sobre la severidad motora por
   encima de la que ya aporta el estadio*, no que ambos sean independientes.
3. **La Discusión expone las dos lecturas, la evidencia externa a favor de cada
   una y el hecho de que el diseño transversal no permite dirimirlas.**
4. **La afirmación de irrelevancia clínica se acota mediante una prueba de
   equivalencia** y no se generaliza más allá de donde esa prueba la respalda.

## Consecuencias

- Ni el Resumen ni las Conclusiones pueden afirmar que no existe asociación. La
  asociación cruda existe y es pequeña (0,17 desviaciones estándar; correlación
  parcial 0,116). Lo que no sobrevive al ajuste por estadio es su independencia.
- La pregunta queda formalmente abierta, y esa es la respuesta honesta que puede
  dar un estudio transversal. Cerrarla exige el orden temporal.
- Un tercer matiz, de fondo: el dolor es un **estado**, no una intervención. «El
  efecto de tener dolor» no define un contrafactual sin especificar cómo se
  intervendría (analgesia, tratamiento de la distonía, control dopaminérgico), y
  cada intervención tendría un efecto distinto. Lo que este trabajo estima es una
  asociación ajustada.
