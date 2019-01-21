#pragma rtGlobals=1		// Use modern global access method.
#include  <All IP Procedures>
#include  <Image Saver>

Menu "jProtocols"
	"Loader", jClampLoader()
	"Grafico combinado de Cm, Rm, RS", jPlotDialog()
	"Medicion de trazos graficados. NO olividar cursores", jMeasure()
	//"Continua medicion",  jMeasureContinua()
	"Grafico combinado 'para mostrar'", jCorrectPlot()
	"-"
	"Renombrar Heka file", RenameHekaDialog()
end

Function jClampLoader()
	variable i
	SVAR CellN
	String cellNAux
	if((!SVAR_Exists(cellN)) || (cmpstr(cellN, "") == 0))
		String/G cellN
		Prompt CellNAux, "Identificar celula (A, B, etc)"
		DoPrompt "File Loading", CellNAux
	
		CellN = CellNAux
	endif
	String HT_Import = "HT_ImportAbfFile2()"
	Execute HT_Import
	SVAR jFilename
	SVAR jFilePath
	
	i=0
	Do
		String TestMultipleEpisodes = jFileName+"_"+num2str(i+1)+"_1"
		if(WaveExists($TestMultipleEpisodes) == 1)		
			Variable Pos1= strsearch(jFilePath, ".", Inf, 1)	//16.5.18 Simple cambio. Ahora busca de atras para adelante
			String FilePath = jFilePath[0,(Pos1 -1)] + "_2.asc"
//	open/r refnum as Filename
//	variable ver
//	string verstr
//	fReadLine/T=(num2char(13)) refnum, ver
//	fReadLine/n=11/T=(num2char(13)) refnum, verstr
			LoadWave/Q/N=jTemp/J/k=1/L={0,3,0,2*i,2} FilePath
			if(V_flag == 0)
				abort
			endif
			Wave jTemp0, jTemp1
			Variable SampleIntCm = (jTemp0[3] - jTemp0[2])*1e-3
			KillWaves jTemp0
//	Deletepoints 0,3, jTemp1
			Setscale/p x,0, SampleIntCm, jTemp1
			SVAR CurrentFileName 
			CurrentFileName = "LB1" + jFileName[1,4]+ cellN+"_0" + jFileName[5,7]
			Rename jTemp1, $(CurrentFileName+"_"+num2str(i+1)+"_2")
	
			 FilePath = jFilePath[0,(Pos1 -1)] + "_3.asc"
			LoadWave/Q/N=jTempRm/J/k=1/L={0,3,0,2*i,2} FilePath
			if(V_flag == 0)
				abort
			endif
			Wave jTempRm1
			Rename jTempRm1, $(CurrentFileName+"_"+num2str(i+1)+"_3")
			Setscale/p x,0, SampleIntCm, $(CurrentFileName+"_"+num2str(i+1)+"_3")
	
			 FilePath = jFilePath[0,(Pos1 -1)] + "_4.asc"
			LoadWave/Q/N=jTempRs/J/k=1/L={0,3,0,2*i,2} FilePath
			if(V_flag == 0)
				abort
			endif	
			Rename jTempRs1, $(CurrentFileName+"_"+num2str(i+1)+"_4")
			Setscale/p x,0, SampleIntCm, $(CurrentFileName+"_"+num2str(i+1)+"_4")
	
			Killwaves jTempRs0, jTempRm0
			Rename $(jFileName+"_"+num2str(i+1)+"_1"), $(CurrentFileName+"_"+num2str(i+1)+"_1")
		else
			break
		endif
		i+=1
	While(1)
end


Function RenameHekaDialog()
	SVAR CurrentFileName
	Variable FileN
	string scurrentFileName = CurrentFileName
	Prompt scurrentFileName, "Nombre del CurrentFileName?"
	Prompt FileN, "Numero de file para renombrar?"
	DoPrompt "jProtocols", scurrentFileName, FileN
	If(V_flag ==1)
		abort
	endif
	CurrentFileName = sCurrentFileName
	String cmd
	Sprintf cmd, "RenameHekaTojProt(\"%s\", %g)",  scurrentFileName, fileN
	print cmd
	execute cmd
