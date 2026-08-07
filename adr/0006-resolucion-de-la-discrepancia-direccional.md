# ADR 0006: Resolución de la discrepancia direccional

- **Fecha:** 2026-08-07
- **Estado:** Aceptada
- **Modifica a:** [ADR 0005](0005-cambio-de-modelo-primario.md), cuyo apoyo temporal queda retirado
- **Afecta a:** afirmaciones de direccionalidad, Discusión, argumento de sobreajuste
- **Código:** `R/paper/01_direccionalidad.R`, `R/paper/02_refutacion_riclpm.R`

## Contexto

Había dos análisis en contradicción abierta.

El Aim 4 (mayo de 2026) estimó los dos rezagos cruzados sobre todas las visitas y
encontró que ambos eran significativos, con la dirección motor a dolor unas tres
veces más fuerte en escala estandarizada. Un análisis posterior, restringido a la
ventana de la basal a los 12 meses, concluyó lo contrario: el dolor basal predecía
el motor a 12 meses (p = 0,009) y el motor basal no predecía el dolor (p = 0,155).
De ahí salió la afirmación de asimetría direccional que el ADR 0005 usa como
apoyo empírico de su argumento de sobreajuste.

Las dos cosas no podían ser ciertas a la vez. Hasta resolverlo no se podía
afirmar direccionalidad en ninguno de los dos sentidos.

## Lo que se encontró

Se examinaron cuatro explicaciones candidatas y dos resultaron ciertas.

### La asimetría de la ventana única era un artefacto del conjunto de análisis

Los dos modelos de la ventana no se ajustaban sobre las mismas personas. El de
dolor a motor exigía dolor basal y motor a 12 meses; el de motor a dolor exigía
motor basal y dolor a 12 meses. Como el dolor está disponible en más visitas que
la puntuación motora, el segundo modelo podía usar más casos, pero el análisis
original los restringió al panel completo común.

Sobre la muestra corregida del ADR 0003:

| Conjunto | dolor → motor | motor → dolor |
| --- | --- | --- |
| Panel completo común, n = 698 | +1,072, p = 0,003 | +0,0051, **p = 0,116** |
| Conjunto propio de cada modelo | +1,003 (n = 742), p = 0,005 | +0,0073 (n = 825), **p = 0,015** |

La conclusión de asimetría depende por completo de esa elección. Con el conjunto
máximo de cada dirección, las dos son significativas. La diferencia entre p = 0,116
y p = 0,015 es de potencia, no de dirección: las dos estimaciones puntuales son
positivas en ambos conjuntos.

Esto es un caso de la trampa ya documentada en el proyecto, elegir la
especificación por su resultado, y no se sostiene.

### Los retardos irregulares no explicaban nada

Sólo el 3,0 % de los pares de visitas consecutivas observadas no son adyacentes.
Añadir el tiempo real transcurrido, o restringir a pares adyacentes, deja los
coeficientes prácticamente iguales. La advertencia del script original era
razonable pero el problema es menor de lo que sugería.

### La explicación sustantiva: entre personas frente a intra persona

Un modelo rezagado con intercepto aleatorio no separa la covariación estable
entre personas de la dinámica intrapersonal. Si el dolor y la severidad motora
coexisten en un perfil estable, los dos rezagos cruzados salen significativos por
la correlación de rasgo, sin que ninguno preceda al otro.

Se contrastó el panel cruzado clásico frente al panel cruzado con interceptos
aleatorios (Hamaker, Kuiper y Grasman, 2015):

| Modelo | CFI | RMSEA | SRMR | dolor → motor | motor → dolor |
| --- | --- | --- | --- | --- | --- |
| Panel cruzado clásico | 0,877 | 0,114 | 0,112 | p = 0,004 | p = 0,008 |
| Con interceptos aleatorios | 0,960 | 0,067 | 0,069 | p = 0,013 | **p = 0,132** |

El modelo con interceptos aleatorios ajusta claramente mejor. En él la dirección
motor a dolor desaparece, y aparece una correlación de rasgo entre las dos series
de r = 0,175 (p = 0,006).

El resultado del Aim 4, dos rezagos significativos, se explica: es lo que produce
un panel cruzado clásico cuando existe covariación estable entre personas y el
modelo no la separa.

## Decisión

1. **El artículo no afirma direccionalidad en ninguno de los dos sentidos.** Ni
   que el dolor preceda al deterioro motor ni lo contrario.
2. **El ADR 0005 pierde su apoyo temporal.** Su argumento estructural sobre qué
   mide el Hoehn & Yahr se mantiene intacto, porque no dependía de los datos, pero
   la evidencia longitudinal de asimetría que se citaba como refuerzo se retira.
   El ADR 0004, que la recoge en su sección de evidencia longitudinal, queda
   igualmente corregido en ese punto.
3. **El modelo con interceptos aleatorios es la especificación primaria** para
   cualquier afirmación sobre la relación temporal entre las dos series.
4. **La vía intrapersonal de dolor a motor no se declara establecida**, por lo
   que se documenta en el [ADR 0008](0008-refutacion-y-preespecificacion.md).

## Consecuencias

- La pregunta del artículo cambia. Ver [ADR 0009](0009-cambio-de-la-tesis-del-articulo.md).
- La tesis ya entregada no queda invalidada: es transversal y no afirma
  direccionalidad. Lo que queda corregido es el material longitudinal preliminar
  de mayo y agosto de 2026, que sí la afirmaba, y que pasa a estar superado por
  este registro.
- Cualquier análisis futuro sobre estas dos series debe comparar las dos
  direcciones **sobre el mismo conjunto de filas**, y declararlo.
