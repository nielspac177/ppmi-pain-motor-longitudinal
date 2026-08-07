# DAGs causales del artículo longitudinal

Este documento hace explícitas las suposiciones causales de los modelos que la
tesis transversal no podía plantear. Continúa la notación de
[`dags-causales.md`](dags-causales.md) y la convención de Hernán y Robins: un
recuadro alrededor de una variable significa que el análisis condiciona sobre
ella.[^hernan]

La tesis dejó la pregunta abierta porque el dolor, el estadio y la puntuación
motora se miden el mismo día y no hay orden temporal que invocar. Con seis olas
anuales sí lo hay, pero aparecen tres estructuras nuevas que el diseño transversal
no tenía que resolver: la separación entre la variación estable entre personas y
la variación intrapersonal, la censura por atrición, y un confusor variable en el
tiempo afectado por la exposición previa. Cada una tiene su grafo.

---

## 📐 Notación

| Símbolo | Significado |
| --- | --- |
| `A(t)` | Exposición en la visita t: dolor autoinformado (MDS-UPDRS ítem 1.9) |
| `Y(t)` | Desenlace en la visita t: severidad motora (MDS-UPDRS III, estado OFF) |
| `L(t)` | Confusor variable en el tiempo: dosis dopaminérgica equivalente |
| `V` | Covariables basales fijas: edad, sexo, duración de la enfermedad, MoCA |
| `RI` | Intercepto aleatorio: el nivel propio y estable de cada persona |
| `C(t)` | Censura: el paciente deja de acudir a partir de la visita t |
| `U` | Variable no medida |
| Recuadro doble | El análisis condiciona sobre esa variable |

---

## 🔀 DAG 1: por qué el panel cruzado clásico fabrica bidireccionalidad

_Es el grafo que explica el resultado central del artículo. Si cada persona tiene
un nivel propio y estable de dolor y otro de severidad motora, y esos dos niveles
covarían, entonces las observaciones repetidas de una misma persona están todas
desplazadas en la misma dirección. Un modelo que no separa ese desplazamiento lo
lee como si el valor pasado de una serie predijera el valor futuro de la otra,
cuando lo único que ocurre es que ambas series pertenecen a la misma persona._

```mermaid
flowchart LR
    accTitle: Como la covariacion estable entre personas produce rezagos cruzados espurios
    accDescr: Los interceptos aleatorios RI del dolor y de lo motor covarian entre si y causan cada una de las observaciones repetidas de su propia serie. Un modelo que no los separa atribuye esa covariacion a los rezagos cruzados entre olas, y por eso encuentra significacion en ambas direcciones sin que exista ninguna dinamica intrapersonal.

    ria["🧍 RI_A<br/>Nivel propio<br/>de dolor"]
    riy["🧍 RI_Y<br/>Nivel propio<br/>motor"]

    a1["😖 A(1)"]
    a2["😖 A(2)"]
    a3["😖 A(3)"]
    y1["🚶 Y(1)"]
    y2["🚶 Y(2)"]
    y3["🚶 Y(3)"]

    ria --> a1
    ria --> a2
    ria --> a3
    riy --> y1
    riy --> y2
    riy --> y3
    ria <--> riy

    a1 -.->|"rezago espurio"| y2
    y1 -.->|"rezago espurio"| a2
    a2 -.-> y3
    y2 -.-> a3

    classDef rasgo fill:#dbeafe,stroke:#2563eb,stroke-width:2px,color:#1e3a5f
    classDef obs fill:#f3f4f6,stroke:#6b7280,stroke-width:1.5px,color:#374151

    class ria,riy rasgo
    class a1,a2,a3,y1,y2,y3 obs
```

La flecha discontinua no es un efecto: es lo que el estimador informa cuando no
puede ver los interceptos. En estos datos el modelo clásico da significación en
las dos direcciones, y el que separa los interceptos anula una y deja la otra
frágil, con mejor ajuste.

---

## 🎯 DAG 2: qué estima cada componente una vez separados

_Separar los interceptos parte la pregunta en dos, y las dos son legítimas pero
distintas. La correlación entre `RI_A` y `RI_Y` responde a si las personas con
más dolor son las que tienen más afectación motora. Los rezagos entre las
desviaciones `w` responden a si, cuando a una persona le sube el dolor por encima
de su propio nivel, su puntuación motora sube después. El artículo encuentra lo
primero y no lo segundo._

