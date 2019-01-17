Igor – Cómo instalar?

1- Antes comenzar la instalación chequear que tenés los siguientes elementos: 
i) archivo instalador de igor
ii) los siguientes files: ElectroCoolStart.ipf, IHCICaLeakSubt.ipf, Calcium Imaging.ipf, jProtocols.ipf, M_abf.ipf, bpc_ReadAbf y ABFFIO.dll

2- Correr el instalador.

3- El programa está ahora instalado en la carpeta correspondiente del disco rígido (seguramente algo así como c:\Program Files(x86)\WaveMetrics\Igor Pro Folder). No obstante, muchas de las funciones del programa que fueron creadas en nuestro laboratorio (o en otros) se instalan aparte. Cada una de estas funciones se llaman familiarmente “macro” y están agrupadas (caprichosamente) en files con extensión .ipf. Los siguiente files .ipf son los que deben instalarse aparte: 
IHCICaLeakSubt.ipf
Calcium Imaging.ipf
jProtocols.ipf
M_abf.ipf

El primer paso para la instalación de estos macros es copiar los correspondientes files en una carpeta que NO se moverá mientras se use Igor. La carpeta puede ser por ejemplo así: C:\UsuarioXX\Macros.

4- El siguiente paso de la instalación es copiar el ElectroCoolStart.ipf al desktop. Luego hay que editar este file de la siguiente manera: Presionando botón derecho del mouse, elegir Editar con Notepad. Una vez abierto el notepad, editar las distintas líneas, copiando el path de la carpeta de macros utilizada en 3. Por ejemplo, si puse los files con macros en la carpeta “C:\UsuarioXX\Macros”, se debe escribir:

#include “c:UsuarioXX:Macros:xxxx” (van las comillas, reemplazar xxx por el nombre del file, y OJO NO VAN barras invertidas “\” o “/”. SI VAN los “:”)

Esto es necesario para CADA file que contenga macros. O sea, si se incluyen los files de macros que se detallan en el punto 3, son 5 líneas del tipo #include…..
Salvar estos cambios y mover el ElectroCoolStart.ipf a C:\Program Files (x86)\WaveMetrics\Igor Pro Folder\IgorProcedures. De este modo, cada vez que arranque Igor va a leer este file y va a ‘inicializar’ los macros incluidos en los files que fueron ‘incluidos’

5- finalmente agregar en la carpeta C:\Program Files (x86)\WaveMetrics\Igor Pro Folder\Igor Extensions (o similar) los siguientes files: bpc_ReadAbf y ABFFIO.dll
Estos files no son macros, son extensiones de algunos macros que vamos a utilizar.

6- Correr Igor y corroborar que no haya ningún error (bug) y que los macros estén cargados. Esto último se verifica de dos manera: en la barra de menúes deben aparecer las opciones “Efferents”, “INGEBI”, “Imaging”, “jProtocols”, y por otro lado, si cliqueas en “Windows” → “Procedure Windows” tiene que estar listado el file “IHCICaLeakSubt” y los demás files que se detallan en el punto 3.

7- Está todo listo!
7/Sep/2018
Instrucciones generales

Cuando Igor  arranca, carga las distintas funciones/macros diseñados en nuestro laboratorio (y otros), y por lo tanto, ya están incorporadas a la hora de empezar a trabajar. Una de las funciones adicionadas son las opciones de menúes que se observan en la barra superior. Allí se pueden observar opciones como “Efferents” (donde se encuentran macros para analizar experimentos eferentes, ver más abajo), o INGEBI, Imaging, jProtocols, etc. Clickeando sobre cualquiera de estos, aparecerán una lista de nombres que representan macros. Si seleccionamos alguno de estos, arranca el macro indicado.
Cualquier análisis en Igor arranca utilizando un file denominado ‘TemplateEffAnalysis5.pxp’, que llamamos familiarmente “templado”. En este file hay una serie de elementos (waves, variables globales, graficos, etc) que sirven para el resto de los macros. Sin éstos, los macros NO funcionan y NO hay análisis posible.
Algunos pasos iniciales para tener en cuenta:

- Abrir el templado y cambiar el nombre del file antes de arrancar el análisis de datos. Para no pisar el file original.