end

Function RenameHekaTojProt(sHekaFileName,file)
	String sHekaFileName
	Variable file
	variable i = 0
	String aux =sHekaFileName + "_1_"+num2str(file)+"*"
	string aux2 = WaveList(aux, ";","")
	Do	
		aux = StringfromList(i, aux2)
		if(WaveExists($aux) == 0)
			print "no hay waves con e"
			abort
		endif
		variable sweep
		sscanf aux, (sHekafileName+"_1_"+num2str(file)+"_%f"), sweep
		String CompleteSweepN = num2str(sweep)
		Do
			completeSweepN = "0" + completeSweepN
		While(strlen(completeSweepN) < 3)

		variable channel
		sscanf aux, (sHekafileName+"_1_"+num2str(file)+"_"+completeSweepN+"_%f"), channel
		
		string completefileN = num2str(file)
		Do
			completeFileN = "0" + completeFileN
		While(strlen(completeFileN) < 4)
		string renameAux = aux[0,8] + completeFileN + "_"+num2str(sweep) +"_"+num2str(channel)
		
		Rename $aux, $renameaux
		i+=1
	While(1)

End
Function jPlotDialog()
	SVAR CurrentFileName
	Variable FileN
	string scurrentFileName = CurrentFileName
	Prompt scurrentFileName, "Nombre del CurrentFileName?"
	Prompt FileN, "Numero de file para graficar?"
	DoPrompt "jProtocols", scurrentFileName, FileN
	If(V_flag ==1)
		abort
	endif
	CurrentFileName = sCurrentFileName
	String cmd
	Sprintf cmd, "jPlot(%g, \"%s\", 0)", fileN, scurrentFileName
	print cmd
	execute cmd
end

Function jPlot(fileN, scurrentFileName, dup)
	//Creado 17ene2017 JG
	//Macro creado para visualizar registros de Cm, Rm y Rs, graficados en conjunto con el trazo de I
	//Asume que hay 4 canales por file o episodio: i) Ip, ii) Cm, iii) Rm, iv) Rs
	//9jun2017 JG
	//Cambie un poco el macro. Simplemente le agregue una seccion para hacer un plot 'corregido' de
	//todos los trazos. Para mostrar mejor

	Variable FileN, dup
	String sCurrentFileName
	Variable i = 1
	String CompleteFileN = num2str(FileN)
	Do
		CompleteFileN = "0"+CompleteFileN
	While(strlen(CompleteFileN) < 4)
	String CurrWave
