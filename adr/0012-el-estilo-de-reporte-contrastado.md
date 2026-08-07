# ADR 0012: El confusor de estilo de reporte se contrasta, no se concede

- **Fecha:** 2026-08-07
- **Estado:** Aceptada
- **Modifica a:** [ADR 0011](0011-el-mecanismo-no-es-dopaminergico-ni-especifico.md)
- **Código:** `R/paper/15_estilo_de_reporte.R`

## Contexto

Una revisión independiente señaló que la explicación más económica del único
resultado positivo del artículo no es biológica sino de medida. Zolfaghari 2022,
en esta misma cohorte, muestra que quienes reportan más síntomas están igual o
menos afectados en la exploración y en los biomarcadores. Una tendencia estable a
reportar produciría por sí sola una correlación de rasgo entre el dolor y
cualquier otra medida, la produciría igual en controles sanos, y se amplificaría
cuando las dos variables son autoinformadas. El artículo observa las tres cosas.

Declararlo en Limitaciones era necesario y no suficiente: el dato para
contrastarlo ya estaba en la base.

## Decisión

Se construye un índice de tendencia a reportar y se contrasta.

**Índice primario.** Residuo de la MDS-UPDRS Parte II sobre la Parte III,
promediado por paciente. Un valor positivo marca a quien refiere más discapacidad
de la que el examinador objetiva. No usa el ítem de dolor.

**Índice alternativo.** Suma de los otros ítems no motores del mismo
cuestionario. Existe porque el primero es ortogonal a la Parte III por
construcción, y un lector tiene derecho a descontar la mitad del contraste por
esa razón.

## Lo que se encontró

El confusor **existe y es grande**: el índice es estable a un año (r = 0,663) y
se asocia con el dolor en +0,419 DE (p = 3×10⁻²⁹). Una parte sustancial de lo
que el ítem 1.9 mide es tendencia a reportar y no nocicepción.

Pero **no explica la asociación con la puntuación explorada**:

| Desenlace | Índice primario | Índice alternativo |
| --- | --- | --- |
| Parte III (explorada) | 0,173 → 0,224 | 0,173 → 0,144 (p = 0,0015) |
| Parte II (autoinformada) | 0,448 → 0,104 (−77 %) | 0,448 → 0,276 (−38 %) |

Con los dos índices, la atenuación es mucho mayor en la escala que comparte
método con la exposición.

## Consecuencias

- La correlación tres veces mayor que se obtiene con la Parte II es en su mayor
  parte varianza de método compartida. El artículo lo dice, con la cifra.
- La pregunta que el artículo declaraba no poder resolver queda resuelta.
- Limitaciones pasa de conceder el confusor a reportar su contraste, y declara lo
  que el contraste **no** descarta: una tendencia a reportar que siga a la
  severidad explorada real, que ningún índice construido con autoinforme puede
  separar.
