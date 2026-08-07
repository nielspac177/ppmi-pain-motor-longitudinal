# Encargo para una revisión independiente del artículo

> Documento de traspaso para un agente con contexto limpio. Quien escribió el
> manuscrito es el peor situado para revisarlo: conoce las decisiones y las da
> por buenas. Este encargo existe para que otro las mire sin ese sesgo.
>
> Fecha de corte: 7 de agosto de 2026. Estado: tras tres rondas de revisión
> internas, 153 pruebas de regresión en verde.

---

## 📋 El encargo, listo para copiar

```
Vas a revisar de forma independiente un manuscrito científico sobre dolor y
severidad motora en la enfermedad de Parkinson, con datos de la cohorte PPMI.
Ya ha pasado tres rondas de revisión, así que lo fácil está corregido. Tu valor
está en lo que esas rondas no vieron.

EL REPOSITORIO
  <repo>/

LEE PRIMERO, en este orden:
  manuscript/paper-compuesto.md      el manuscrito con las cifras sustituidas
  docs/paper/04-prompt-para-revision-independiente.md   este documento
  adr/0006 a adr/0011                las decisiones que cambiaron un resultado
  docs/dags-longitudinales.md        los supuestos causales, en Mermaid

Y CUANDO NECESITES VERIFICAR ALGO:
  outputs/paper/tables/*.csv         72 tablas, una por resultado
  outputs/paper/cifras.json          las 404 cifras del texto
  R/paper/*.R  y  python/*.py        15 + 6 scripts, el análisis entero

REGLA DE ORO: no aceptes ninguna afirmación del manuscrito sin comprobarla
contra la tabla que la produce o contra el código que la calcula. Las tres
rondas anteriores encontraron, en este orden de gravedad: una afirmación
bibliográfica falsa, dos valores p intercambiados que invertían un argumento,
una correlación atribuida a la variable equivocada, un estimador mal nombrado,
un marcador de plantilla que imprimía la cifra de otra variable, y una
restricción de igualdad impuesta sin querer en un modelo multigrupo. Todas
existían en un texto que parecía correcto.

LO QUE TIENES QUE HACER, en cuatro pasadas

PASADA 1. VALIDACIÓN DE LA EVIDENCIA BIBLIOGRÁFICA
  Para CADA una de las 36 referencias citadas en el texto:
    a) recupera el registro real por PMID o DOI contra PubMed o Crossref
    b) comprueba que la afirmación del manuscrito es lo que el trabajo dice,
       no lo que su título sugiere
    c) marca toda cita donde el manuscrito extienda, suavice o invierta lo que
       la fuente sostiene
  Este proyecto ya publicó una vez que un trabajo "no encontró asociación con
  el dolor" cuando ese trabajo NUNCA MIDIÓ DOLOR. El error sobrevivió a dos
  rondas y venía heredado de un documento de traspaso anterior. Asume que hay
  más de esos.
  Presta atención especial a: Liu 2020 (PMID 32092703), Rukavina 2024
  (37587725), Defazio 2008 (18779422), Schrag 2015 (25435387), Helmich 2012 y
  2018 (22382359, 29119634), Simuni 2016, Horvath 2015 (26578041).

PASADA 2. BÚSQUEDA DE LO QUE FALTA
  Busca en PubMed, Europe PMC, OpenAlex y Google Scholar:
    a) ¿existe algún trabajo que ya haya hecho esto y no esté citado? El
       manuscrito afirma que no hay análisis previo de panel cruzado sobre
       dolor y función motora en Parkinson. Intenta refutarlo.
    b) ¿hay literatura que CONTRADIGA el hallazgo central y no aparezca?
    c) ¿hay trabajos de 2025 y 2026 que cambien el contexto?
  Repite la búsqueda con al menos tres formulaciones distintas antes de
  concluir que algo no existe.

PASADA 3. VERIFICACIÓN NUMÉRICA
  Toma 25 cifras del manuscrito al azar, de secciones distintas, y comprueba
  cada una contra su tabla. Reporta cualquier discrepancia con archivo, valor
  en el texto y valor en la tabla.
  Comprueba además que la MISMA cantidad no aparezca con dos valores en dos
  sitios. Ya pasó con la correlación de rasgo, que llegó a circular con cuatro
  valores distintos según qué modelo convenía a cada párrafo.

PASADA 4. CRÍTICA CIENTÍFICA
  Ahora sí, la revisión de fondo. Céntrate en lo que las rondas previas no
  cubrieron, no en repetirlas. En particular:
    a) ¿el reencuadre hacia "carga general no específica del dolor" está
       sostenido, o se ha pasado de frenada en la dirección contraria?
    b) ¿hay algún análisis que el manuscrito presente como confirmatorio y que
       en realidad sea exploratorio?
    c) ¿queda algún supuesto causal sin declarar en los DAGs?
    d) ¿qué haría falta para que este artículo fuese rechazado, y está
       protegido contra eso?

CÓMO ENTREGARLO
  Un informe en markdown con:
    - veredicto y revista objetivo realista
    - los errores encontrados, numerados, cada uno con archivo y evidencia
    - lo que hay que hacer, priorizado en bloqueante / importante / menor
    - las referencias nuevas que deberían citarse, con PMID verificado
  Si no encuentras nada en una pasada, dilo. Un informe que no encuentra nada
  es un resultado; un informe que inventa problemas para parecer riguroso hace
  perder el tiempo y erosiona la confianza en el resto.

RESTRICCIONES
  - Los datos de PPMI no se versionan nunca. El acuerdo de uso lo prohíbe.
  - Ninguna cifra se teclea a mano: salen de outputs/paper/cifras.json.
  - Ninguna referencia se cita sin verificarla contra PubMed o Crossref.
  - Toda decisión que cambie un resultado va a un ADR nuevo.
  - Escribe en español, registro académico. El manuscrito va en inglés.
  - Sin rayas tipográficas ni negritas de énfasis.
```