//	SVAR CurrentFileName = scurrentFileName
	if(dup == 0)
	do
		CurrWave = sCurrentFileName[0,7]+"_"+CompleteFileN+"_"+num2str(i)+"_1LeakS"
		wave wCurrWave  =$CurrWave
		if((WaveExists(wCurrWave) == 0) && (i==1))
			print "No existe ese wave o no esta sustraido el leak"
			abort
		elseif(WaveExists(wCurrWave) == 0)
			abort
		elseif(i == 1)
			Display/W=(10,10,450,450) $CurrWave	
		else 
			appendtograph $CurrWave
			ModifyGraph rgb($CurrWave)=((30000+10000*(i)),(30000+10000*(i)),(30000+10000*(i)))
		endif
		SetAxis left -200,50
		ModifyGraph axisEnab(left)={0.82,1}
		CurrWave = sCurrentFileName[0,7]+"_"+CompleteFileN+"_"+num2str(i)+"_2"
		appendtograph/l=Cm $CurrWave
		setaxis Cm 8,12
		ModifyGraph axisEnab(Cm)={0.5,.8}
		ModifyGraph rgb($CurrWave)=((30000+10000*(i)),(30000+10000*(i)),(30000+10000*(i)))
		CurrWave = sCurrentFileName[0,7]+"_"+CompleteFileN+"_"+num2str(i)+"_3"
		appendtograph/l=Rm $CurrWave
		setaxis Rm 200,500
		ModifyGraph axisEnab(Rm)={.25,.48}
		ModifyGraph rgb($CurrWave)=((30000+10000*(i)),(30000+10000*(i)),(30000+10000*(i)))
		CurrWave =sCurrentFileName[0,7]+"_"+CompleteFileN+"_"+num2str(i)+"_4"
		appendtograph/l=Rs $CurrWave
		setaxis Rs 20,30
		ModifyGraph axisEnab(Rs)={0,.23}
		ModifyGraph rgb($CurrWave)=((30000+10000*(i)),(30000+10000*(i)),(30000+10000*(i)))
		ModifyGraph freePos=0
		ShowInfo
		i+=1
	while(1)
	elseif(dup == 1)
	do
		CurrWave = sCurrentFileName[0,7]+"_"+CompleteFileN+"_"+num2str(i)+"_1LeakS"
		wave wCurrWave  = $CurrWave
	//	make/o wCurrWave// = $CurrWave
		if(WaveExists(wCurrWave) == 0)
			CurrWave = sCurrentFileName[0,7]+"_"+CompleteFileN+"_"+num2str(i)+"_1"
			
			if(WaveExists(wCurrWave) == 0)
				abort
			endif
		else
			CurrWave = sCurrentFileName[0,7]+"_"+CompleteFileN+"_"+num2str(i)+"_1LeakSD"
		endif
		
		if(i == 1)
			Display/W=(10,10,450,450) $CurrWave
			ModifyGraph rgb($CurrWave)=((30000+10000*(i)),(30000+10000*(i)),(30000+10000*(i)))
		else 
			appendtograph $CurrWave
			ModifyGraph rgb($CurrWave)=((30000+10000*(i)),(30000+10000*(i)),(30000+10000*(i)))
		endif
		SetAxis left -200,50
		ModifyGraph axisEnab(left)={0.82,1}
		CurrWave = sCurrentFileName[0,7]+"_"+CompleteFileN+"_"+num2str(i)+"_2dup"
		appendtograph/l=Cm $CurrWave
		ModifyGraph rgb($CurrWave)=((30000+10000*(i)),(30000+10000*(i)),(30000+10000*(i)))
		setaxis Cm -.1,1
		ModifyGraph axisEnab(Cm)={0.5,.8}
		CurrWave = sCurrentFileName[0,7]+"_"+CompleteFileN+"_"+num2str(i)+"_3dup"
		appendtograph/l=Rm $CurrWave
		ModifyGraph rgb($CurrWave)=((30000+10000*(i)),(30000+10000*(i)),(30000+10000*(i)))
		setaxis Rm -30,30
		ModifyGraph axisEnab(Rm)={.25,.48}
		CurrWave = sCurrentFileName[0,7]+"_"+CompleteFileN+"_"+num2str(i)+"_4dup"
		appendtograph/l=Rs $CurrWave
		ModifyGraph rgb($CurrWave)=((30000+10000*(i)),(30000+10000*(i)),(30000+10000*(i)))
		setaxis Rs -1,3
		ModifyGraph axisEnab(Rs)={0,.23}
		ModifyGraph freePos=0
		ShowInfo
		i+=1
	while(1)
	endif
end

Function CorrectjImTrace(TraceLS, p1, p2, p3, p4)
	Wave TraceLS
	Variable p1, p2, p3, p4
	String sNOW = NameofWave(TraceLS) + "D"
	Duplicate/o TraceLS, $sNOW
	Wave wNOW = $sNOW
	Wavestats/q/R=(.0001,.01) wNOW
	NVAR SampleInterval
	variable i 
	P1 /= SampleInterval; P2 /= SampleInterval; P3 /= SampleInterval
	P4 /= SampleInterval
	for(i=P1;i<P2;i+=1)
		wNOW[i] = 50*sin(i*100/50000) + gnoise(V_sdev) 
	endfor
	for(i=P3;i<p4;i+=1)
		wNOW[i] = 50* sin(i*100/50000)+ gnoise(V_sdev) 
	endfor
