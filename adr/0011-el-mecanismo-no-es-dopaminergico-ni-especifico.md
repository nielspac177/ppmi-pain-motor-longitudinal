# ADR 0011: El mecanismo no es dopaminérgico, y no se puede afirmar que sea específico

- **Fecha:** 2026-08-07
- **Estado:** Aceptada en su decisión, con una afirmación retractada y un intervalo superado (ver el aviso)
- **Supera a:** [ADR 0009](0009-cambio-de-la-tesis-del-articulo.md) en su lectura mecanística
- **Afecta a:** título, Resumen, Resultados, Discusión, Conclusiones
- **Código:** `R/paper/09_dominios.R`, `R/paper/10_controles_negativos.R`, `R/paper/11_hipotesis.R`

> ## ⚠️ Aviso: una afirmación retractada y un intervalo superado
>
> La conclusión de este registro sigue en pie por completo: el mecanismo no es
> dopaminérgico y no se puede afirmar especificidad. Dos de sus apoyos no.
>
> **Retractada.** Este ADR dice que el resultado «replica y extiende el hallazgo
> de Liu 2020 en esta misma cohorte, que encontró que el dolor no figuraba entre
> los síntomas no motores asociados al transportador». Es falso. Se recuperó el
> trabajo y se comprobó que Liu 2020 nunca midió dolor: no hay ni una mención en
> el artículo. La afirmación entró heredada de un documento de traspaso anterior
> y sobrevivió a dos rondas de revisión. El resultado no replica nada, es una
> prueba nueva, y así se reporta ahora en el manuscrito. La cita se retiró del
> texto y este aviso existe para que no vuelva a entrar desde aquí.
>
> **Superado.** El intervalo de la diferencia entre pacientes y controles sanos
> se dio como +0,016 (IC 95 % −0,109 a 0,142). Ese intervalo venía de una
> transformación z de Fisher, que aplica el error estándar de una correlación
> observada a una latente y lo subestima 2,4 veces. Sustituido por un modelo de
> ecuaciones estructurales multigrupo con el parámetro derivado y contraste de
> Wald: la diferencia es +0,016 (IC 95 % −0,199 a 0,231; p = 0,885), y la
> igualdad de la correlación entre las tres cohortes no se rechaza
> (χ² = 0,59; 2 gl; p = 0,744).
>
> El intervalo corregido es más ancho, de modo que la corrección refuerza la
> conclusión de este ADR: con estos datos todavía menos se puede afirmar
> especificidad. Las cifras vigentes están en `outputs/paper/cifras.json`.

## Contexto

El ADR 0009 dejó el artículo en «dolor y severidad motora coexisten en un fenotipo
estable». Faltaba decir de qué está hecho ese fenotipo. Se contrastaron ocho
hipótesis mecanísticas, cada una con su predicción declarada antes de mirar el
resultado. Tres cambian lo que el artículo puede afirmar.

## Lo que se encontró

### El vínculo no es dopaminérgico

La severidad motora sigue a la captación estriatal del transportador de dopamina
(−0,219 DE por DE; p = 1×10⁻¹⁰). El dolor no la sigue en absoluto (+0,011; IC 95 %
−0,060 a 0,081; p = 0,766), y lo mismo en putamen y caudado por separado. Añadir
la captación al modelo deja la asociación entre dolor y severidad motora
inalterada, de 0,188 a 0,190.

~~Replica y extiende el hallazgo de Liu 2020 en esta misma cohorte, que encontró
que el dolor no figuraba entre los síntomas no motores asociados al
transportador.~~ RETRACTADO: Liu 2020 nunca midió dolor. Ver el aviso al
principio de este registro.

### La covariación excluye el temblor