```mermaid
flowchart TB
    accTitle: Descomposicion entre personas e intra persona
    accDescr: La parte superior contiene los interceptos aleatorios y su covarianza, que es el componente entre personas. La parte inferior contiene las desviaciones intrapersonales y sus rezagos cruzados. El articulo estima las dos y solo la primera sobrevive.

    subgraph entre["Componente ENTRE personas (lo que el artículo encuentra)"]
        ria["🧍 RI_A"]
        riy["🧍 RI_Y"]
        ria <-->|"r = 0,152<br/>p = 0,011"| riy
    end

    subgraph intra["Componente INTRA persona (lo que el artículo NO encuentra)"]
        wa1["📉 wA(t-1)"]
        wy1["📉 wY(t-1)"]
        wa2["📉 wA(t)"]
        wy2["📉 wY(t)"]
        wa1 -->|"autorregresivo"| wa2
        wy1 -->|"autorregresivo"| wy2
        wa1 -.->|"cruzado, frágil"| wy2
        wy1 -.->|"cruzado, nulo"| wa2
    end

    classDef hallado fill:#dcfce7,stroke:#16a34a,stroke-width:2px,color:#14532d
    classDef nulo fill:#f3f4f6,stroke:#6b7280,stroke-width:1.5px,stroke-dasharray:4 3,color:#374151

    class ria,riy hallado
    class wa1,wy1,wa2,wy2 nulo
```

---

## 💊 DAG 3: la dosis dopaminérgica como confusor afectado por la exposición

_Es el escenario canónico en que la regresión convencional falla en las dos
direcciones. La dosis responde a los síntomas y a su vez afecta a los síntomas
posteriores, de modo que ajustar por ella bloquea parte del efecto y además abre
un camino de colisión si existe una causa común no medida de la dosis y del
desenlace. Ajustar y no ajustar son las dos opciones malas._

```mermaid
flowchart LR
    accTitle: Dosis dopaminergica como confusor variable en el tiempo afectado por la exposicion previa
    accDescr: El dolor en t0 influye en la dosis en t1, que a su vez influye en el dolor en t1 y en la severidad motora en t2. Una causa comun no medida U afecta a la dosis y al desenlace. Condicionar sobre la dosis bloquea parte de la via y abre un camino de colision; no condicionar deja confusion por indicacion.

    a0["😖 A(t0)<br/>Dolor"]
    l1["💊 L(t1)<br/>Dosis"]
    a1["😖 A(t1)<br/>Dolor"]
    y2["🚶 Y(t2)<br/>Motor"]
    u["❓ U<br/>no medida"]

    a0 --> l1
    a0 --> a1
    l1 --> a1
    l1 --> y2
    a1 --> y2
    u -.-> l1
    u -.-> y2

    classDef expo fill:#dbeafe,stroke:#2563eb,stroke-width:2px,color:#1e3a5f
    classDef trat fill:#fef9c3,stroke:#ca8a04,stroke-width:2px,color:#713f12
    classDef nomed fill:#f3f4f6,stroke:#6b7280,stroke-width:2px,stroke-dasharray:5 3,color:#374151

    class a0,a1,y2 expo
    class l1 trat
    class u nomed
```

> ⚠️ **Lo que este grafo justifica, y lo que no.** La estructura justifica un modelo
> estructural marginal **sólo si la flecha `A(t0) → L(t1)` existe**. En estos datos
> ese coeficiente es de 18,3 mg con intervalo de −2,17 a 38,85 y p = 0,080, es decir,
> no la sostiene. Por la regla preespecificada en el propio código, el modelo
> estructural marginal queda como análisis de sensibilidad y no como principal. Ver
> el [ADR 0010](../adr/0010-atricion-y-confusion-variable-en-el-tiempo.md).

---

## 📉 DAG 4: la censura por atrición

_La retención cae del 97 % en la basal al 20 % a los cinco años. Lo que decide si
eso sesga es de qué depende la censura. Aquí depende del desenlace, no de la
exposición: la severidad motora basal predice el abandono y el dolor basal no lo
predice en ningún horizonte._