- Cómo importar registros de electrofisiología en Igor para analizar? (para files de imaging, ver más adelante)
	→ Existen tres macros diferentes para importar registros, uno para files de pClamp, otro para files de WinWCP, y otro para files de jClamp. A estos macros los llamamos “loaders” y están en el menú superior dentro de INGEBI (en el caso de pClamp y WinWCP) o jProtocols. Al clickear sobre el macro correspondiente, se abrirá una ventana de diálogo donde uno debe seleccionar el file que desee analizar.
	→ NOTA: por razones históricas adoptamos el formato de pClamp para nombrar files. Es decir: EC12805A_0003, que viene de: EC, iniciales del experimentador; “12”, los últimos dos dígitos del año del experimento; “8” del mes (de enero a septiembre se representa con el número de mes; y luego octubre con una O, noviembre con una N, y diciembre con una D); “05” el día del mes; “A” representa el orden de la célula registrada en el día (A, para la primera, B para la segunda, etc); y finalmente, “_0003” el número de file.
En el caso de WinWCP, luego de seleccionar el file para importar, el macro abre una ventana de diálogo para consultar las iniciales del experimentador  y el orden de la célula.
	→ Si la importación de files funcionó exitosamente, deberían aparecer una serie de “waves” nuevas en el Data Browser, que corresponden a cada uno de los sweeps (o episodio) y cada uno de los canales del file importado. Los sweeps serán numerados consecutivamente con un dígito (o más) que aparece después del número de file (y un “_”), y el número de canal con otro dígito (y otro “_”) después del sweep (ej: EC12805A_0003_9_1).

- Hay dos tipos principales de análisis de experimentos de electrofisiología que hacemos normalmente: 1) eferente, y 2) aferente. Se detallan a continuación


1) Análisis Eferente
Para analizar corrientes sinápticas eferentes usamos una familia de macros que están en el menú “Efferents”. Los dos macros principales son: el que sirve para analizar los eventos evocados (“Analysis on evoked synaptic current in trains or single”, que en realidad se llama EffAnalysisTrain), y el que sirve para eventos espontáneos (“Analysis of spontaneous currents”, MiniAnalDeconv). Para que este conjunto de macros funcionen hace falta: un file para analizar (es decir, un registro de corriente que conste de al menos 1 sweep), y que la tabla con los distintos parámetros (File, NSweeps, NEstimulos, etc) esté completa. Esta tabla está en el templado y la información requerida en ella consiste de:

a) File:		Nro del file a analizar. Por ej si el file es “EG16505A_0013_2_1”, correspondería el 13.
b) Nsweeps:	Número de sweeps (episodios) en el file (debe coincidir el número máximo alcanzado en la posición del “2” en el ejemplo anterior).
c) Freq (Hz):	Si se trata de un  tren (incluyendo el doble pulso), la frecuencia del mismo. En el caso de que sea un sólo estímulo, se indica “0”.
d) FactorUmbral:	Este número representa un umbral para la detección de corrientes sinápticas. Concretamente es un número que se multiplica por el ruido basal y determina un valor umbral de corriente. Un evento de amplitud mayor a este valor se considera éxito sináptico.
e) Win1:	Este es un valor te tiempo que funciona junto a “Time of artifact” (ver más abajo). Este último indica el punto en el tiempo donde se encuentra el estímulo eléctrico. El “Win1” es la ventana de tiempo que el macro “salta” y debe coincidir con duración del artefacto de estimulación. Es importante para que el macro “salte” el artefacto y NO lo confunda con un evento sináptico.
f) Win2:	Punto final de la búsqueda. Entre Win1 y Win2 se define la venta temporal de la búsqueda.
g) QeffF:	Factor umbral que opera sobre la carga (Q, integral de la corriente) del evento sináptico,  como criterio de detección de eventos. Similar a FactorUmbral, pero en Q. ATENCIÓN: es importante conservar el signo de la corriente a analizar. Es decir, agregar al QeffF un signo negativo “-” si se analizan eventos de corriente negativa (cationes entrantes), o positivo si se trata de una corriente positiva (cationes salientes).
h) MiniAmp:	No usar
i) MiniAnal starting point (s):	Punto temporal donde se empieza la búsqueda de eventos espontáneos. La idea es dejar afuera la parte del sweep donde está el estímulo eléctrico y los evocados.
j) MiniAnal Deconv Threshold:	Umbral para la detección de eventos espontáneos. Este valor depende de la “deconvolución” del trazo de corriente. Va entre xx y xx
g) Kinetic analysis (1: si, 0: no): 	Analiza la cinética de eventos evocados. Abre una ventana que muestra la corriente evocada en detalle (además del mismo trazo filtrado, superpuesto), y también la integral de este trazo. Sobre estos trazos calcula i) el “ancho medio” de la corriente sináptica, ii) el tiempo característica de caída de la misma (tau), iii) la integral del mismo, y finalmente iv) el tiempo característico de subida de la integral del trazo. Para cada uno de estos genera un wave con la información. ATENCIÓN: para cada evento detectado y ajustado abre una ventana de diálogo donde el usuario debe indicar si está satisfecho con el análisis (si: 1, no: 0).
h) Time of artifact:			Punto en el tiempo donde se produjo el estímulo dentro de cada sweep. Si este valor no está (NaN), busca automáticamente el artefacto.
i) Latency analysis (1: si, 0: no):	?