//	return wNOW
end
Function correctvprot()	
	NVAR SampleInterval
//	SVAR CurrentFileName
	variable i, j
	Variable P1 = .09272/SampleInterval, P2 = .49272/SampleInterval, P3 = .58272/SampleInterval
	Variable P4 = 1.08272/SampleInterval
	string sWave
	for(j=0;j<9;j+=1)
		sWave = "VoltProtforGraph" + num2str(j)
		Wave wWave = $sWave
		for(i=P1;i<P2;i+=1)
			wWave[i] = wWave[i] + .01*sin(i*500/50000)//+ gnoise(V_sdev) 
		endfor
		for(i=P3;i<P4;i+=1)
			wWave[i] = wWave[i] + .01* sin(i*500/50000)//+ gnoise(V_sdev) 
		endfor
	endfor
end

//Function jPlotDialog()
//	SVAR CurrentFileName
//	Variable FileN
//	string scurrentFileName = CurrentFileName
//	Prompt scurrentFileName, "Nombre del CurrentFileName?"
//	Prompt FileN, "Numero de file para graficar?"
//	DoPrompt "jProtocols", scurrentFileName, FileN
//	If(V_flag ==1)
//		abort
//	endif
//	CurrentFileName = sCurrentFileName
//	String cmd
//	Sprintf cmd, "jPlot(%g, \"%s\", 0)", fileN, scurrentFileName
//	print cmd
//	execute cmd
//end

Function jMeasure()
		//Creado 17ene2017 JG
		//Macro creado para medir valores de DeltaCm, Rm pre y post, y Rs pre y post
		//Antes de correrlo hace falta poner 2 cursores en el trazo de Cm, determinando el periodo donde medir
		//Asi, mide los 3 parametros en ese periodo para TODOS los episodios. A menos que se indique lo contrario
		//Si se indica lo contrario, vuelve a pedir que se indique los puntos en cada episodio
		//9jun2017 JG
		//Introduje un par de cambios. 1) El prompt pregunta si utilizar los mismos valores de baseline y demas para 
		//hacer calculos en todos los episodios. Si la respuesta es 'no', corta y hay que correr el 'jMeasureContinua'
		//2)Imprime en el command window, el numero de file, episodio y los valores de puntos utilizados para meidciones
		//19jun2018 JG
		//Algunos cambios: Los puntos que se indican para medir son en segundos (no mas ptos)
		//ii)Los puntos para calcular el baseline son bastante fijos pero igual el macro consulta para chequearlos.
		//Asi tambien los puntos para calcular el delta despues del estimulo, y finalmente, si esos punto si se repiten 
		//(en el caso de la I-V) o no (curva de tiempo)
		//Si NO se repiten el macro vuelve a preguntar por los valores correspondiente para CADA episodio
		//Cambio IMPORTANTE: el macro 'estima' cuales serian esos nuevos valores (para la curva de tiempo)
		//Para lo cual, es NECESARIO que el VProtWave, TimeWave, etc esten conformes al protocolo utilizado
		//Ademas, los cursores se corren para facilitar para estimacion
	Variable i = 1,j
	Wave ParamWave,TimeWave
	String CmWave, CmWave1 = CsrWave(A)
	Variable FileN = str2num(CmWave1[9,12])
	if(strlen(CmWave1) < 5)	
		printf "chequear cursores\r"
		abort
	endif
	
	Variable  Point1Pre, Point2Pre, Point1Post, Point2Post, Repeat
	Point1Pre = .11
	Point2Pre = .45
	Point1Post = round(xcsr(a)*10000)/10000
	Point2Post = round(xcsr(b)*10000)/10000
	Repeat = 0
	String ResultadoDeltaCm = "ResultadoDeltaCm_"+num2str(FileN)
	String ResultadoDeltaRm = "ResultadoDeltaRm_"+num2str(FileN)
	String ResultadoDeltaRs = "ResultadoDeltaRs_"+num2str(FileN)
	Make/O/N=0 $ResultadoDeltaCm
	Make/O/N=0 $ResultadoDeltaRm
	Make/O/N=0 $ResultadoDeltaRs

			Prompt Point1Pre, "Punto inicial Pre"
			Prompt Point2Pre, "Punto final Pre"
			Prompt Point1Post, "Punto inicial Post"
			Prompt Point2Post, "Punto final Post"