```mermaid
flowchart LR
    accTitle: Estructura de la censura por atricion
    accDescr: La severidad motora previa causa la censura, y la censura determina que observaciones se analizan. El dolor previo no predice la censura en ningun horizonte, de modo que la perdida de seguimiento depende del desenlace pero no de la exposicion.

    a["😖 A<br/>Dolor basal"]
    y0["🚶 Y(t-1)<br/>Motor previo"]
    c["✂️ C(t)<br/>Censura"]
    y1["🚶 Y(t)<br/>Motor observado"]
    v["📋 V<br/>Basales"]

    y0 -->|"OR 0,967 por punto<br/>p &lt; 0,001"| c
    a -.->|"todas las p &gt; 0,12"| c
    c ==> y1
    y0 --> y1
    a --> y1
    v --> a
    v --> y0
    v --> c

    classDef expo fill:#dbeafe,stroke:#2563eb,stroke-width:2px,color:#1e3a5f
    classDef cens fill:#fee2e2,stroke:#dc2626,stroke-width:2px,color:#7f1d1d
    classDef base fill:#f3f4f6,stroke:#6b7280,stroke-width:1.5px,color:#374151

    class a,y0,y1 expo
    class c cens
    class v base
```

Que la censura dependa del desenlace y no de la exposición explica por qué los
pesos por probabilidad inversa de censura quedan próximos a uno y por qué apenas
mueven las estimaciones. Es un resultado, no una formalidad: acota cuánto puede
haber distorsionado la atrición.

---

## 🔍 DAG 5: la estructura de especificidad que el artículo contrasta

_El grafo que hay que descartar antes de atribuir la covariación a algo propio del
dolor. Si existe una dimensión general de carga que causa a la vez el dolor, la
severidad motora y el estado cognitivo, la correlación observada no dice nada
específico sobre el dolor. El artículo contrasta esta estructura de cuatro
maneras, y no consigue descartarla._

```mermaid
flowchart TB
    accTitle: Dimension general de carga como explicacion rival
    accDescr: Un factor general G causa el dolor, los dominios motores y la cognicion. Si esa estructura es cierta, la correlacion entre dolor y severidad motora esta enteramente mediada por G y no indica nada especifico del dolor. Los cuatro contrastes que el articulo aplica aparecen como comprobaciones sobre el grafo.

    g["⚖️ G<br/>Dimensión general<br/>de carga"]
    a["😖 Dolor<br/>carga 0,23"]
    rig["🦿 Rigidez<br/>0,71"]
    bra["🐢 Bradicinesia<br/>0,81"]
    axi["🚶 Axial<br/>0,60"]
    tem["🤲 Temblor<br/>0,04, no carga"]
    moc["🧠 MoCA<br/>−0,21"]

    g --> a
    g --> rig
    g --> bra
    g --> axi
    g -.->|"no"| tem
    g --> moc

    classDef gen fill:#dbeafe,stroke:#2563eb,stroke-width:2px,color:#1e3a5f
    classDef ind fill:#f3f4f6,stroke:#6b7280,stroke-width:1.5px,color:#374151
    classDef fuera fill:#ffffff,stroke:#9ca3af,stroke-width:1.5px,stroke-dasharray:4 3,color:#6b7280

    class g gen
    class a,rig,bra,axi,moc ind
    class tem fuera
```

Los cuatro contrastes y su veredicto:

| Contraste | Predicción si `G` es la explicación | Resultado |
| --- | --- | --- |
| Liberar la covarianza residual dolor-motor | no mejora el ajuste | no mejora (p = 0,227) |
| Depresión como exposición alternativa | mismo patrón que el dolor | mismo patrón (p = 0,001 en ambos) |
| Cognición como desenlace alternativo | también covaría con el dolor | covaría (r = −0,157) |
| Controles sanos y prodrómicos | correlación similar sin la enfermedad | similar, aunque el contraste no concluye |

Ninguno descarta `G`. El artículo lo declara en lugar de sortearlo.

---

## 🧾 Qué se decide con estos grafos

| Decisión | Grafo que la sostiene | Registro |
| --- | --- | --- |
| El modelo con interceptos aleatorios es el primario | DAG 1 y 2 | [ADR 0006](../adr/0006-resolucion-de-la-discrepancia-direccional.md) |
| El modelo estructural marginal es sensibilidad, no principal | DAG 3 | [ADR 0010](../adr/0010-atricion-y-confusion-variable-en-el-tiempo.md) |
| Se pondera por censura y se reportan las dos versiones | DAG 4 | [ADR 0010](../adr/0010-atricion-y-confusion-variable-en-el-tiempo.md) |
| No se afirma especificidad de la covariación | DAG 5 | [ADR 0011](../adr/0011-el-mecanismo-no-es-dopaminergico-ni-especifico.md) |

---

[^hernan]: Hernán MA, Robins JM. *Causal Inference: What If*. Boca Raton: Chapman & Hall/CRC; 2020. https://miguelhernan.org/whatifbook
