# Encargo de continuación: seguir mejorando el artículo hasta agotar lo factible

> Documento para un agente que retoma el trabajo con contexto limpio. Sustituye a
> [`04-prompt-para-revision-independiente.md`](04-prompt-para-revision-independiente.md),
> que era solo para una ronda de revisión. Este cubre el ciclo completo: revisar,
> analizar, buscar literatura, rehacer figuras, y decidir cuándo parar.
>
> Fecha de corte: 7 de agosto de 2026. Estado: cuatro rondas de revisión, 181
> pruebas de regresión en verde, 47 referencias citadas de 165 verificadas.

---

## 📋 El encargo, listo para copiar

```
Vas a continuar un artículo científico sobre dolor y severidad motora en la
enfermedad de Parkinson, con datos de PPMI. Ya ha pasado cuatro rondas de
revisión por pares y 181 pruebas de regresión están en verde. Tu trabajo NO es
empezar de cero ni repetir lo hecho: es encontrar lo que queda y decidir con
honestidad cuándo ya no queda nada que merezca la pena.

EL REPOSITORIO
  <repo>/            (privado, con los datos)
  https://github.com/nielspac177/ppmi-pain-motor-longitudinal   (público, sin datos)

LEE PRIMERO, en este orden:
  docs/paper/05-encargo-de-continuacion.md    este documento
  manuscript/paper-compuesto.md               el manuscrito compuesto
  docs/paper/04-prompt-para-revision-independiente.md   la ronda anterior
  adr/0006 a adr/0011                         las decisiones que cambiaron algo
  docs/dags-longitudinales.md                 los supuestos causales

SKILLS QUE DEBES USAR, y cuándo
  /literature-review     antes de afirmar que algo es novedoso o que falta
  /paper-lookup          para recuperar y verificar cada referencia por PMID
  /deep-research         cuando una pregunta necesite varias fuentes cruzadas
  /scientific-critical-thinking   al evaluar si una afirmación aguanta
  /peer-review           para redactar cada informe de revisión
  /statistical-analysis  antes de elegir un contraste nuevo
  /figure-qa             OBLIGATORIO tras generar cualquier figura
  /critique-figures      antes de dar una figura por buena
  /scientific-visualization  si hay que rehacer una figura desde cero
  /markdown-mermaid-writing  para cualquier diagrama nuevo
  /latex                 para las versiones tipográficas (TikZ)
  /architecture-decision-records   para cada decisión que cambie un resultado
  /the-humanizer         antes de cerrar cualquier bloque de prosa nueva
  /clinical-numbers-audit  antes de dar por buena cualquier tanda de cifras
  /verify-claims         sobre las afirmaciones que no vengan de una tabla

EL CICLO, que repites hasta que se agote

  PASO 1. REVISIÓN. Lanza DOS revisores en paralelo, con contexto limpio y
  roles distintos: uno estadístico (inferencia causal, SEM, multiplicidad) y
  otro clínico (trastornos del movimiento, dolor en Parkinson, PPMI). A CADA
  uno dale la lista explícita de lo que el autor AFIRMA haber corregido, para
  que lo verifique contra el código y no contra la palabra del autor. Pedir una
  revisión genérica devuelve generalidades; este formato produjo casi todos los
  hallazgos de las cuatro rondas anteriores.

  PASO 2. VERIFICACIÓN. Antes de aplicar nada, comprueba tú mismo cada
  acusación grave contra la tabla o el código. Los revisores se equivocan: en la
  ronda 2 uno leyó mal una tabla y acusó de un problema de integridad que no
  existía, aunque su versión afilada del mismo punto sí era válida.

  PASO 3. APLICACIÓN. Corrige, y por cada corrección que cambie un resultado
  escribe un ADR nuevo y una prueba de regresión que falle si el problema
  reaparece. Sin la prueba, la corrección se deshace sola en la ronda siguiente.

  PASO 4. LITERATURA. Cada dos rondas, repite la validación bibliográfica
  completa: recupera cada referencia citada por PMID y comprueba que el
  manuscrito dice lo que la fuente dice. Este proyecto ha encontrado TRES citas
  que atribuían a un trabajo algo que no contenía, y las tres sobrevivieron a
  varias rondas.

  PASO 5. DECISIÓN. Después de cada ronda, responde por escrito: ¿lo que
  encontró esta ronda es de menor entidad que lo de la anterior? Si dos rondas
  seguidas solo devuelven cuestiones menores de redacción, para. Si una ronda
  devuelve un error de análisis, sigue.

CUÁNDO PARAR, explícitamente
  Para cuando se cumpla cualquiera de estas:
    - dos rondas consecutivas sin ningún hallazgo que cambie una cifra
    - lo que queda exige datos que PPMI no tiene
    - lo que queda exige una decisión del autor, no del analista (revista,
      orden de autoría, alcance)
  NO pares solo porque las pruebas estén en verde. Las pruebas comprueban que
  nada se movió, no que nada esté mal.

REGLAS NO NEGOCIABLES
  - Los datos de PPMI no se versionan nunca. La CI lo verifica en cada cambio.
  - Ninguna cifra se teclea: salen de outputs/paper/cifras.json.
  - Ninguna referencia se cita sin verificarla por PMID o DOI.
  - Toda figura se ABRE y se mira antes de darla por buena. Varios defectos de
    este proyecto solo eran visibles en la imagen renderizada.
  - Cuando encuentres un resultado que te guste, intenta refutarlo antes de
    quedártelo.
  - Escribe en español; el manuscrito va en inglés. Sin rayas tipográficas.
```