Como se mencionó, existen dos análisis básicos que realizamos con dos macros particulares: “Analysis on evoked synaptic current in trains or single” (que en realidad se llama EffAnalysisTrain), y “Analysis of spontaneous currents” (MiniAnalDeconv).

1) Análisis de eventos evocados
Una vez completada la tabla de parámetros e importado el file a analizar, se selecciona el macro dentro del menú de “Efferents” y listo. El macro arroja UN wave que se llama “AmplitudeWave_xx_1”, donde “xx” tiene el número del file analizado, en el caso en que el experimento tenga UN sólo estímulo (eso se indica dentro de la tabla de parámetros en Freq (Hz)). Si se trata de un tren (de al menos 2 estímulos), se generan tantos “AmplitudeWave_xx_y” como número de estímulos tenga en tren (indicado ). En cualquier caso, el macro genera un segundo wave, “Nfailures_xx”, donde se indican el número de fallas para el/los estímulos aplicados (también en este caso el “xx” refiere al número de file).
A partir de estos dos waves (AmplitudeWave y Nfailures), se pueden calcular múltiples variables que describen el funcionamiento de la sinapsis. También hay un macro para calcularlos automáticamente y se llama “PrintEffAnalysis”. Este macro escribe en el “Command Window” los valores calculados de probabilidad, contenido cuántico, etc.

2) Análisis de eventos espontáneos
El de espontaneos requiere más interacción con el usuario ya que éste tiene que “dar el ok” a cada evento detectado. El macro arranca “activando” automaticamente dos gráficos donde se muestran el trazo de corriente en la parte superior y la deconvolución en la inferior. Los dos gráficos tienen la misma información pero en distinta escala temporal (para mejor decisión). El macro arranca preguntando si el usuario desea guardar los trazos individuales de los eventos detectados exitosamente (1: si, 0: no). El macro busca eventos, en base a criterios indicados en la Tabla, y abre una ventana donde se debe indicar con un “1” si el usuario considera que se trata de un evento, “0” para rechazarlo.
Otras opciones?


Esto es de Lucas:
Además del de espontáneos y el de evocados yo uso un par más que me parecen bastante útiles. Varios ya existían, algunos los modifiqué; otros los hice de cero con ayuda de Marce. Son los siguientes:
1) “Delete Waves”, killabfWaves(): para borrar los files después de analizar y que no colapse todo
2) "Tren Promedio", TrenPromedio(): te da la amplitud promedio para cada pulso de un tren (contando fallas)
3) "Tren Promedio Evocados", TrenPromedioEvocados(): lo mismo, pero solamente considerando eventos exitosos
4) "Integrar trenes", IntegrarTrenes(): te da la carga promedio luego de cada pulso de un tren, y también el acumulado para todo el tiempo que dura el sweep (y te hace el promedio de esto último también)
5) "Probabilidad de Liberación para cada pulso", ProbLib(): se autoexplica
6) "Remover artefacto fit", RemoveArtifact_FillFit(): para sacar el artefacto y rellenar con un fiteo (yo le saqué esto último, pero igual está en el macro)
7) "Remover artefacto y calcular Q", RemocionArtefacto_Integra(): este se lo robé a Marce; saca el artefacto (sin fiteo creo) y te calcula la carga. Es bastante cómodo.
Análisis Aferente

Hay un serie de macros para analizar la corriente de calcio y eventos postsinápticos, que están todos en el menú, bajo el rótulo de INGEBI. Esta serie de macros requiere de parámetros correctamente descriptos que están en la Table1.