//			Repeat = 1
			Prompt Repeat, "Repetir los puntos en los episodios siguientes? (0: No, 1: Si)"
			DoPrompt "Determinar puntos para analisis", Point1Pre, Point2Pre, Point1Post, Point2Post, Repeat
	Point1Pre = round(Point1Pre/.00512)
	Point2Pre = round(Point2Pre/.00512)
				Point1Post = round(Point1Post/.00512)
			Point2Post = round(Point2Post/.00512)

	if(Repeat == 0)
		WaveStats/Q TimeWave
		if(V_max >= 1000)
			Integrate/P TimeWave /D=TimeWaveInt
			Make/O/n=(1) PtosPaCorr
			PtosPaCorr[0] = TimeWaveInt[V_maxLoc-1]
			Wavestats/Q ParamWave
			InsertPoints 1, V_npnts, PtosPaCorr
			for(j=0;j<V_npnts;j+=1)
				PtosPaCorr[j+1] = ParamWave[j]
			endfor
		endif
	endif
	Do
		CmWave = CmWave1[0,13]+num2str(i)+"_2"
		Wave wCmWave = $CmWave
		if(WaveExists(wCmWave ) == 0)
			break
		endif
		if((i>1) && Repeat == 0)
			Point1Post = round(10000*(PtosPaCorr[0] + PtosPaCorr[i] + .05))/10000
			Point2Post = round(10000*(PtosPaCorr[0] + PtosPaCorr[i] + .45))/10000
			Cursor A, $CmWave, Point1Post
			Cursor B, $CmWave, Point2Post
			Doupdate
			Prompt Point1Post, "Punto inicial Post esta bien?"
			Prompt Point2Post, "Punto final Post esta bien?"
			DoPrompt "Determinar puntos para analisis", Point1Post, Point2Post
			Point1Post = round(Point1Post/.00512)
			Point2Post = round(Point2Post/.00512)
		endif

		Wavestats/Q/R=[Point1Post, Point2Post] $CmWave
		Variable DeltaCm = V_avg
		Wavestats/Q/R=[Point1Pre,Point2Pre] $CmWave
		DeltaCm -= V_avg
		DeltaCm *=1000
		insertpoints (i-1),1, $ResultadoDeltaCm
		wave  wResultadoDeltaCm =  $ResultadoDeltaCm
		wResultadoDeltaCm[i-1] = DeltaCm
		
		String RmWave = CmWave[0,13] +num2str(i)+"_3"
		Wavestats/Q/R=[Point1Pre, Point2Pre] $RmWave
		Variable RmPre = V_avg
		insertpoints (2*i-2),2, $ResultadoDeltaRm
		wave  wResultadoDeltaRm =  $ResultadoDeltaRm
		wResultadoDeltaRm[2*i-2] = RmPre
		Wavestats/Q/R=[Point1Post,Point2Post] $RmWave
		Variable RmPost = V_avg
		wResultadoDeltaRm[2*i-1] = RmPost
			
		String RsWave = CmWave[0,13] +num2str(i)+"_4"
		Wavestats/Q/R=[Point1Pre, Point2Pre] $RsWave
		Variable RsPre = V_avg
		insertpoints (2*i-2),2, $ResultadoDeltaRs
		wave  wResultadoDeltaRs =  $ResultadoDeltaRs
		wResultadoDeltaRs[2*i-2] = RsPre
		Wavestats/Q/R=[Point1Post,Point2Post] $RsWave
		Variable RsPost = V_avg
		wResultadoDeltaRs[2*i-1] = RsPost