---

## 🎯 Qué sostiene el artículo ahora mismo

Para que la revisión sepa qué está atacando.

**La afirmación central.** El dolor y la severidad motora covarían como
características estables del paciente, y ninguno precede al otro a resolución
anual. La causalidad recíproca que un panel cruzado convencional produce sobre
estos mismos datos es un artefacto de no separar la variación entre personas de
la intrapersonal.

**Las cifras que lo sostienen.**

| Resultado | Valor |
| --- | --- |
| Panel cruzado clásico, ambas direcciones | p = 0,004 y p = 0,008 |
| Con interceptos aleatorios, motor a dolor | p = 0,132 |
| Ajuste, libre frente a clásico | CFI 0,963 vs 0,877; SRMR 0,044 vs 0,112 |
| Correlación de rasgo, modelo primario | r = 0,152 (p = 0,011) |
| Nivel frente a pendiente | +1,396 (p < 0,001) frente a p = 0,189 |
| Regresión estándar frente a ponderada | 2,696 frente a 1,706 |

**Las cinco líneas que dicen que no es específico del dolor.** Control negativo
de depresión que falla, diferencial de depresión que iguala al del dolor, factor
general que no deja residuo, correlación igual en controles sanos, y otros
síntomas no motores que covarían igual o más (insomnio r = 0,277 frente a
dolor 0,159).

---

## ⚠️ Lo que ya se corrigió, para que no se repita el trabajo

No hace falta volver sobre esto salvo que se encuentre que la corrección
introdujo otro problema.

| Corregido | Qué era |
| --- | --- |
| Residuo del factor general | Se regresaban indicadores sobre puntuaciones factoriales que los contenían, lo que fabricaba el residuo negativo que se reportaba |
| z de Fisher entre cohortes | Error estándar de una correlación observada aplicado a una latente; subestimaba 2,4 veces. Sustituido por SEM multigrupo |
| Multigrupo con dinámica restringida | Etiquetas escalares en lavaan se replican entre grupos e imponen igualdad sin avisar |
| «Estimación g» | No lo era: mantenía las covariables en valores observados |
| Regla preespecificada del MSM | Se declaró y se incumplió. Ahora el script la evalúa y degrada el modelo |
| `lmer(weights=)` | Pesos de precisión, no de muestreo. Sustituido por GEE robusto |
| Efecto de «nivel» | Era la asociación transversal basal por no centrar el tiempo |
| Analgésicos como confusor | Son descendientes de la exposición: mediación más colisión, no confusión |
| Liu 2020 | Se citaba como que no halló asociación con el dolor. Nunca midió dolor |

---

## 🧭 Lo que sigue abierto, y es donde más valor tiene una mirada nueva

1. **La fiabilidad de la exposición.** La correlación intraclase del dolor es
   0,392, la más baja de las cuatro medidas del artículo. Las vías
   intrapersonales nulas son compatibles con ausencia real de acoplamiento y con
   falta de señal, y el manuscrito dice que no puede distinguirlas. ¿Podría?
2. **El resumen sigue en 488 palabras**, por encima del límite de casi cualquier
   revista objetivo. El recorte depende de la revista.
3. **El repositorio público está desactualizado.** Tiene la versión del primer
   empuje, sin ninguno de los catorce análisis posteriores.
4. **La Parte II autoinformada da una correlación de rasgo de 0,533**, más del
   triple que la Parte III. El manuscrito ofrece dos lecturas y no elige. ¿Hay
   forma de elegir con estos datos?

---

## 🔧 Cómo reproducir

```bash
export PPMI_RAW_DIR=/ruta/a/los/csv/de/ppmi
make prep-paper      # fenotipo, cohortes, biomarcadores, analgésicos
make paper           # los 14 análisis, figuras, cifras, manuscrito, pruebas
Rscript tests/test_paper.R        # 153 pruebas del artículo
Rscript tests/test_resultados.R   # 57 pruebas de la tesis, que no debe moverse
```

La tesis transversal está cerrada y su pipeline reproduce byte a byte. Si
`tidy_long.csv` cambia, algo se ha roto.

---

## 📌 Una nota sobre el método de revisión

Las tres rondas previas siguieron un patrón que funcionó y conviene mantener:
un revisor estadístico y otro clínico, cada uno con la lista explícita de lo que
el autor **afirma** haber corregido, para que lo verifiquen contra el código y no
contra la palabra del autor. Ese formato produjo la mayoría de los hallazgos.

Lo que no funcionó: pedir una revisión genérica. Devuelve generalidades.