Tabla de parámetros (Table1)
Allí se encuentran 4 waves que describen el protocolo del experimento: TimeWave, AuxFitWave, VprotWave y ParamLeakSWave. Las filas de cada uno de estos waves (se excluye ParamLeakSWave) indica un paso en un protocolo de voltaje. TimeWave indica la duración, VprotWave indica el potencial aplicado en cada caso, y AuxFitWave indica diversas variables: i) en las filas con valores <0 se refiere a qué pasos utilizar para el leak subtraction (ver más abajo), ii) en las filas con valores >0 se indica en qué pasos analizar parámetros de corriente de calcio o eventos postsinápticos.
Los valores de TimeWave, AuxFitWave y VprotWave se utilizan para analizar cada uno de los sweeps de un file determinado. En el caso de que alguno de estos valores cambie de sweep a sweep en un file, este hecho se indica con un valor = 1000. Por ejemplo, si el potencial en el paso 4 cambia de un sweep a otro (en caso de una I-V), esto se indica con un valor de 1000 en el paso 4 del VprotWave. Los valores que toma este paso de potencial se listan en ParamLeakSWave, de tal modo que si el file tiene 8 sweeps, el ParamLeakSWave tiene que tener 8 elementos. De igual manera, si la duración de un paso cambia entre sweeps, se indica con un 1000 en el TimeWave, y los valores utilizados se listan en  ParamLeakSWave.

Análisis de corrientes de calcio
El primer paso para obtener los datos de amplitud, cinética, etc de la corriente de calcio, es sustraer el leak. Esto se realiza con el macro “Ultimate leak subtraction” en el menú INGEBI. Para que este macro funcione sólo se requiere que haya un file para analizar y que la tabla de parámetros esté correctamente completada. Al correr el macro aparece un cuadro de diálogo donde se pide el número de file a analizar, y además, si se desea analizar el canal 1 (generalmente el registro postsináptico) o el canal 2 (generalmente, IHC).
El resultado de “Ultimate leak subtraction” es una serie de waves, duplicadas a partir de cada sweep de los registros originales, sobre las que se aplicó la substracción. El leak se calcula a partir de 3 steps entre -80 y -60 mV. Luego se extrapola al resto de los potenciales utilizados en el experimento, asumiendo la linearidad.
Una vez realizada la sustracción, que revelaría la corriente de calcio “pura”, se pueden calcular otras variables como amplitud del pico, integral, cinética, etc. A saber:
- Con el macro “Ultimate Delay to onset”, se determina el delay entre el escalón de voltaje y el inicio de la corriente de calcio. Este valor es menos importante fisiológicamente de lo que es para la estimación de las otras variables mencionadas. El resultado del macro es un wave llamado “ICaDelayOnset_xx_yy”, xx es el número de file, yy es el número de pulso de interés en el protocolo. Aclaración de esto último: En un mismo protocolo puede haber más de un pulso de depolarización de interés, y para cada uno de ellos se analiza el delay to onset. El wave “IcaDelayOnset_xx_yy” va a tener tantos elementos como sweeps haya para un determinado file.
NOTA: para que funcionen los macros que se detallan abajo, es imprescindible que el “ICaDelayOnset_xx_yy” haya funcionado.
- Con el macro “Ultimate Ica Peak and Qca calculation” se obtiene: i) valor del pico de la corriente de calcio, ii) la carga producida (integral de la corriente), iii) el cociente entre la corriente a los 50ms y en el pico (como estimador de inactivación). Como resultado de este macro se producen 3 waves “PeakCa_xx_yy”, “QCa_xx_yy” y “at50msCa_xx_yy”, donde xx es el número de file, yy es el número de pulso de interés en el protocolo, como se mencionó previamente. Cada uno de estos waves tiene tantos elementos como sweeps tenga el file en cuestión.
- “Ultimate activation tau calc” realiza un ajuste exponencial de la activación de la corriente de calcio. Arroja un wave denominado “ICaActTau_xx_yy”, donde xx e yy indican lo mismo que fue mencionado previamente.

Análisis de EPSCs

El principal problema para analizar EPSCs es detectarlos eficientemente. Inicialmente, esto se realizaba con el software MiniAnalysis, pero ahora desarrollamos un macro para hacerlo en Igor. El macro central para arrancar el análisis (en realidad es una familia de macros) está bajo “Detectar EPSCs” en INGEBI, aunque en realidad se denomina “ArrancaDeconvEventosAf”.