//		if(Repeat == 0)
//			abort
//		endif		
		i+=1
		
	While(1)
	
//	if((i == 2))
//		Printf "File: %g,\tDeltaCm: %g fF\rRmPre: %g MOhm\tRmPost: %g MOhm\rRsPre: %g MOhm\tRsPost:%g MOhm\r", FileN, DeltaCm, RmPre, RmPost,RsPre,RsPost
//		Killwaves $ResultadoDeltaCm,$ResultadoDeltaRm,$ResultadoDeltaRs
//	else
		Point1Pre*=.00512; Point2Pre*=.00512; Point1Post*=.00512; Point2Post*=.00512
		printf "Medido el File: %g,\tUsando los puntos Point1Pre: %g, Point2Pre: %g, Point1Post: %g, Point2Post: %g\r", FileN, Point1Pre, Point2Pre, Point1Post, Point2Post
		Edit $ResultadoDeltaCm,$ResultadoDeltaRm,$ResultadoDeltaRs
		KillWaves PtosPaCorr, TimeWaveInt
//	endif
end

//Function jMeasureContinua()
//		//Creado 9jun2017 JG
//		//La idea es correr este macro a continuacion de jMeasure para que mida Cm, Rm y Rs para casos
//		//como el Cm vs t
//		//Imprime en el command window, el numero de file, episodio y los valores de puntos utilizados para meidciones
//	Variable i = 1
//	String CmWave, CmWave1 = CsrWave(A)
//	Variable FileN = str2num(CmWave1[9,12])
//	Variable EpiN = str2num(CmWave1[14])
//	if(strlen(CmWave1) < 5)	
//		printf "chequear cursores\r"
//		abort
//	endif
//	
//	Variable  Point1Pre, Point2Pre, Point1Post, Point2Post, Repeat
//	Point1Pre = 22	
//	Point2Pre = 90
//	Point1Post = pcsr(a)
//	POint2Post = pcsr(b)
//	Repeat = 0
//	String ResultadoDeltaCm = "ResultadoDeltaCm_"+num2str(FileN)
//	String ResultadoDeltaRm = "ResultadoDeltaRm_"+num2str(FileN)
//	String ResultadoDeltaRs = "ResultadoDeltaRs_"+num2str(FileN)
//	Wave wResultadoDeltaCm =  $ResultadoDeltaCm
//	Wave wResultadoDeltaRm = $ResultadoDeltaRm
//	Wave wResultadoDeltaRs =  $ResultadoDeltaRs
//	Variable Aux = DimSize($ResultadoDeltaCm,0)
//	//Do
//	//	if(Repeat == 0)
//			Prompt Point1Pre, "Punto inicial Pre"
//			Prompt Point2Pre, "Punto final Pre"
//			Prompt Point1Post, "Punto inicial Post"
//			Prompt Point2Post, "Punto final Post"
////			Repeat = 1
//		//	Prompt Repeat, "Repetir los puntos en los episodios siguientes? (0: No, 1: Si)"
//			DoPrompt "Determinar puntos para analisis", Point1Pre, Point2Pre, Point1Post, Point2Post//, Repeat
//		//endif
//		CmWave = CmWave1[0,13]+num2str(EpiN)+"_2"
//		Wave wCmWave = $CmWave
//		if(WaveExists(wCmWave ) == 0)
//			abort
//		endif
//		Wavestats/Q/R=[Point1Post, Point2Post] $CmWave
//		Variable DeltaCm = V_avg
//		Wavestats/Q/R=[Point1Pre,Point2Pre] $CmWave
//		DeltaCm -= V_avg
//		DeltaCm *=1000
//		insertpoints (aux),1, $ResultadoDeltaCm
//		wave  wResultadoDeltaCm =  $ResultadoDeltaCm
//		wResultadoDeltaCm[aux] = DeltaCm
//		
//		String RmWave = CmWave[0,13] +num2str(EpiN)+"_3"
//		Wavestats/Q/R=[Point1Pre, Point2Pre] $RmWave
//		Variable RmPre = V_avg
//		insertpoints (aux),2, $ResultadoDeltaRm
//		wave  wResultadoDeltaRm =  $ResultadoDeltaRm
//		wResultadoDeltaRm[aux] = RmPre
//		Wavestats/Q/R=[Point1Post,Point2Post] $RmWave
//		Variable RmPost = V_avg
//		wResultadoDeltaRm[aux+1] = RmPost
//			
//		String RsWave = CmWave[0,13] +num2str(EpiN)+"_4"
//		Wavestats/Q/R=[Point1Pre, Point2Pre] $RsWave
//		Variable RsPre = V_avg
//		insertpoints (aux),2, $ResultadoDeltaRs
//		wave  wResultadoDeltaRs =  $ResultadoDeltaRs
//		wResultadoDeltaRs[aux] = RsPre
//		Wavestats/Q/R=[Point1Post,Point2Post] $RsWave
//		Variable RsPost = V_avg
//		wResultadoDeltaRs[aux+1] = RsPost
//		printf "Medido el File: %g, Episodio: %g\rUsando los puntos Point1Pre: %g, Point2Pre: %g, Point1Post: %g, Point2Post: %g\r", FileN, EpiN, Point1Pre, Point2Pre, Point1Post, Point2Post
//
//end


