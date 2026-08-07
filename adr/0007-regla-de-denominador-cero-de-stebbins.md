# ADR 0007: La regla de denominador cero en la clasificación de Stebbins

- **Fecha:** 2026-08-07
- **Estado:** Aceptada
- **Afecta a:** `python/02_stebbins_phenotype.py`, toda la clasificación de fenotipo
- **Código:** `python/02_stebbins_phenotype.py`, `R/paper/03_fenotipo.R`

## Contexto

La clasificación de Stebbins define el fenotipo motor como el cociente entre la
media de once ítems de temblor y la media de cinco ítems de inestabilidad postural
y marcha, con cortes en 1,15 y 0,90.

En una cohorte de reciente diagnóstico, una parte considerable de los pacientes no
tiene ningún signo axial: la media del denominador es exactamente cero y el
cociente no está definido. En esta muestra ocurre en el **19,3 % de las visitas
analíticas de V04** y en el **25,5 % de las basales**.

El artículo original de Stebbins es de acceso cerrado y no se pudo verificar que
enuncie una regla para ese caso. Una revisión de trabajos que aplican el criterio
no encontró ninguno que declare una, ni ninguno que señale la ambigüedad.

Esto no es un detalle de implementación. Los afectados son sistemáticamente
distintos: MDS-UPDRS III media de 19,8 frente a 27,5, y dolor medio de 0,55 frente
a 0,91. Clasificarlos de una u otra forma mueve 125 pacientes entre el grupo de
temblor dominante y el indeterminado.

## Decisión

Se preespecifica la regla primaria y se reportan las tres.

**Primaria, convención de Jankovic.** Si la media de inestabilidad postural y
marcha es cero y la de temblor es mayor que cero, el paciente es temblor
dominante. Si las dos son cero, es indeterminado.

Se elige como primaria porque el criterio de Stebbins es la adaptación a la
MDS-UPDRS del cociente de Jankovic (1990), que sí resuelve el caso de esa forma, y
porque es sustantivamente coherente: un paciente con temblor y sin ningún signo
axial es el caso puro de temblor dominante, no un caso sin clasificar.

**Sensibilidad A, conservadora.** Todo denominador cero pasa a indeterminado.

**Sensibilidad B, exclusión.** Todo denominador cero queda sin clasificar.

## Justificación de que la decisión no orienta el resultado

La regla se fijó **antes** de ver su efecto sobre la asociación de interés, y las
tres variantes se ejecutan en el mismo script. El resultado principal del análisis
de fenotipo es prácticamente invariante:

| Regla | Interacción dolor × PIGD sobre la MDS-UPDRS III | p |
| --- | --- | --- |
| Jankovic (primaria) | −1,276 (−3,653 a 1,101) | 0,293 |
| Todo a indeterminado | −1,434 (−3,949 a 1,080) | 0,264 |
| Excluidos | −1,474 (−3,995 a 1,047) | 0,252 |

## Consecuencias

- La sección de métodos del artículo declara la regla, su justificación y la
  proporción de casos afectados. No se deja implícita.
- La columna `denominador_cero` queda en `data/stebbins.csv` para que cualquier
  revisor pueda rehacer el contraste.
- Se recomienda a quien reutilice este código en otra cohorte que compruebe la
  proporción afectada antes de dar la clasificación por buena: en cohortes con
  enfermedad más avanzada el problema es menor, pero no desaparece.