-Detección de EPSCs
Este macro es similar al de detección de eventos espontáneos eferentes en tanto utiliza la deconvolución del trazo de corriente para hacer más eficiente la detección. Arranca pidiendo que se indique el número de file a analizar, y luego activa dos gráficos que muestran el trazo de corriente a analizar (en un panel superior) y la deconvolución (en el inferior), y donde la única diferencia entre los gráficos es la escala temporal. 
El macro arranca buscando EPSCs en base a criterios preestablecidos que incluyen la deconvolución y el ruido basal, y cuando detecta un posible evento coloca un cursor en el pico y otro en un punto anterior donde calcula el baseline. También se abre una pequeña ventana con 3 botones que indican “Ok al evento y seguir buscando”, “No al evento” y “Ok al evento y NO seguir”. Si el evento previamente indicado es considerado como un artefacto técnico por el usuario, se debe clickear en el segundo botón. Si en cambio es considerado como un EPSC por el usuario, debe clickear en el primer botón en caso de que quiera seguir buscando automáticamente, o en el tercero, para aceptar pero continuar en forma manual. Esto último implica que el usuario quiere manualmente mover los cursores para señalar un nuevo EPSC. También es posible corregir la posición de los cursores antes dar el OK.
Cuando el macro termina de analizar un primer sweep, sigue con los siguientes (el número de sweep analizado está indicado en un cuadro dentro del gráfico). Aclaración: al arrancar un nuevo sweep hace falta clickear en el botón “NO al evento” para que comience la búsqueda automática de eventos.
El resultado de este macro es un wave de dos dimensiones (una matriz): las columnas son variables medidas a partir de los EPSCs, y cada fila es un evento. Las variables medidas (y por lo tanto las columnas de la matriz) son (hasta ahora): # sweep, tiempo (dentro del sweep) del evento, amplitud del evento.

-Análisis datos EPSCs
Una vez terminada la fase de detección de EPSCs, se pueden calcular distintos parámetros de estos eventos. Estos se realiza con el macro “Analizar Datos EPSC”, que calcula la amplitud de los eventos evocados por un determinado estímulo, así como también el delay entre el estímulo y el inicio del EPSC.
19/jun/2018
jProtocols:

1) jClampLoader:
Este loader está basado en el loader de pClamp, HT_ImportAbfFile. Primero “llama” a éste úlitmo para elegir el file a cargar (los files de jClamp son .abf) y luego carga en forma automática el trazo de Cm (…_2), el de Rm (… _3), y el de Rs  (… _4). Si el file tiene varios episodios, los enumera como de costumbre.
OJO: antes, hace falta exportar de jClamp los trazos correspondientes (Cm, Rm, Rs).

2) Grafico combinado Cm, Rm, Rs.
El primer paso del análisis es el gráfico combinado. Al arrancar el macro pregunta la “raíz” del file name (Siguiendo la lógica previamente mencionada, sería: EC12805A) y el numero de file. Si no existe ese wave, aborta.
El gráfico consta de: a) trazo de corriente (sustraida), b) Cm, c) Rm, d) Rs.
(Este macro tambien se usa para el jCorrectPlot, ver más abajo)

3) jMeasure.
Este macro mide valores importante, como Cm. Para operar requiere antes de arrancar que el usuario primero coloque los cursores en los puntos que delimiten el periodo a medir, post estímlo. Luego, correr el macro. El macro pregunta por los puntos que delimitan los intervalos para medir pre- (punto 1 y 2) y post- (puntos 3 y 4) estímulo en el primer episodio, y finalmente si repite o no esos puntos para los episodios subsiguientes. Si se repite, vuelve a medir en los mismos intervalos. Si no, primero estima cuales serían los puntos a partir del TimeWave, por lo tanto, es necesario que ese wave (y el resto) sean coherentes con el experimento a analizar. Después de esta estimación, chequea abriendo un nuevo diálogo por período, y además, mueve los cursores a las posiciones estimadas para facilitar la lectura.
Finalmente, muestra una tabla con los Delta Cm, Rm y Rs. Y también imprime en el command window los valores de los puntos utilizados para el análisis.

4) jCorrectPlot
Este macro está exclusivamente hecho para graficar, y por tanto, genera duplicaciones de los waves de I, Cm, Rm y Rs con algunos retoques. A saber:
i) el wave de I: genera un wave nuevo donde los períodos de medición de Cm, los cambia por una onda senoidal, sólo a los fines ilustrativos.
ii) wave de Cm: borra las partes que no poseen información real de Cm y además, calcula el baseline de la medición y lo sustrae del trazo completo. Así, se genera un trazo de DeltaCm (multiplicado por 1000, para figurar en fF).
iii) wave de Rm: lo mismo que el de Cm
iv) wave de Rs: lo mismo.