Function jCorrectPlot()
	//Creado 9jun2017 JG
	//Macro creado para visualizar registros de Cm, Rm y Rs, graficados en conjunto con el trazo de I
	//pero corrigiendo los baselines y borrando partes no deseadas.
	//
	Variable FileN
	//Variable p1 = 0, p2 = 18, p3 = 94, p4 = 112,p5 =  20, p6 = 90
	Variable p1 = 0, p2 = .09728, p3 = .481, p4 = .578,p5 =  .123, p6 = .4505
	Wave TimeWave, ParamWave	
	Variable i, j, NPoints, Repeat = 0
	Make/o TimeWaveInt

	String sCmTrace, sCmTraceDup, sRmTrace,sRmTraceDup
	String sRaTrace, sRaTraceDup, sITrace
	SVAR CurrentFileName
	String sCurrentFileName = CurrentFileName
	Prompt sCurrentFileName, "File?"
	Prompt FileN "Numero de file?"
	Prompt Repeat, "repetir en todos los espisodios? (0: no, 1: si)"
	Prompt p1, "Punto 1 para borrar"
	Prompt p2, "Punto 2 para borrar"
	Prompt p3, "Punto 3 para borrar"
	Prompt p4, "Punto 4 para borrar"
	Prompt p5, "Punto 5 para calcular baseline"
	Prompt p6, "Punto 6 para calcular baseline"

