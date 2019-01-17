Requerimientos: 
-Version Igor Pro 6.37
-Instalar Paquete SARFIA para análisis de imágenes desde IgorExchange: http://www.igorexchange.com/project/SARFIA

Procedimiento: 
1.	Cargar imágenes usando el macro LoadMultipleImages(). Esto cargara el set de imágenes en formato TIFF manteniendo el nombre de la imagen – “NombreImagen”  e incluirá un wave adicional llamado Timewave_”NombreImagen” conteniendo el tiempo de adquisición de cada imagen. El Macro fue corregido para aceptar imágenes de cualquier dimensión X-Y. Se recomienda utilizar un formato para “NombreImagen”: ‘Img’+ ˽ ˽ (iniciales experimentador)+˽ ˽ (año)+ ˽ (mes)+ ˽ ˽ (día)+˽ (célula)+’_’+ ˽ (file).
2.	Abrir la imagen y mantenerla en primer plano.
3.	Ejecutar AutoROIImgProcV2(). Esto desplegará el Menu donde deben cargarse todos los parámetros y seleccionar las opciones de procesamiento:

<img src=https://github.com/mjmoglie/MACROS-IGOR/blob/master/IMAGENES/MENU.png width="700">
 
•	Photobleaching Correction: Al seleccionarlo se realizará una corrección del photobleaching sobre los trazos de fluorescencia. La misma se basa en el ajuste de una función lineal al trazo de la señal de fluorescencia promedio entre los ROIs comprendidos en el intervalo Photobleaching PRE- Photobleaching POST. Si ambos presentan el mismo valor se tomarán en cuenta todos los ROIs. Tener en cuenta que el número coincida con el ángulo asignado (#ROIs=360/Angle).
•	Analysis Output: seleccionar si el resultado final será expresada en DeltaF/F0 o Delta F.
•	Automatic Center Determination: Define el centro de la célula bajo análisis realizando un analisis de partículas y la posterior determinacion del centro de masa de la partícula encontrada. Al deseleccionarlo, el centro estará definido por los parámetros “X center” e “Y center”. 
•	Smooth ROI traces: al seleccionarlo se incluye una fase de filtrado adicional sobre los trazos de fluorescencia obtenidos.
•	File Properties: 
i.	FILE: # de file que será analizado (solo a fines de notación de registros)
ii.	VERSION: fue incorporado para evitar problemas de incompatibilidad de nombres en caso de realizar múltiples análisis sobre un mismo file
iii.	TOTAL IMAGES: # de frames del archivo a analizar
iv.	TOTAL Sweeps: # de sweeps totales del experimento. El programa está pensado para protocolos en los cuales el número de imágenes por sweep se mantiene constante ( # Imágenes por sweep= total images/total sweeps)
v.	Stimulus Time (ms): momento del registro electrofisiológico en el que se realiza el estímulo. Este punto determinará el momento hasta donde se calcula el baseline del trazo y a partir del cual se busca el pico máximo. 
•	Location Properties: 
i.	X-Center & Y-Center: Posicion del centro de la circunferencia de analisis en cada eje de la imagen. Sólo serán tenidos en cuenta si “Automatic center determination” se encuentra deseleccionado. 
ii.	External Radius: límite radial en pixeles de la circunferencia a partir de la cual se generarán los ROIs. Más allá de este radio, nada será analizado.
iii.	Angle: dimensión angular de  cada uno de los ROIs que se generará (#ROIs = 360/Angle)

<img src=https://github.com/mjmoglie/MACROS-IGOR/blob/master/IMAGENES/Dise%C3%B1o%20ROI.png width="350">

•	Analysis parameters: 
i.	Peak Criteria: Indica cuantas veces mayor a la desviacion estándar del baseline debe ser el pico de la señal para ser considerado positivo (2-3).
ii.	Integral Criteria: Indica valor umbral de la integral de la señal de fluorescencia en unidades arbitrarias para considerar el evento como positivo.
iii.	Threshold Min & Threshold Max: Se define el umbral de la señal de fluorescencia. A partir de la detección del borde celular con un algoritmo iterativo, se genera un histograma de la señal de fluorescencia celular, normalizado a la fluorescencia máxima. Luego, se obtiene una máscara comprendida entre las regiones con los umbrales máximos y mínimos indicados.  
 
 <img src=https://github.com/mjmoglie/MACROS-IGOR/blob/master/IMAGENES/Dise%C3%B1o%20ROI%20y%20MASCARA.png width="350">

4.	Una vez cargados los parámetros, apretar sobre el botón “Start Background-ROI Draw” y dibujar una región de interés sobre el Background que será utilizada para corregir la señal de fluorescencia. La región dibujada puede eliminarse con el botón “Erase ROI” y se puede volver a dibujar. 
5.	Presionar el botón “Finish Background-ROI” para dar comienzo al macro de análisis automático.
6.	Al finalizar se creará una carpeta cuyo nombre será “˽ ˽ (iniciales experimentador)+˽ ˽(año)+ ˽ (mes)+ ˽ ˽ (día)+˽ (célula)+’_’+F_(# de File indicado)_V_(# de versión indicado)”, conteniendo distintos Waves resultantes del análisis: 
•	AutoROIAnalVar: String que contiene los parámetros del analisis realizado
•	ROIMasksThreshold: Máscara obtenida a partir de la definición de los umbrales de fluorescencia para el experimento en cuestión. 
•	ROIMasks: wave tridimensional que contiene en cada plano la máscara de cada uno de los ROIs definidos por los parámetros utilizados.
•	ROIMasks_Back: Máscara del ROI utilizado para calcular la señal Background. 
•	BacK: Señal de fluorescencia del ROI utilizado como Background
•	BaselineF: Wave de 2 dimensiones (# ROI vs. # sweeps). Señal de fluorescencia promedio del Baseline (señal previa al estímulo) para cada ROI y cada estimulo, antes de realizar la normalización de la señal de fluorescencia. 

•	Amplitude: Wave de 2 dimensiones (# ROI vs. # sweeps). Amplitud de la señal al pico detectado para cada ROI en cada sweep. Solo se incluirán aquellos valores de los trazos que hayan sido seleccionados como éxitos basándose en los criterios de amplitud e integral. 
•	PeakTime: Wave de 2 dimensiones (# ROI vs. # sweeps).  Tiempo en el que fue detectado el pico de la señal de fluroescencia para cada ROI en cada sweep. Solo se incluirán aquellos valores de los trazos que hayan sido seleccionados como éxitos basándose en los criterios de amplitud e integral. 
•	Integral_area: Wave de 2 dimensiones (# ROI vs. # sweeps). Integral de la señal de fluorescencia para cada ROI en cada sweep. Solo se incluirán aquellos valores de los trazos que hayan sido seleccionados como éxitos basándose en los criterios de amplitud e integral. 
•	ProbabilityROIS: Se indica la probabilidad de detectar un evento exitoso en cada ROIs durante el experimento. 
•	TauImaging: Wave de 2 dimensiones (# ROI vs. # sweeps).  Ajste exponencial a la fase de decaimiento de la señal de fluorescencia en caso de haber detectado un evento positivo basándose en los criterios de amplitud e integral.

•	ConcatenatedSweeps: Este wave de dos dimensiones contiene la señal de fluorescencia de cada ROI a lo largo de todo el experimento. La señal de Fluorescencia se encuentra normalizada a la señal inicial de cada sweep. Presionando Ctrl+3 mientras se encuentra abierto este Wave se activa la función “Image Line Profile” que permite explorar la imagen a partir de la generación de trazos correspondientes a la señal de fluorescencia de cada ROI.

<img src=https://github.com/mjmoglie/MACROS-IGOR/blob/master/IMAGENES/CONCATENADO%20DE%20ROIS.png width="450">
 