Descompuesta la MDS-UPDRS III en cinco dominios que suman exactamente el total, la
asociación con el dolor está presente en bradicinesia (+0,169), axial (+0,187),
rigidez (+0,142) y bulbar (+0,141), y **ausente en temblor** (+0,005; p = 0,905).
El contraste entre el eje rigidez-bradicinesia y el temblor, dentro de los mismos
pacientes y el mismo instrumento, es de +0,172 (IC 95 % 0,073 a 0,271; p = 0,001).

Al ser una comparación interna a la escala, la varianza de método compartida no
puede explicarla.

### Un factor general da cuenta de toda la covariación

Un modelo de un factor sobre los cinco dominios más dolor y MoCA ajusta bien. Las
cargas son 0,81 en bradicinesia, 0,71 en rigidez, 0,67 en bulbar, 0,60 en axial,
0,23 en dolor, −0,21 en MoCA y 0,04 en temblor, que no carga.

Retirado ese factor, **no queda covariación positiva residual**: la correlación
residual es −0,121 (p = 0,0006).

## Decisión

**El artículo pasa a afirmar que el dolor es un indicador débil de una dimensión
general de carga, no dopaminérgica y no específica de lo motor.** Se retira la
afirmación de mecanismo compartido propio de la enfermedad.

El título cambia en consecuencia.

## Lo que obliga a no afirmar especificidad

Refitear el modelo idéntico en las otras cohortes de PPMI da r = 0,213 en 1 744
prodrómicos y r = 0,143 en 307 controles sanos, frente a r = 0,159 en pacientes.
La diferencia entre pacientes y controles es de +0,016 (IC 95 % −0,109 a 0,142).

Ese contraste **no es concluyente**: con 307 controles el intervalo admite tanto
la ausencia de correlación como una correlación mayor que la de los pacientes. No
demuestra equivalencia, y presentarlo como tal repetiría el error de confundir «no
significativo» con «equivalente» que ya se documentó en este proyecto.

Lo que sí impide es afirmar especificidad. La estimación puntual en controles es
próxima a la de pacientes, y se obtuvo pese a una desviación de la puntuación
motora de 3,10 frente a 11,64, de modo que la restricción del recorrido opera
contra la lectura deflacionaria y aun así no la desmiente.

## Una limitación que el contraste de H4 obliga a declarar

La correlación intraclase del dolor es de 0,392, la más baja de las cuatro medidas
examinadas (motor 0,535; MoCA 0,595; GDS 0,626). Sólo el 39 % de su varianza está
entre personas.

Eso afecta directamente a la interpretación de las vías intrapersonales nulas.
Promediar seis olas mejora la fiabilidad del componente entre personas pero no la
de las desviaciones intrapersonales, de modo que el patrón observado, rasgo que
sobrevive y dinámica intrapersonal que no, es también lo que produciría una
fiabilidad insuficiente. **Las dos explicaciones no se distinguen con estos datos y
el artículo lo dice.**

## Hipótesis que no se sostuvieron

- **H4, punto de ajuste constitucional.** Refutada: el dolor es la medida menos de
  rasgo, no la más.
- **H6, carga de alfa-sinucleína.** Interacción nula (p = 0,657), pero con 56
  negativos al SAA frente a 669 positivos el contraste no tiene potencia.
- **H7, genotipo GBA.** Interacción nula (p = 0,124) y en dirección contraria a la
  prevista: la asociación está ausente en los 83 portadores. Infrapotenciada.
- **H8, vía periférica.** Sin gradiente entre miembro inferior y superior
  (diferencia p = 0,184).

Se reportan las cuatro. Una hipótesis contrastada y no sostenida es un resultado.

## Consecuencias

- El artículo gana un mecanismo negativo fuerte (no es dopaminérgico) y pierde la
  afirmación de especificidad, que no estaba sostenida.
- La correlación del dolor con el MoCA deja de ser una limitación incómoda y pasa
  a ser parte del hallazgo: es lo que predice una dimensión de carga difusa.
- Los contrastes infrapotenciados (H6, H7 y el de controles) se reportan con su
  potencia y no como evidencia de ausencia.