//			Repeat = 1
		//	Prompt Repeat, "Repetir los puntos en los episodios siguientes? (0: No, 1: Si)"
	DoPrompt "Determinar puntos para analisis", sCurrentFileName, FileN, Repeat, p1,p2,p3,p4,p5,p6
	CurrentFileName = sCurrentFileName
	String CompleteFileN = num2str(FileN)
	Do
		CompleteFileN = "0"+CompleteFileN
	While(strlen(CompleteFileN) < 4)
	if(Repeat == 0)
		WaveStats/Q TimeWave
		if(V_max >= 1000)
			Integrate/P TimeWave /d=TimeWaveInt
			Make/O/n=(1) PtosPaCorr
			PtosPaCorr[0] = TimeWaveInt[V_maxLoc-1]
			Wavestats/Q ParamWave
			InsertPoints 1, V_npnts, PtosPaCorr
			for(j=0;j<V_npnts;j+=1)
				PtosPaCorr[j+1] = ParamWave[j]
			endfor
			p3 = (PtosPaCorr[0])
			p4 = (PtosPaCorr[0] + PtosPaCorr[1])
		endif
	endif
			
	Do
		if((i>0) && (Repeat == 0))
			p3 = (PtosPaCorr[0])
			p4 = (PtosPaCorr[0] + PtosPaCorr[i+1])
			Prompt p1, "Punto 1 para borrar"
			Prompt p2, "Punto 2 para borrar"
			Prompt p3, "Punto 3 para borrar"
			Prompt p4, "Punto 4 para borrar"
			Prompt p5, "Punto 5 para calcular baseline"
			Prompt p6, "Punto 6 para calcular baseline"
			DoPrompt "Determinar puntos para analisis", p1,p2,p3,p4,p5,p6
		endif
		sCmTrace = CurrentfileName[0,7] + "_" + CompleteFileN + "_" + num2str(i+1) +"_2"
		sCmTraceDup = sCmTrace + "dup"
		Duplicate/O $sCmTrace, $sCmTraceDup
		Wave wCmTraceDup = $sCmTraceDup

		sRmTrace = CurrentfileName[0,7] + "_" + CompleteFileN + "_" + num2str(i+1) +"_3"
		sRmTraceDup = sRmTrace + "dup"
		Duplicate/O $sRmTrace, $sRmTraceDup
		Wave wRmTraceDup = $sRmTraceDup		
		
		sRaTrace = CurrentfileName[0,7] + "_" + CompleteFileN + "_" + num2str(i+1) +"_4"
		sRaTraceDup = sRaTrace + "dup"
		Duplicate/O $sRaTrace, $sRaTraceDup
		Wave wRaTraceDup = $sRaTraceDup
		
		sITrace = CurrentfileName[0,7] + "_" + CompleteFileN + "_" + num2str(i+1) +"_1LeakS"
		Wave wITrace = $sITrace
		if(WaveExists(wITrace) == 0)
			print "El registro no esta substraido"
		else
			Variable p7 = (Dimsize(wITrace,0) * DimDelta(wItrace,0))
			CorrectjImTrace(wITrace, p2, p3, p4, p7)
		endif

		p1=round(p1/.00512); p2=round(p2/.00512); p3=round(p3/.00512); p4=round(p4/.00512)
		p5=round(p5/.00512); p6=round(p6/.00512)
		for(j=p1;j<p2;j+=1)
			wCmTraceDup[j] = nan
			wRmTraceDup[j] = nan
			wRaTraceDup[j] = nan
		endfor
		for(j=p3;j<p4;j+=1)
			wCmTraceDup[j] = nan
			wRmTraceDup[j] = nan
			wRaTraceDup[j] = nan
		endfor
		Wavestats/q/r=[p5,p6] wCmTraceDup
		wCmTraceDup -= V_avg
		NPoints = DimSize(wCmTraceDup,0)
		DeletePoints (Npoints-1), 1, wCmTraceDup
		Smooth 10, wCmTraceDup
		///////////////////////////////////////////////
		Wavestats/q/r=[p5,p6] wRmTraceDup
		wRmTraceDup -= V_avg
		Wavestats/q/r=[p5,p6] wRaTraceDup
		wRaTraceDup -= V_avg
		p1*=.00512;p2*=.00512; p3*=.00512; p4*=.00512; p5*=.00512; p6*=.00512
		i+=1
		sCmTrace = CurrentfileName[0,7] + "_" + CompleteFileN + "_" + num2str(i+1) +"_2"
		Wave wCmTrace = $sCmTrace
		if(WaveExists(wCmTrace) == 0)
			break
		endif
	While(1)
	KillWaves PtosPaCorr, TimeWaveInt
	jPlot(fileN,scurrentFileName,1)
End