---

## 🎯 Qué sostiene el artículo, en una tabla

| Afirmación | Cifra | Dónde |
| --- | --- | --- |
| El panel cruzado clásico fabrica bidireccionalidad | p = 0,004 y 0,008 | `t01_direccionalidad_sem.csv` |
| Con interceptos aleatorios libres, ninguna dirección aguanta | 0 y 1 de 5 olas | `t01_sem_libre_resumen.csv` |
| Queda covariación estable entre personas | r = 0,152, ajustada 0,171 | `t01_correlacion_rasgo_libre.csv` |
| Marca nivel, no pendiente | +1,396 frente a p = 0,189 | `t04_mixto.csv` |
| No es dopaminérgica | dolor p = 0,766, motor p < 0,001 | `t11_h2_dat.csv` |
| No es específica del dolor | cinco análisis convergentes | varias |

---

## ⚠️ Lo que ya se corrigió, con su patrón

No repitas este trabajo, pero **sí busca más ejemplares de cada patrón**, porque
los tres se han repetido.

| Patrón | Ejemplares encontrados |
| --- | --- |
| **Cita que atribuye a una fuente algo que no contiene** | Liu 2020 citado por un resultado sobre dolor que nunca midió; VanderWeele 2019 por una distinción de escala que no menciona; Pautrat 2023 por una afirmación sobre estadios de Braak que contradice |
| **El texto no sigue al código** | Dos valores p intercambiados que invertían el argumento; una correlación atribuida a la variable equivocada; un marcador de plantilla imprimiendo la cifra de otra variable; Métodos afirmando un conjunto de ajuste que los modelos no llevan |
| **El código no hace lo que su propio comentario dice** | El comentario declara primario el modelo libre y el script extrae solo del restringido; una regla preespecificada evaluada y luego incumplida; etiquetas escalares en lavaan imponiendo igualdad entre grupos sin avisar |

Y errores de método, ya corregidos: residuo por puntuaciones factoriales que se
fabricaba a sí mismo, z de Fisher sobre una correlación latente, `lmer(weights=)`
como si fueran pesos de muestreo, tiempo sin centrar, ajuste por un descendiente
de la exposición presentado como control de confusión, aritmética de la DMCI
redondeada a la baja en la dirección conveniente.

---

## 🔭 Lo que queda abierto, por orden de valor

1. **El confusor de estilo de respuesta es el ataque más fuerte que sigue en
   pie.** Zolfaghari 2022, en esta misma cohorte, muestra que la Parte IB, que
   contiene el ítem de dolor, correlaciona 0,54 con la discapacidad motora
   autoinformada, y que quienes más reportan están igual o menos afectados en la
   exploración. Eso produciría nuestra correlación de rasgo sin ninguna biología.
   Está declarado en Limitaciones. **¿Se puede contrastar con lo que hay?** Una
   vía: construir un índice de tendencia a reportar con los ítems de la Parte I
   ajenos al dolor y ver si absorbe la correlación.
2. **El resumen sigue en 528 palabras**, contra 250 a 350 según revista.
3. **No hay figuras para los análisis 9 a 14.** Serían dominios, cohortes,
   hipótesis y clínicos. Hoy solo se reportan en tablas.
4. **Los ADR 0009 y 0011 están desactualizados**: citan cifras anteriores al
   centrado del tiempo y a la corrección del multigrupo, y el 0011 aún repite la
   afirmación retirada sobre Liu 2020. Necesitan marca de superado.
5. **El RI-CLPM no tiene pendiente aleatoria.** En una enfermedad que progresa
   2,29 puntos al año, la variación entre personas en la VELOCIDAD se mete en el
   componente intrapersonal. Un modelo de curva latente con residuos
   estructurados es el remedio estándar y no está hecho.
6. **La Parte II da r = 0,533 frente a 0,175 de la Parte III.** El artículo
   ofrece dos lecturas y se inclina por la de método compartido apoyándose en
   Hodgson 2026. ¿Hay forma de zanjarlo?

---

## 🚫 Lo que NO es factible, para que no se pierda tiempo

- **Neuropatía de fibra fina.** PPMI no tiene biopsia, QST ni electroneurografía.
- **Subtipos de dolor.** Haría falta la KPPS o la PD-PCS; PPMI tiene un ítem.
- **Conectómica de estimulación subtalámica.** No hay pacientes operados con
  imagen en esta muestra; sería otro estudio.
- **Aumentar la potencia del contraste con controles.** Son 307 y no hay más.

---

## 🔧 Reproducir

```bash
export PPMI_RAW_DIR=/ruta/a/los/csv/de/ppmi
make prep-paper   # fenotipo, cohortes, biomarcadores, analgésicos
make paper        # 14 análisis, figuras, cifras, manuscrito, pruebas
Rscript tests/test_paper.R        # 181 pruebas del artículo
Rscript tests/test_resultados.R   # 57 de la tesis, que NO debe moverse
```

Si `data/tidy_long.csv` deja de reproducir byte a byte, algo se ha roto: la
tesis transversal está cerrada y su pipeline es el control de integridad del
proyecto entero.
