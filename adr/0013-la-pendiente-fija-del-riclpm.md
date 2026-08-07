# 0013. El supuesto de pendiente fija del RI-CLPM, contrastado

- Fecha: 7 de agosto de 2026
- Estado: aceptada
- Sustituye a: nada
- Relacionada con: [0006](0006-resolucion-de-la-discrepancia-direccional.md),
  [0010](0010-atricion-y-confusion-variable-en-el-tiempo.md)

## Contexto

El modelo de panel cruzado con interceptos aleatorios descompone cada serie en un
nivel propio y estable de la persona mas desviaciones respecto de ese nivel. La
descomposicion presupone que la persona no se mueve: su nivel es una constante y
todo lo demas es fluctuacion. En una enfermedad que progresa, ese presupuesto es
falso por construccion. En esta cohorte la severidad motora avanza 2,29 puntos al
ano, y si las personas difieren tambien en la VELOCIDAD con la que avanzan, esa
variacion entre personas no tiene ningun parametro que ocupar y termina dentro
del componente que el modelo llama intrapersonal. Los rezagos cruzados dejarian
entonces de estimarse sobre desviaciones respecto de un nivel estable y pasarian
a estimarse sobre desviaciones respecto de un nivel mas una deriva individual no
modelada.

La objecion estaba anotada como pendiente en el encargo de continuacion y era el
ultimo analisis de la lista que podia mover una cifra.

## Decision

Se ajusta el remedio estandar, un modelo de curva latente con residuos
estructurados (Curran y colaboradores, 2014, PMID 24364798): a cada constructo se
le anade una pendiente latente ademas del intercepto, con cargas fijadas al
tiempo, de modo que los rezagos cruzados pasan a estimarse sobre desviaciones
respecto de la trayectoria individual. Se reporta como analisis de sensibilidad.
El modelo con intercepto aleatorio sigue siendo el primario, por comparabilidad
con la literatura que lo usa y porque el BIC lo prefiere.

Las cargas de la pendiente se centran en el punto medio del seguimiento. Esto no
es cosmetico y es la parte de la decision que mas importa; se justifica abajo.

## Consecuencias

El supuesto estaba violado. Anadir las pendientes latentes mejora el ajuste de
forma sustancial: razon de verosimilitud 39,5 con 7 grados de libertad,
p < 0,001; CFI de 0,960 a 0,983; RMSEA de 0,067 a 0,047; SRMR de 0,069 a 0,043.
El AIC prefiere el modelo con pendiente (33.093 frente a 33.126) y el BIC prefiere
el modelo sin ella (33.316 frente a 33.314), que es lo que cabe esperar cuando
una ganancia grande de ajuste cuesta siete parametros en una muestra amplia.

La violacion no es simetrica entre los dos constructos, y eso es informativo. La
varianza entre personas de la pendiente es apreciable en la severidad motora
(1,704, p = 0,079) y no se distingue de cero en el dolor (0,006, p = 0,376). Es
exactamente el perfil que deberian tener una escala motora que progresa y un
item unico que no.

Que el supuesto estuviera violado no implica que su violacion distorsionara el
resultado, y aqui no lo hizo. La correlacion de rasgo pasa de 0,175 a 0,189, un
desplazamiento de 0,014, y sigue siendo significativa (p = 0,010). El articulo
puede ahora sostener con una cifra lo que antes solo podia sostener con un
argumento.

Lo que si se mueve es la unica via intrapersonal que quedaba nominalmente
significativa en el modelo restringido, de dolor a severidad motora posterior:
pasa de p = 0,013 a p = 0,160. La conclusion es la misma a la que ya habia
llegado el analisis ola por ola, por otro camino: esa via era en parte un
artefacto de obligar a todos los pacientes a progresar al mismo ritmo. El
resultado refuerza la negativa del articulo en lugar de contradecirla, que es la
direccion menos comoda y por eso conviene decirlo explicitamente.

## Por que las cargas van centradas, y por que se reportan las dos

El primer ajuste uso cargas de 0 a 5 y dio una correlacion de rasgo de 0,242, un
salto grande respecto de 0,175 que invitaba a titular que la pendiente aleatoria
reforzaba el hallazgo central. Era falso.

Con cargas que arrancan en cero, el intercepto latente deja de ser el nivel medio
de la persona y pasa a ser su nivel BASAL, porque es el punto donde la pendiente
vale cero. La correlacion entre interceptos deja entonces de responder a la
pregunta del articulo, que es si el dolor y la severidad motora covarian como
caracteristicas estables, y pasa a responder a otra: si covarian sus niveles
iniciales. Con las cargas centradas el intercepto es el nivel a mitad del
seguimiento, que es la cantidad comparable con el intercepto aleatorio.

Las dos parametrizaciones son el MISMO modelo con otro origen del tiempo, y el
script lo comprueba: la diferencia de AIC entre ellas es 0,0002. Mismo ajuste,
misma verosimilitud, y sin embargo 0,242 frente a 0,189. Una cifra que cambia con
el origen del tiempo sin que cambie el ajuste es una propiedad de la
parametrizacion y no de los datos. Ambas se reportan en el manuscrito por ese
motivo: la comparacion es la prueba de que la mayor de las dos no significa lo
que parecia significar.

Es el mismo error que ya se cometio y se corrigio una vez en este proyecto,
cuando el efecto de nivel del modelo mixto resulto ser la seccion transversal
basal por no centrar el tiempo (ADR 0010). Reaparecio en un modelo distinto, con
otra forma, y volvio a producir la cifra conveniente. Se deja constancia porque
la leccion no es sobre el centrado sino sobre la reincidencia: el error se
detecto por desconfiar de un resultado que gustaba, no por revisar el codigo.

## Alternativas descartadas

- **Reportar el modelo con pendiente como primario.** El AIC lo apoya y el BIC
  no, la varianza de la pendiente del dolor es nula, y la comparabilidad con la
  literatura de panel cruzado tiene valor. Sensibilidad, no primario.
- **Anadir la pendiente solo al constructo motor.** Es la version teoricamente
  motivada, dado que la varianza de la pendiente del dolor es cero, pero elegir
  que constructo la lleva DESPUES de ver las varianzas es preespecificacion al
  reves. No se ajusta.
- **Usar el tiempo real en lugar del nominal.** El modelo es de ocasiones fijas.
  Las visitas se separan un ano con desviaciones de semanas, comprobado en el
  analisis 0, y el modelo mixto ya usa el intervalo real para la pregunta de
  nivel frente a pendiente.