Cuando arranca abre una venta de diálogo en el que pregunta por los puntos utilizados para borrar las partes del trazo no deseadas, y también el intervalo utilizado para el baseline. También hay que indicar si esos puntos se repiten o no para todos los episodios. Si son siempre los mismos, ejecuta el macro y muestra al final una tabla con los valores. Si no, el macro estima cuales serían los puntos a partir del TimeWave. De nuevo, hace falta que éste y el resto de los waves sean coherentes con el experimento.



-----------------------------------FIN DEL MANUAL--------------------------------------------------------------
LOG


3/abr/18
Empezamos oficialmente el log de Macros de Igor!

Por la importante razón de que tenemos muchos Macros hechos aca e importados, usuarios, computadoras y necesitamos poner orden.

3/abr/18 JG
Hoy Lucho instalo Igor en su compu nueva y tuvo problemas con el jClampLoader. Principalmente porque el jClampLoader utiliza un ABF loader “viejo”, el HT_ImportAbfFile(), que requiere dos extensiones en c:/...Igor/IgorExtensions, y son la ABFFIO.dll y la bpc_ReadAbf.
NO OLVIDARLAS!!!!

Yo tambien tengo problemas después de haber instalado Igor en el SSD nuevo. Y se debe a que el jClampLoader busca un “.” en el filename de ABF para cambiar el 001 por el 002 etc. Y ultimamente puse todos mis datos en la carpeta de OneDrive que lleva como nombre “OneDrive – dna.uba.ar”. O sea, se confunde con estos “.” Arreglar eso!==> Listo (16.5.18)

Tambien hay que cambiar de Abf Loader en el jClampLoader. Habria que cambiar al nuevo, LoadABF()==>> Listo (16.5.18)

4/abr/2018
Tema CurrentFile, y parecidos:
CurrentFile: lo usa como global el ABFloader, y los proc subsidiarios. Pero me parece que NO hace falta que sea global. Tambien lo usa el winwcp pero como LOCAL. El jClampLoader NO lo usa y el loader que a su vez usa el jclamp tampoco

6/abr/2018
Recien descubri que el HT_ImportAbffile() funciona con abf1.8, abf2.0 y del jClamp. Tal vez deberiamos usar todos ese. Ademas, genera un monton de informacion en los ‘notes’ de cada wave. Ahi tiene fecha y hora del registro, tiempo, samples, canales, etc. Sin necesidad de crear una nueva variable


/////////////////////////////////////////////////////////////////////
17abr2018

Unificamos y corregimos WinWCPLoader. Ahora, carga files de Marce (MM17722_001.1, etc. Donde lo que esta despues de “1.” es el numero de file) y los mios, que tienen el formato por default de WCP (170722_001, etc). Al cargarlos a Igor, a los mios les cambia el nombre a “JG17722A_001” etc. Para eso, abre un dialogo para pedir las iniciales y la letra correspondiente a la celula a analizar.
Otros:
1) CurrentFileName queda como global. Y CADA macro te pide que chequees que ese es el que queres operar, junto con el numero de file. (a pesar que de que esta en los paramWave tambien)
2) Creamos otra global “CurrentPath” (antes se llamaba Filename) que contiene TODO el path hasta el file cargado
3) IndexCurrFileName no existe mas, tampoco Currentfile
4) S_fileName y S_path existen y son globales. Los utiliza el loader.
//////////////////////////////////////////
16may2018
jClampLoader:
-Habia un inconveniente en como buscaba el nombre del archivo a cargar, de acuerdo a lo descripto el 3/abr/18. Ya esta resuelto. Ahora busca el ‘.’ desde atrás para adelante. Asi, se encuentra primero con el punto del ‘… .abf’
-Otra cosa que hice en el jClampLoader es que ahora usa el HTImportABFfile(). Que tiene como ventajas: 1) carga todos los abf (1.8, 2.0), 2) genera informacion en las ‘notas’ de las waves correspondientes a los registros.
Hice 2 pequenhos cambios: 1) arme una nueva ‘supra’rutina para llamar el HTImportABFfile, que no tiene cuadros de dialogo adicionales, solo te pide que elijas el file. Esa ‘supra’rutina se llama "HT_ImportAbfFile2()". 2) imprime el nombre del file que acaba de cargar (con el path completo)

