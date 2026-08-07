# ADR 0002: Fidelidad al plan de análisis registrado

- **Fecha:** 2026-08-06
- **Estado:** Aceptada
- **Supera a:** [ADR 0001](0001-desviaciones-protocolo.md)
- **Decide:** Niels Pacheco-Barrios (asesor)
- **Afecta a:** capítulo de Métodos y Resultados; `R/02_analisis_principal.R`

## Contexto

El ADR 0001 decidió apartarse del plan de análisis registrado en tres puntos: usar regresión
lineal en lugar de multinomial, eliminar Hoehn & Yahr del ajuste y añadir covariables
psicoafectivas. Al ejecutar ambas versiones del análisis se obtuvo lo siguiente:

| Modelo | β del dolor (por punto) | p |
|---|---|---|
| Registrado (multinomial con H&Y) | OR 1.16 / 1.21 | 0.47 / 0.40 |
| Registrado, versión lineal, con H&Y | +0.86 | 0.037 |
| Desviado (lineal, sin H&Y) | +1.94 (presencia) | 0.022 |

Es decir: **la conclusión del estudio dependía de la decisión de covariables**, y esa decisión
se tomó después de haber visto los datos. Ese es precisamente el grado de libertad que un
protocolo registrado existe para eliminar.

Además, la premisa empírica del ADR 0001 resultó incorrecta. Se afirmó que Hoehn & Yahr y la
MDS-UPDRS III "miden el mismo constructo con distinto instrumento". La correlación de Spearman
observada es **ρ = 0.559**: sustancial, pero muy lejos de la equivalencia que se alegó.

## Decisión

**El análisis primario es el registrado en el protocolo, sin excepciones**: regresión logística
multinomial sobre los terciles de la MDS-UPDRS III (referencia = severidad baja), ajustada por
edad, sexo, duración de la enfermedad, estadio Hoehn & Yahr y MoCA.

Todo lo demás pasa a ser análisis de sensibilidad **etiquetado como tal**, y ninguno puede
sustituir al primario en el Resumen ni en las Conclusiones:

1. Regresión lineal múltiple sobre el puntaje continuo con EE robustos HC3, contemplada
   explícitamente por el propio protocolo (§4.7).
2. Regresión logística binaria agrupando los dos terciles superiores, también registrada.
3. El mismo modelo lineal **sin** Hoehn & Yahr. El argumento estructural del ADR 0001 sigue en
   pie (H&Y es una estadificación de la propia función motora, y ajustar por ella absorbe
   parte del efecto de interés), pero es un argumento *a priori* discutible, no un hecho
   demostrado. Se reporta el contraste completo y se deja que el lector juzgue. La diferencia
   entre ambas versiones es, en sí misma, un resultado del estudio.

Las covariables psicoafectivas (GDS, STAI, RBDSQ, SCOPA-AUT) **no** entran en el modelo
primario. Se describen en la Tabla 1 y se usan en el análisis exploratorio de ejes clínicos
(§4.5 del script), declarado como post hoc.

## Consecuencias

- **La hipótesis nula del protocolo no se rechaza.** Ningún análisis registrado alcanza
  significación: χ² p = 0.068; OR 1.16 (IC95% 0.78–1.71) y 1.21 (0.78–1.89); logística binaria
  OR 1.18 (0.82–1.70). El estudio informa una asociación nula, no una asociación positiva.
- El intervalo de confianza del mayor efecto plausible sigue por debajo de la diferencia mínima
  clínicamente importante de la MDS-UPDRS III (≈3.25 puntos, Horvath 2015). El resultado es
  por tanto un **nulo informativo**, no un estudio sin potencia: se descarta un efecto de
  magnitud clínicamente relevante.
- Los Métodos deben declarar que se verificaron los tres supuestos comprometidos (VIF < 5,
  IIA por Hausman-McFadden, odds proporcionales por Brant) y reportar sus resultados, se
  cumplan o no.
- La Discusión debe explicar por qué el modelo sin H&Y da un resultado distinto, en lugar de
  ocultarlo. Es el punto metodológicamente más instructivo del trabajo.
