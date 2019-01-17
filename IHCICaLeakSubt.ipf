#pragma rtGlobals=1		// Use modern global access method.

//Jun2009
Menu "Efferents"
	"Analysis on evoked synaptic currents in trains or single", EffAnalysisTrain()
	"Cumulative amplitude plot", EffAnalysisCum()
	"Analysis of spontaneous currents", MiniAnalDeconv()
	
	SubMenu "Efferent OUTPUT"
	"Print results from EffAnalysis", PrintResultsEffAnal()
	"Export to Prism", Exporttoprism()
	end

End

Menu "INGEBI"

	"IHC Analysis=>"
	" ICa Analysis Ensemble", EnsembleICaAnal()
	"Ultimate leak subtraction", UltimateLeakSubtDialog()
	"Ultimate delay to onset calc", UltimateICaDelayToOnsetDialog()
	"Ultimate activation tau calc", UltimateICaActTauDialog()
	"Ultimate ICa peak and Q calc", UltimatePeakCa_QcaDialog()
	"Train ICa analysis", TrainICaAnalDialog()
	"Tail Currents analysis in train [should have cursor on trace]", TailCaAnalysis()
	"-"
	"PostAnalysis=>"
	"  MiniAnalysis Table Conversion", MiniAnalysisTableConvDialog()
	"  EPSCs analysis", UltimateMiniAnalDialog()
	"  EPSCs analysis in Trains",UltimateTrainMiniAnalDialog()
//	"  Calculate Phase for onset times", PhaseListCalculationDialog()
	"  Make a Delay List from delays in top graph", MakeDelayList()
	"  Make a Delay list from ALL events in file", DelayList_NOT1stLatONLYDialog()
	"  Calculate Preferred Phase and Vector Strength", VectorStrengthDialog()
	"  Postsynaptic traces Leak Subtraction", DialogLeakSPost()
	"-"
	"Others=>"
	"Remove artifact from trace", RemoveArtifactZero()
	"Remove artifact an fill trace", RemoveArtifact_Fill()
	"Remove artifact and fit trace",  RemoveArtifact_FillFit()
	"Duplicate and Offset baseline in traces from TopGraph", OffsetBaselineDialog()
	"Data Reduction", DataRed()
	"Invert Wave", InvertDialog()
	"Construct wave with voltage protocol", VoltProtGraphDialog()
	"Average Waves", AverageWaveAuxDialog()
	"Transpose Table", TransposeWavesDialog()
	"Calculate Post Ra from transients", RaCalcPostDialog()
//	"Make a delay list from waves in top graph", MakeDelayList()
	//"IHC ICa PP analysis",  PPICaAnalDialog()
End


End

Function TrainICaAnalDialog()
			//prompt
		Variable  file, order=0
		SVAR CurrentFileName
		Variable SweepAsk = str2num(CurrentFileName[9,12])
		file = SweepAsk
		Prompt file, "Sweep number?"
		Prompt order, "Order (0=direct, 1=inverse)?"
		DoPrompt "ICa at Trains Analysis", file, order
			String cmd
			sprintf cmd, "UltimateLeakSubt(%g, 1)", file
			print cmd
			execute cmd

			String cmd2
			sprintf cmd2, "ICaDelayOnsetTrain(%g)", file
			Print cmd2
			Execute cmd2

			String cmd4
			sprintf cmd4, "ICaActTauTrain(%g)", file
			Print cmd4
			Execute cmd4
			
			String cmd3
			sprintf cmd3, "TrainICaAvg(%g)", file
			print cmd3
			Execute cmd3
			//
			String dPeakCa="PeakCa_"+num2str(file)
			String dQCa="QCa_"+num2str(file)
			String dICaDelayOnset="ICaDelayOnset_"+num2str(file)
			String dICaActTau="ICaActTau_"+num2str(file)
			Wave wdPeakCa = $dPeakCa
			Wave wdQCa = $dQCa
			Wave wdICaDelayOnset = $dICaDelayOnset
			Wave wdICaActTau = $dICaActTau
//			Edit $dPeakCa, $dQCa, $dICaDelayOnset, $dICaActTau
End

Function ICaDelayOnsetTrain(file)
	variable  file
	SVAR CurrentFileName
	Wave TimeWave, VProtWave, AuxFitWave, ParamWave, paramwave1
	Variable i, j, CumTime, baseline, Nsteps=0, Nsweeps=0, ndepol=0
	NVAR GapICaAct 
	NVAR SampleInterval
	Variable AcqRate = 1/(SampleInterval*1e-6)
	//Now, list of subtracted sweeps from this 'file'
	String sweep = num2str(file)
	Do
		sweep = "0"+sweep
	While(strlen(sweep)<4)
	//	Printf "File: _%s\r", sweep
	String sAux1 = CurrentFileName[0,7]+"_"+sweep+"_*_2LeakS"
	String WavesToLeakS = WaveList(sAux1, ";","")
	//
	Nsweeps = ItemsInList(WavesToLeakS)
	WaveStats/Q AuxFitWave
	Nsteps = V_npnts
	String sICaDelayOnset
	for(i=0; i<(Nsweeps); i+=1)
		sICaDelayOnset = "ICaDelayOnset_"+num2str(file)+"_"+num2str(i+1)
		Make/O/N=0 $sICaDelayOnset
		Wave wICaDelayOnset = $sICaDelayOnset
		String sWave0 = CurrentFileName[0,7]+"_"+sweep+"_"+num2str(i+1)+"_2LeakS"
		Wave wWave0 = $sWave0
		CumTime=0
		ndepol=0
		for(j=0;j<Nsteps;j+=1)
			if(AuxFitWave[j] > 0)
				InsertPoints ndepol, 1, $sICaDelayOnset
				wICaDelayOnset[ndepol] = GapICaAct
				WaveStats/Q/R=((CumTime-.0003), (CumTime-.00045)) wWave0
				baseline = V_avg
	FindLevel/B=3/EDGE=2/Q/R=((CumTime+GapICaAct), (CumTime+TimeWave[j])) wWave0, baseline
				if(V_flag == 1)
					Printf "Onset for sweep # %g was not found!!/r", (i+1)
				else
					wICaDelayOnset[ndepol] = V_LevelX - CumTime
				endif
				ndepol+=1
			endif
			switch(TimeWave[j])
				case 1000:
					CumTime += ParamWave[i]
				case 2000:
					CumTime += ParamWave1[i]
				default:
					CumTime += TimeWave[j]
			endswitch
//			if(TimeWave[j]!=1000)
//				CumTime += TimeWave[j]
//			else
//				CumTime += ParamWave[i]
//			endif
		endfor
		if(i==0)
			Edit $sICaDelayOnset
		else
			AppendToTable $sICaDelayOnset
		endif
	endfor
	//edit $sICaDelayOnset
End

Function ICaActTauTrain(file)
	Variable  file
	String root = ""
	SVAR CurrentFileName
	Wave TimeWave, VProtWave, AuxFitWave, ParamWave,ParamWave1
	Variable i, j, k, CumTime, baseline, Nsteps=0, Nsweeps=0, Ndepol=0
	NVAR GapICaAct
	NVAR SampleInterval
	Variable AcqRate = 1/(SampleInterval*1e-6)
	//Now, list of subtracted sweeps from this 'file'
	String sweep = num2str(file)
	Do
		sweep = "0"+sweep
	While(strlen(sweep)<4)
//		Printf "File: _%s\r", sweep
	String sAux1 = CurrentFileName[0,7]+"_"+sweep+"_*_2LeakS"
	String WavesToLeakS = WaveList(sAux1, ";","")
	//
	Nsweeps = ItemsInList(WavesToLeakS)
	WaveStats/Q AuxFitWave
	Nsteps = V_npnts
	String sICaDelayOnset, sICaActTau
	for(i=0; i<(Nsweeps); i+=1)
		sICaDelayOnset = root+"ICaDelayOnset_"+num2str(file)+"_"+num2str(i+1)
		Wave wICaDelayOnset = $sICaDelayOnset
		String sWave0 = CurrentFileName[0,7]+"_"+sweep+"_"+num2str(i+1)+"_2LeakS"
		Wave wWave0 = $sWave0
		sICaActTau = "ICaActTau_"+num2str(file)+"_"+num2str(i+1)
		Make/O/N=0 $sICaActTau=0
		Wave wICaActTau = $sICaActTau
		CumTime=0
		ndepol=0
		for(j=0;j<Nsteps;j+=1)
			if(AuxFitWave[j] > 0)
				InsertPoints ndepol,1, $sICaActTau
				if(i==0 && ndepol == 0)
					Display $sWave0
					ModifyGraph rgb($sWave0)=(0,0,0)
				else
					appendtograph $sWave0
					ModifyGraph rgb($sWave0)=(0,0,0)
				endif
				setaxis bottom (CumTime-.001), (CumTime+TimeWave[j]+.001)
				setaxis left -280, 100
				//CurveFit/q exp wWave1 [(Tinit+(1e-3*PreStepDur[j])+wICaDelayOnset[j])*AcqRate+3,(Tinit+(1e-3*PreStepDur[j])+.0015)*AcqRate]/D
CurveFit/q exp_XOffset wWave0 [(CumTime+wICaDelayOnset[j])*AcqRate+3,(CumTime+AuxFitWave[j])*AcqRate-2]/D
				wICaActTau[ndepol] = K2
				ndepol+=1
			endif
					
			switch(TimeWave[j])
				case 1000:
					CumTime += ParamWave[i]
				case 2000:
					CumTime += ParamWave1[i]
				default:
					CumTime += TimeWave[j]
			endswitch
//			
//			if(TimeWave[j]!=1000)
//				CumTime += TimeWave[j]
//			else
//				CumTime += ParamWave[i]
//			endif
		endfor
	endfor
	DoWindow/C ToBeDeleted
	DoWindow/K ToBeDeleted
	String fitWavesToDelete = WaveList("fit_*", ";", "")
	String AuxfitWavesToDelete
	for(i=0; i<(Nsweeps); i+=1)
		sICaActTau = "ICaActTau_"+num2str(file)+"_"+num2str(i+1)
		if(i==0)
			Edit $sICaActTau
		else
			AppendToTable $sICaActTau
		endif
	endfor
	k=0
	Do
		AuxfitWavesToDelete = StringFromList(k, fitWavesToDelete, ";")
		if(strlen(AuxfitWavesToDelete) == 0)
			break
		endif
		KillWaves $AuxfitWavesToDelete
		k+=1
	While(1)
End
Function TrainICaAvg(file)
	Variable  file
	String root = ""
	SVAR CurrentFileName
	Wave TimeWave, VProtWave, AuxFitWave, ParamWave, ParamWave1
	Variable i, j, k, CumTime, baseline, AuxICaPeak, Nsteps=0, Nsweeps=0, Ndepol=0
	NVAR GapICaAct
	NVAR SampleInterval
	Variable AcqRate = 1/(SampleInterval*1e-6)
	//Now, list of subtracted sweeps from this 'file'
	String sweep = num2str(file)
	Do
		sweep = "0"+sweep
	While(strlen(sweep)<4)
//		Printf "File: _%s\r", sweep
	String sAux1 = CurrentFileName[0,7]+"_"+sweep+"_*_2LeakS"
	String WavesToLeakS = WaveList(sAux1, ";","")
	//
	Nsweeps = ItemsInList(WavesToLeakS)
	WaveStats/Q AuxFitWave
	Nsteps = V_npnts
	String sPeakCa, sQCa
	for(i=0; i<(Nsweeps); i+=1)
		String sWave0 = CurrentFileName[0,7]+"_"+sweep+"_"+num2str(i+1)+"_2LeakS"
		Wave wWave0 = $sWave0
		sPeakCa = "PeakCa_"+num2str(file)+"_"+num2str(i+1)
		sQCa = "QCa_"+num2str(file)+"_"+num2str(i+1)
		Make/O/N=0 $sPeakCa=0
		Make/O/N=0 $sQCa=0
		Wave wPeakCa = $sPeakCa
		Wave wQCa = $sQCa
		String sAuxLeakSubtInt = sAux1 + "_Int"
		Make/O $sAuxLeakSubtInt
		Integrate wWave0 /D=$sAuxLeakSubtInt
		CumTime=0
		ndepol=0
		for(j=0;j<Nsteps;j+=1)
			if(AuxFitWave[j] > 0)
				InsertPoints ndepol,1, $sPeakCa, $sQCa
				//Now, calculate Peak ICa
				String sICaDelayOnset = root+"ICaDelayOnset_"+num2str(file)+"_"+num2str(i+1)
				Wave wICaDelayOnset = $sICaDelayOnset
				String sAux2 = CurrentFileName[0,7]+"_"+sweep+"_"+num2str(i+1)+"_2LeakS"
				Wave wAux0 = $sAux2
				WaveStats/Q/R=(CumTime+wICaDelayOnset[j],CumTime+AuxFitWave[j]-.00004) $sAux2
				AuxICaPeak = (V_min + wAux0[AcqRate*V_minloc+1] + wAux0[AcqRate*V_minloc-1])/3
				wPeakCa[ndepol] = AuxICaPeak
				//Now, calculate Q
				Variable Int1 = round((CumTime+wICaDelayOnset[j])*AcqRate)
				Variable Int2 = round((CumTime+AuxFitWave[j])*AcqRate)
				Wave wIntWave0 = $sAuxLeakSubtInt
				Variable aux1 = wIntWave0[int1]
				Variable aux2 = wIntWave0[int2]
				wQCa[ndepol] += (aux1 - aux2)
				ndepol+=1
			endif
			
			switch(TimeWave[j])
				case 1000:
					CumTime += ParamWave[i]
				case 2000:
					CumTime += ParamWave1[i]
				default:
					CumTime += TimeWave[j]
			endswitch
//			if(TimeWave[j]!=1000)
//				CumTime += TimeWave[j]
//			else
//				CumTime += ParamWave[i]
//			endif
		endfor
		if(i==0)
			Edit $sPeakCa, $sQCa
		else
			AppendToTable $sPeakCa, $sQCa
		endif
	endfor
	String IntWavesToDelete = WaveList("*_Int", ";", "")
	Do
		String AuxIntWavesToDelete = StringFromList(k, IntWavesToDelete, ";")
		if(strlen(AuxIntWavesToDelete) == 0)
			break
		endif
		KillWaves $AuxIntWavesToDelete
		k+=1
	While(1)
End

Function EnsembleICaAnal()
	Variable file, EditAsk, IHCAsk = 1
	Prompt file, "File number?"
	Prompt EditAsk, "Show results (1: yes, 0: no)?"
	DoPrompt "Ensemble ICa Analysis", file, EditAsk
	if(V_flag == 1)
		Print "Should indicate file number"
		abort
	endif
	String cmd
	sprintf cmd, "UltimateLeakSubt(%g, %g)", file, IHCAsk
	Print cmd
	Execute cmd
	
	sprintf cmd, "UltimateICaDelayToOnset(%g, %g)", file, EditAsk
	Print cmd
	Execute cmd	
	
	sprintf cmd, "UltimateICaActTau(%g, %g)", file, EditAsk
	Print cmd
	Execute cmd	
	
	sprintf cmd, "UltimatePeakCa_QCa(%g, %g)", file, EditAsk
	Print cmd
	Execute cmd
	
End


Function UltimateLeakSubtDialog()
	Variable file, IHCAsk
	Prompt file, "File number?"
	Prompt IHCAsk, "On IHC? (1: IHC, 0: Post)"
	DoPrompt "Leak Subtraction", file, IHCAsk
	if(V_flag == 1)
		print ""
		abort
	endif
	String cmd 
	sprintf cmd, "UltimateleakSubt(%g, %g)", file, IHCAsk
	print cmd
	execute cmd
end

Function UltimateLeakSubt(file, IHCAsk)
//27mar2013. Changed macro in order to accomodate a second parameter that could change from
//sweep to sweep. Now, there's paramwave and paramwave1, both bring parameters that could change
//15may2014. Cambie la forma en que se determinan los pulsos para calcular el leak. 
//Ahora es flexible el Vh de esos pulsos (se puede cambiar en distintos
//protocolos) y ademas se puede cambiar el orden en el que se los presenta.
	Variable  file, IHCAsk
	SVAR CurrentFileName, IndexCurrFileName
	Variable/G GapICaAct = 0.00026
	Wave TimeWave, VProtWave, AuxFitWave, ParamWave,ParamWave1 //, FitInWave
	Variable i,j, s,DurStep, VoltStep, LeakAtStep, TimeCounter, flagleak
	NVAR SampleInterval
	Variable AcqRate = 1/(SampleInterval*1e-6)
	// Defining Leak Steps and sweeps
	Make/O/N=3 LeakI
	Make/O/N=3 LeakVh
	Make/o/n=16 leakI2
//	LeakVh={-.08,-.07,-.06}
	WaveStats/Q TimeWave
	Variable Nsteps = V_npnts + V_NumNaNs
	String sweep = num2str(file)
	do
		sweep = "0"+sweep
	while(strlen(sweep)<4)
//	String/G IndexCurrFileName = CurrentFileName[0,7]				////////////Also changed this to 6!!!!!!!!!!!!!!!!!!!
	String sAux = IndexCurrFileName+"_"+sweep+"_"
	String sAux1 = sAux+"*_1"
	String WavesToLeakS = WaveList(sAux1, ";","")
	Variable Nsweeps = ItemsInList(WavesToLeakS)
		if(Nsweeps == 0)
			print "No file with that number"
			abort
		endif
		IHCAsk += 1
	//Now, interpolation from leak steps
	For(j=0;j<Nsweeps;j+=1)
		sAux = IndexCurrFileName+"_"+sweep+"_"+num2str(j+1)+"_"+num2str(IHCAsk)
		Wave wAux = $sAux
		String sAuxLeakS = sAux+"LeakS"
		//Calculating Leak from leak steps (-80, -70 and -60 mV)
//		WaveStats/Q/R=((TimeWave[0]+.005), (TimeWave[0]+TimeWave[1]-.002)) wAux
//		LeakI[0] = V_avg//changed 0 to 2 for old files
//		WaveStats/Q/R=((TimeWave[0]+TimeWave[1]+.00936), (TimeWave[0]+TimeWave[1]+.00986)) wAux
//		LeakI[2] = V_avg//changed 2 to 0 for old files
//		WaveStats/Q/R=((TimeWave[1]+TimeWave[0]+TimeWave[2]+.002), (TimeWave[1]+TimeWave[0]+TimeWave[2]+0.003)) wAux//1_0_2_1_0_2
//		LeakI[1] = V_avg// keep 1
		
		//////////////////////////////////15may2014 cambo forma de calcular leak para posterior interpolacion
		s=0
		flagleak = 0
		TimeCounter = 0 //zeroing Timecounter
		do
			if(AuxFitWave[s] < 0)
				LeakVh[flagleak] = VProtWave[s]
				WaveStats/Q/R=(TimeCounter+.004, TimeCounter+.009) wAux
				LeakI[flagleak] = V_Avg
				Timecounter += TimeWave[s]
				s+=1
				flagleak+=1
			elseif(s==Nsteps)
				break
			else
				Timecounter += TimeWave[s]
				s+=1
			endif
		while(1)
		///////////////////////////////////////////////////////////////////15may2014 fin del cambio
		Variable StepLeak
		//Now, duplicate waves and leak subtract them//
		Make/O $sAuxLeakS
		Wave wAuxLeakS = $sAuxLeakS
		wAuxLeakS = 0
		Duplicate/O wAux, $sAuxLeakS
/////////////////////////////////////////////////////////////////////////////////////////////////
		TimeCounter = 0
		for(s=0;s<Nsteps;s+=1)
//			Switch(TimeWave[s])
//				case 1000
			if(TimeWave[s] == 1000)							//New parameter 
				DurStep = ParamWave[j]
			elseif(TimeWave[s] == 2000)
				DurStep = ParamWave1[j]
			else
				DurStep = TimeWave[s]
			endif
			
			if(VProtWave[s] == 1000)
				VoltStep = ParamWave[j]
			elseif((VProtWave[s] == 2000))
				VoltStep = ParamWave1[j]
			else
				VoltStep = VProtWave[s]
			endif
			
			LeakAtStep = interp(VoltStep, LeakVh, LeakI)
			if(VProtWave[s] == 1000)
				leakI2[j] = LeakatStep
			endif
			//Effectively leak subtracting
			for(i=(TimeCounter*AcqRate); i<((DurStep+TimeCounter)*AcqRate); i+=1)
			//	wAuxLeakS[i] = wAuxLeakS[i] - LeakAtStep
				wAuxLeakS[i] -= LeakAtStep
			endfor
			TimeCounter += DurStep
		endfor		
		if(j==0)
			Display $sAuxLeakS
			ModifyGraph rgb($sAuxLeakS)=(0,0,0)
		else
			AppendToGraph $sAuxLeakS
			ModifyGraph rgb($sAuxLeakS)=((30000+10000*(j-1)),(30000+10000*(j-1)),(30000+10000*(j-1)))
		endif
	Endfor
End
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function OldFilesLeakSubt()
		Variable  file
		Prompt file, "File number?"
		DoPrompt "ICa Analysis", file
		if(V_flag==1)
			Print "Should indicate file number"
			abort
		endif
	SVAR CurrentFileName, IndexCurrFileName
	Variable/G GapICaAct
	Wave TimeWave, VProtWave, ParamWave //, FitInWave
	Variable i, j, s, DurStep, VoltStep, LeakAtStep, TimeCounter
	NVAR SampleInterval
	Variable AcqRate = 1/(SampleInterval*1e-6)
	// Defining Leak Steps and sweeps
	Make/O/N=3 LeakI//Should indicate file number
	Make/O/N=3 LeakVh
	LeakVh={-.08,-.07,-.06}
	WaveStats/Q TimeWave
	Variable Nsteps = V_npnts + V_numnans
	String sweep = num2str(file)
	do
		sweep="0"+sweep
	while(strlen(sweep)<4)
		Printf "File: _%s \r", sweep
//	String/G IndexCurrFileName = CurrentFileName[0,6]				////////////Also changed this to 6!!!!!!!!!!!!!!!!!!!
	IndexCurrFileName = CurrentFileName[0,6]
	String sAux = IndexCurrFileName+"_"+sweep+"_"
	String sAux1 = sAux+"*_2"
	String WavesToLeakS = WaveList(sAux1, ";","")
	Variable Nsweeps = ItemsInList(WavesToLeakS)
	//Now, interpolation from leak steps
	For(j=0;j<Nsweeps;j+=1)
		TimeCounter = 0 //zeroing Timecounter
		sAux = IndexCurrFileName+"_"+sweep+"_"+num2str(j+1)+"_2"
		Wave wAux = $sAux
		String sAuxLeakS = sAux+"LeakS"
		//Calculating Leak from leak steps (-80, -70 and -60 mV)
		WaveStats/Q/R=((.32756+.01), (.32756+.18)) wAux//0_0_1
		LeakI[0] = V_avg//changed 0 to 1 for old files
		WaveStats/Q/R=((.34754+.002), (.34754+.006)) wAux//0_1_0_1
		LeakI[1] = V_avg//changed 2 to 1 
		WaveStats/Q/R=((.36754+.002), (.36754+0.008)) wAux//1_0_2_1_0_2
		LeakI[2] = V_avg// changed 1 to 0
		Variable StepLeak
		//Now, duplicate waves and leak subtract them//
		Make/O $sAuxLeakS
		Wave wAuxLeakS = $sAuxLeakS
		wAuxLeakS = 0
		Duplicate/O wAux, $sAuxLeakS
/////////////////////////////////////////////////////////////////////////////////////////////////
//		for(s=0;s<Nsteps;s+=1)
//			if(TimeWave[s] == 1000)
//				DurStep = ParamWave[j]
//				VoltStep = VProtWave[s]
//			elseif(VProtWave[s] == 1000)
//					VoltStep = ParamWave[j]
//					DurSTep = TimeWave[s]
//			else
//					DurStep = TimeWave[s]
//					VoltStep = VProtWave[s]
//			endif
//			LeakAtStep = interp(VoltStep, LeakVh, LeakI)
//			//Effectively leak subtracting
//			for(i=(TimeCounter*AcqRate); i<((DurStep+TimeCounter)*AcqRate); i+=1)
//			//	wAuxLeakS[i] = wAuxLeakS[i] - LeakAtStep
//				wAuxLeakS[i] -= LeakAtStep
//			endfor
//			TimeCounter += DurStep
//		endfor
/////////////////////////////////////////////////////////////////////////////////////////////////////
		wave voltprotforgraph0
		VoltStep = VProtWave[0]
		LeakAtStep = interp(VoltStep, LeakVh, LeakI)
		for(i=0;i<(.00656*AcqRate);i+=1)
			wAuxLeakS[i] -= LeakAtStep
		endfor
		VoltStep = VProtWave[1]
		LeakAtStep = interp(VoltStep, LeakVh, LeakI)
		for(i=(.00659*AcqRate);i<(.00759*AcqRate);i+=1)
			wAuxLeakS[i] -= LeakAtStep
		endfor		
		for(i=(.00759*AcqRate);i<(.20759*AcqRate);i+=1)
			VoltStep = VoltProtforGraph0[i]
			LeakAtStep = interp(VoltStep, LeakVh, LeakI)
			wAuxLeakS[i] -= LeakAtStep
		endfor
			
		
		if(j==0)
			Display $sAuxLeakS
			ModifyGraph rgb($sAuxLeakS)=(0,0,0)
		else
			AppendToGraph $sAuxLeakS
			ModifyGraph rgb($sAuxLeakS)=((30000+10000*(j-1)),(30000+10000*(j-1)),(30000+10000*(j-1)))
		endif
	Endfor
End

Function IntegrateSineICa()
	Variable file
		Prompt file, "File number?"
		DoPrompt "ICa Analysis", file
		if(V_flag==1)
			Print "Should indicate file number"
			abort
		endif
	SVAR CurrentFileName, IndexCurrFileName
	Wave TimeWave, VProtWave, ParamWave //, FitInWave
	Variable i,j, s,k
	NVAR SampleInterval
	Variable AcqRate = 1/(SampleInterval*1e-6)
	// Defining Leak Steps and sweeps
	String sweep = num2str(file)
	do
		sweep="0"+sweep
	while(strlen(sweep)<4)
		Printf "File: _%s \r", sweep
	String sAux = IndexCurrFileName+"_"+sweep+"_"
	String sAux1 = sAux+"*_2"
	String WavesToLeakS = WaveList(sAux1, ";","")
	Variable Nsweeps = ItemsInList(WavesToLeakS)
	String sPeakCa, sQCa
	Variable AuxICaPeak
	for(i=0;i<Nsweeps;i+=1)
		String sWave0 = CurrentFileName[0,6]+"_"+sweep+"_"+num2str(i+1)+"_2LeakS"
		Wave wWave0 = $sWave0
		sPeakCa = "PeakCa_"+num2str(file)+"_"+num2str(i+1)
		sQCa = "QCa_"+num2str(file)+"_"+num2str(i+1)
		Make/O/N=100 $sPeakCa=0
		Make/O/N=100 $sQCa=0
		Wave wPeakCa = $sPeakCa
		Wave wQCa = $sQCa
		String sAuxLeakSubtInt = sWave0 + "_Int"
		Make/O $sAuxLeakSubtInt
		Integrate wWave0 /D=$sAuxLeakSubtInt
		for(j=0;j<100;j+=1)
				//Now, calculate Peak ICa
			WaveStats/Q/R=(.00756, .00756+j*.002) $sWave0
			AuxICaPeak = (V_min + wWave0[AcqRate*V_minloc+1] + wWave0[AcqRate*V_minloc-1])/3
			wPeakCa[j] = AuxICaPeak
				//Now, calculate Q
			Variable Int1 = round((.00756+j*.002)*AcqRate)
			Variable Int2 = round((.00756+(j+1)*.002)*AcqRate)
			Wave wIntWave0 = $sAuxLeakSubtInt
			Variable aux1 = wIntWave0[int1]
			Variable aux2 = wIntWave0[int2]
			wQCa[j] += (aux2 - aux1)
		endfor
		if(i==0)
			Edit $sPeakCa, $sQCa
		else
			AppendToTable $sPeakCa, $sQCa
		endif
	endfor
	String IntWavesToDelete = WaveList("*_Int", ";", "")
	Do
		String AuxIntWavesToDelete = StringFromList(k, IntWavesToDelete, ";")
		if(strlen(AuxIntWavesToDelete) == 0)
			break
		endif
		KillWaves $AuxIntWavesToDelete
		k+=1
	While(1)
end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function UltimateICaDelayToOnsetDialog()
	Variable file, IHCAsk
	Prompt file, "File number?"
	Prompt IHCAsk, "On IHC? (1: IHC, 0: Post)"
	DoPrompt "Ca2+ current delay to onset calculation", file, IHCAsk
	if(V_flag == 1)
		print ""
		abort
	endif
	String cmd 
	sprintf cmd, "UltimateICaDelayToOnset(%g, %g)", file, IHCAsk
	print cmd
	execute cmd
end


Function UltimateICaDelayToOnset(file, EditAsk)
		Variable  file, EditAsk
//		Prompt file, "File number?"
//		DoPrompt "ICa Analysis", file
//		if(V_flag==1)
//			Print "Should indicate file number"
//			abort
//		endif
	SVAR IndexCurrFileName
	Wave TimeWave, VProtWave, AuxFitWave, ParamWave, ParamWave1
	Variable i, j, CumTime, baseline, Nsteps=0, Nsweeps=0, Ndepol=0
	NVAR SampleInterval, GapICaAct
	Variable AcqRate = 1/(SampleInterval*1e-6)
	String sweep = num2str(file)
	Do
		sweep = "0"+sweep
	While(strlen(sweep)<4)
//		Printf "File: _%s\r", sweep
	String sAux1 = IndexCurrFileName+"_"+sweep+"_*_2LeakS"//Changed this 7 to 6
	String WavesToLeakS = WaveList(sAux1, ";","")
	Nsweeps = ItemsInList(WavesToLeakS)
	WaveStats/Q AuxFitWave
	Nsteps = V_npnts
	String sICaDelayOnset
	for(i=0;i<Nsteps;i+=1)
		if(AuxFitWave[i] > 0)
			ndepol+=1
			sICaDelayOnset = "ICaDelayOnset_"+num2str(file)+"_"+num2str(ndepol)
			Make/O/N=(nsweeps) $sICaDelayOnset
			Wave wICaDelayOnset = $sICaDelayOnset
			wICaDelayOnset = GapICaAct
		endif
	endfor
	for(i=0; i<(Nsweeps); i+=1)
		Ndepol=0
		sICaDelayOnset = "ICaDelayOnset_"+num2str(file)+"_"+num2str(ndepol+1)
		Wave wICaDelayOnset = $sICaDelayOnset
		String sWave0 = IndexCurrFileName+"_"+sweep+"_"+num2str(i+1)+"_2LeakS"
		Wave wWave0 = $sWave0
		CumTime=0
		for(j=0; j<(Nsteps); j+=1)
			if(AuxFitWave[j] > 0)
				Ndepol+=1
				sICaDelayOnset = "ICaDelayOnset_"+num2str(file)+"_"+num2str(ndepol)
				Wave wICaDelayOnset = $sICaDelayOnset
				WaveStats/Q/R=((CumTime-.0003), (CumTime-.00045)) wWave0
				baseline = V_avg
				FindLevel/B=1/EDGE=2/Q/R=((CumTime+GapICaAct), (CumTime+TimeWave[j])) wWave0, baseline
				if(V_flag == 1)
					Printf "	Onset for sweep # %g was not found!!\r", (i+1)
				else
					wICaDelayOnset[i] = V_LevelX - CumTime
				endif
			endif
			if(TimeWave[j] ==1000)
				CumTime += ParamWave[i]
			elseif(TimeWave[j] ==2000)
				CumTime += ParamWave1[i]
			else
				CumTime += TimeWave[j]
			endif
		endfor
	endfor
	if(EditAsk == 1)
		for(i=0; i<(ndepol); i+=1)
			sICaDelayOnset = "ICaDelayOnset_"+num2str(file)+"_"+num2str(i+1)
			if(i==0)
				Edit/N=ICaParam $sICaDelayOnset
			else
				AppendToTable $sICaDelayOnset
			endif
		endfor
	endif
	//edit $sICaDelayOnset
End
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function UltimateICaActTauDialog()
	Variable file, IHCAsk
	Prompt file, "File number?"
	Prompt IHCAsk, "On IHC? (1: IHC, 0: Post)"
	DoPrompt "Ca2+ current activation tau", file, IHCAsk
	if(V_flag == 1)
		print ""
		abort
	endif
	String cmd 
	sprintf cmd, "UltimateICaActTau(%g, %g)", file, IHCAsk
	print cmd
	execute cmd
end

Function UltimateICaActTau(file, EditAsk)
		Variable  file, EditAsk
		String path = ""
	SVAR IndexCurrFileName
	Wave TimeWave, VProtWave, AuxFitWave, ParamWave, ParamWave1
	Variable i, j, k, CumTime, baseline, Nsteps=0, Nsweeps=0, Ndepol=0
	NVAR GapICaAct
	NVAR SampleInterval
	Variable AcqRate = 1/(SampleInterval*1e-6)
	String sweep = num2str(file)
	Do
		sweep = "0"+sweep
	While(strlen(sweep)<4)
//		Printf "File: _%s \r", sweep
	String sAux1 = IndexCurrFileName+"_"+sweep+"_*_2LeakS"//Changed this 7 to 6
	String WavesToLeakS = WaveList(sAux1, ";","")
	Nsweeps = ItemsInList(WavesToLeakS)
	WaveStats/Q AuxFitWave
	Nsteps = V_npnts
	String sICaActTau, sICaDelayOnset
	for(i=0;i<Nsteps;i+=1)
		if(AuxFitWave[i] > 0)
			ndepol+=1
			sICaActTau = "ICaActTau_"+num2str(file)+"_"+num2str(ndepol)
			Make/O/N=(Nsweeps) $sICaActTau
		endif
	endfor
	for(i=0; i<(Nsweeps); i+=1)
		Ndepol = 0
		String sWave0 = IndexCurrFileName+"_"+sweep+"_"+num2str(i+1)+"_2LeakS"//Changed this 7 to 6
		Wave wWave0 = $sWave0
		CumTime=0
		if(i==0)
			Display wWave0
			ModifyGraph rgb($sWave0) = (0,0,0)
		else
			AppendToGraph wWave0
			ModifyGraph rgb($sWave0) = (0,0,0)
		endif
		for(j=0; j<(Nsteps); j+=1)
			if(AuxFitWave[j] > 0)
				ndepol+=1
				sICaDelayOnset = path + "ICaDelayOnset_"+num2str(file)+"_"+num2str(ndepol)
				Wave wICaDelayOnset = $sICaDelayOnset
				sICaActTau = "ICaActTau_"+num2str(file)+"_"+num2str(ndepol)
				Wave wICaActTau = $sICaActTau
				SetAxis bottom (CumTime-.004), (CumTime+.004)
				SetAxis left -300, 100
		//		if(TimeWave[j]!=1000)
		CurveFit/Q exp_XOffset wWave0 [round(AcqRate*(CumTime+wICaDelayOnset[i])),round(AcqRate*(CumTime+AuxFitWave[j]-.0001))] /D
		//		else
		//			CurveFit/Q exp_XOffset wWave0 [round(AcqRate*(CumTime+wICaDelayOnset[i])),round(AcqRate*(CumTime+ParamWave[i]-.0001))] /D
		//		endif
				wICaActTau[i] = K2
			endif
			if(TimeWave[j] == 1000)
				CumTime += ParamWave[i]
			elseif(TimeWave[j] == 2000)
				CumTime += ParamWave1[i]
			else
				CumTime += TimeWave[j]
			endif
		endfor
	endfor
	DoWindow/C ToBeDeleted
	DoWindow/K ToBeDeleted
	String fitWavesToDelete = WaveList("fit_*", ";", "")
	String AuxfitWavesToDelete
	if(EditAsk ==1)
		for(i=0; i<(ndepol); i+=1)
			sICaActTau = "ICaActTau_"+num2str(file)+"_"+num2str(i+1)
//			if(i==0)
//				Edit $sICaActTau
//			else
				AppendToTable/W=ICaParam $sICaActTau
//			endif
		endfor
	endif
	k=0
	Do
		AuxfitWavesToDelete = StringFromList(k, fitWavesToDelete, ";")
		if(strlen(AuxfitWavesToDelete) == 0)
			break
		endif
		KillWaves $AuxfitWavesToDelete
		k+=1
	While(1)
End
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function UltimatePeakCa_QcaDialog()
	Variable file, IHCAsk
	Prompt file, "File number?"
	Prompt IHCAsk, "On IHC? (1: IHC, 0: Post)"
	DoPrompt "Ca2+ peak current and charge calc", file, IHCAsk
	if(V_flag == 1)
		print ""
		abort
	endif
	String cmd 
	sprintf cmd, "UltimatePeakCa_QCa(%g, %g)", file, IHCAsk
	print cmd
	execute cmd
end

Function UltimatePeakCa_QCa(file, EditAsk)
	// To change back (31 Ago 2012)
	//ICa Delay Onset name
	//IndexCurrFileName declaration
		Variable  file, EditAsk
		Variable tail=0
//		Prompt file, "File number?"
		Prompt tail, "Integrate tail (yes: 1, no:0)?"
		DoPrompt "ICa Analysis", tail
		if(V_flag==1)
			Print "Should indicate file number"
			abort
		endif
	//SVAR IndexCurrFileName 
	SVAR IndexCurrFileName
//	String/G IndexCurrFileName = CurrentFileName[0,7]
	Wave TimeWave, VProtWave, AuxFitWave, ParamWave, ParamWave1
	Variable i, j, k, CumTime, baseline, ndepol=0, int1, int2
	NVAR SampleInterval
	Variable AcqRate = 1/(SampleInterval*1e-6)
	String sweep = num2str(file)
	Do
		sweep = "0"+sweep
	While(strlen(sweep)<4)
//		Printf "File: _%s \r", sweep
	String sAux1 = IndexCurrFileName+"_"+sweep+"_*_2LeakS"
	String WavesToLeakS = WaveList(sAux1, ";","")
	Variable Nsweeps = ItemsInList(WavesToLeakS)
	WaveStats/Q AuxFitWave
	Variable Nsteps = V_npnts
	String sPeakCa, sQCa, sICaDelayOnset
	for(i=0;i<Nsteps;i+=1)
		if(AuxFitWave[i] > 0)
			ndepol+=1
			sPeakCa = "PeakCa_"+num2str(file)+"_"+num2str(ndepol)
			sQCa = "QCa_"+num2str(file)+"_"+num2str(ndepol)
			Make/O/N=(Nsweeps) $sPeakCa, $sQCa
		endif
	endfor
	for(i=0; i<(Nsweeps); i+=1)
		String sWave0 = IndexCurrFileName+"_"+sweep+"_"+num2str(i+1)+"_2LeakS"
		Wave wWave0 = $sWave0
		String sIntWave0 = sWave0+"_Int"
		Make/O $sIntWave0
		Integrate wWave0 /D=$sIntWave0
		Wave wIntWave0 = $sIntWave0
		CumTime=0
		Ndepol=0
		for(j=0; j<(Nsteps); j+=1)
			if(AuxFitWave[j] > 0)
				ndepol+=1
				sICaDelayOnset = "ICaDelayOnset_"+num2str(file)+"_"+num2str(ndepol)	//
				Wave wICaDelayOnset = $sICaDelayOnset
				sPeakCa = "PeakCa_"+num2str(file)+"_"+num2str(ndepol)
				Wave wPeakCa = $sPeakCa
				sQCa = "QCa_"+num2str(file)+"_"+num2str(ndepol)
				Wave wQCa = $sQCa
				if(TimeWave[j] == 1000)
					WaveStats/Q/R=((CumTime+wICaDelayOnset[i]),(CumTime+ParamWave[i]-.0002)) wWave0
					if(tail == 1)
						int2 = round(AcqRate*(CumTime+ParamWave[i]+.002))
					elseif(tail == 0)
						int2 = round(AcqRate*(CumTime+ParamWave[i]))
					endif
				elseif(TimeWave[j] == 2000)
					WaveStats/Q/R=((CumTime+wICaDelayOnset[i]),(CumTime+ParamWave1[i]-.0002)) wWave0
					if(tail == 1)
						int2 = round(AcqRate*(CumTime+ParamWave1[i]+.002))
					elseif(tail == 0)
						int2 = round(AcqRate*(CumTime+ParamWave1[i]))
					endif					
				else
					WaveStats/Q/R=((CumTime+wICaDelayOnset[i]),(CumTime+AuxFitWave[j]-.0002)) wWave0
					if(tail == 1)
						int2 = round(AcqRate*(CumTime+AuxFitWave[j]+.002))
					elseif(tail == 0)
						int2 = round(AcqRate*(CumTime+AuxFitWave[j]))
					endif
				endif
				wPeakCa[i] = (1/3)*(V_min + wWave0[round(AcqRate*V_minLoc)-1] + wWave0[round(AcqRate*V_minLoc)+1])
				//print wWave0[AcqRate*(V_minLoc -1)]
				int1 = round(AcqRate*(CumTime+wICaDelayOnset[i]))
				wQCa[i] = wIntWave0[int2] - wIntWave0[int1]
			endif
			if(TimeWave[j] == 1000)
				CumTime += ParamWave[i]
			elseif(TimeWave[j] == 2000)
				CumTime += ParamWave1[i]
			else
				CumTime += TimeWave[j]
			endif
			
//			if(TimeWave[j] != 1000)
//				CumTime += TimeWave[j]
//			else
//				CumTime += ParamWave[i]
//			endif
		endfor
				//graph
	endfor
	if(EditAsk == 1)
		for(i=0; i<(ndepol); i+=1)
			sPeakCa = "PeakCa_"+num2str(file)+"_"+num2str(i+1)
			sQCa = "QCa_"+num2str(file)+"_"+num2str(i+1)
//			if(i==0)
//				Edit $sPeakCa, $sQCa
//			else
				AppendToTable/W=ICaParam $sPeakCa,  $sQCa
//			endif
		endfor
	endif
	String IntWavesToDelete = WaveList("*_Int", ";", "")
	Do
		String AuxIntWavesToDelete = StringFromList(k, IntWavesToDelete, ";")
		if(strlen(AuxIntWavesToDelete) == 0)
			break
		endif
		KillWaves $AuxIntWavesToDelete
		k+=1
	While(1)
End

Function VoltProtGraphDialog()
	Variable  sweepdur
	Prompt sweepdur, "Sweep Duration (s)?"
	DoPrompt "Volt protocol wave", sweepdur
	
	String cmd3
	sprintf cmd3, "VoltProtGraph(%g)", sweepdur
	print cmd3
	Execute cmd3
End


Function VoltProtGraph(sweepdur)
	Variable sweepdur
	Wave TimeWave, VProtWave, ParamWave
	NVAR SampleInterval
	WaveStats/Q TimeWave
	Variable i,j, Nsteps= V_npnts, CumTime, AcqRate = 1/(SampleInterval*1e-6), NProt, k
	Variable tlap
	WaveStats/Q ParamWave
	if(V_npnts==0)
		NProt = 1
	else
		NProt = V_npnts
	endif
	
    for(j=0; j<NProt; j+=1)
       String sVoltProt = "VoltProtforGraph"+num2str(j)
    	Make/O/N=(sweepdur*AcqRate) $sVoltProt
    	Wave VoltProtforGraph = $sVoltProt
    	VoltProtforGraph = 5000
	SetScale/p x,0,(SampleInterval*1e-6), $sVoltProt
	CumTime=0
	for(i=0;i<Nsteps;i+=1)
		if(VProtWave[i] == 1000)
			VoltProtforGraph[CumTime*AcqRate, (CumTime+TimeWave[i])*AcqRate] = ParamWave[j]
			CumTime += TimeWave[i]
		elseif(TimeWave[i] == 1000)
			VoltProtforGraph[CumTime*AcqRate, (CumTime+ParamWave[j])*AcqRate] = VProtWave[i]
			CumTime += ParamWave[j]
		else
			VoltProtforGraph[CumTime*AcqRate, (CumTime+TimeWave[i])*AcqRate] = VProtWave[i]
			CumTime += TimeWave[i]
		endif
	endfor
	     for(k=0;k<(AcqRate*sweepdur); k+=1)
 		    	if(VoltProtforGraph[k]==5000)
   		  		VoltProtforGraph[k] = -.08
 		    	endif
 	    endfor
     endfor

End


		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function MiniAnalysisTableConvDialog()
	Variable sweep, TimeAdj = 1
	Prompt sweep, "File number?"
	Prompt TimeAdj, "Apply 'seconds' scale on Time and RiseTime, 10-90% RT, Decay (0: No, 1: Yes)?"
	DoPrompt "File", sweep, TimeAdj
	String cmd
			sprintf cmd, "MiniAnalysisTableConversion(%g, %g)", sweep, TimeAdj
			Print cmd
			Execute cmd
End
Function MiniAnalysisTableConversion(sweep, TimeAdj)
	Variable sweep, TimeAdj
	Variable i=0, j, nevents
	Make/T/O/N=18 AuxNewWaveNames
	AuxNewWaveNames[0] = "Number", AuxNewWaveNames[1]="Time", AuxNewWaveNames[2]="Amplitude"
	AuxNewWaveNames[3]="Rise", AuxNewWaveNames[4]="Decay", AuxNewWaveNames[5]="Area"
	AuxNewWaveNames[6]="Baseline", AuxNewWaveNames[7]="Noise", AuxNewWaveNames[8]="Group"
	AuxNewWaveNames[9]="Channel", AuxNewWaveNames[10]="10_90Rise", AuxNewWaveNames[11]="Halfwidth"
	AuxNewWaveNames[12]="Rise50", AuxNewWaveNames[13]="PeakDir", AuxNewWaveNames[14]="Burst"
	AuxNewWaveNames[15]="BurstE", AuxNewWaveNames[16]="10_90Slope", AuxNewWaveNames[17]="RelTime"
	AuxNewWaveNames[18] = "extra"
	String sAuxFolderName = "Sw"+num2str(sweep)+"Folder"
	NewDataFolder $sAuxFolderName
	String sAuxOldWaveNames, sAuxNewWaveNames
	Do	
		sAuxOldWaveNames = WaveName("table1",0,3)
		variable aux = strlen(sAuxOldWaveNames)
		if(aux==0)
			break
		endif
		sAuxOldWaveNames = sAuxOldWaveNames[0, (aux-3)]
		WaveStats/q $sAuxOldWaveNames
		nevents = (V_npnts)
		sAuxNewWaveNames = "Sw"+num2str(sweep)+"_"+AuxNewWaveNames[i]
		Make/O/N=(nevents) $sAuxNewWaveNames
		Wave wAuxNewWaveNames = $sAuxNewWaveNames
//		if(i==0)
			Wave wAuxOldWaveNames = $sAuxOldWaveNames
			for(j=0;j<(nevents);j+=1)
				wAuxNewWaveNames[j] = wAuxOldWaveNames[j]
			endfor
//		else
//			Wave/T wAuxOldWaveNames2 = $sAuxOldWaveNames
//			for(j=0;j<(nevents);j+=1)
//				wAuxNewWaveNames[j] = str2num(wAuxOldWaveNames2[j+1])
//			endfor
//		endif
		RemoveFromTable $sAuxOldWaveNames
		Killwaves $sAuxOldWaveNames
//		MoveWave root:sAuxNewWaveNames, :$sAuxFolderName:
		i+=1
	while(1)

	if(TimeAdj == 1)
		sAuxNewWaveNames = "Sw"+num2str(sweep)+"_"+AuxNewWaveNames[1]
		Wave wAuxNewWaveNames = $sAuxNewWaveNames
		wAuxNewWaveNames /= 1000
		sAuxNewWaveNames = "Sw"+num2str(sweep)+"_"+AuxNewWaveNames[3]
		Wave wAuxNewWaveNames = $sAuxNewWaveNames
		wAuxNewWaveNames /= 1000
		sAuxNewWaveNames = "Sw"+num2str(sweep)+"_"+AuxNewWaveNames[4]
		Wave wAuxNewWaveNames = $sAuxNewWaveNames
		wAuxNewWaveNames /= 1000
		sAuxNewWaveNames = "Sw"+num2str(sweep)+"_"+AuxNewWaveNames[10]
		Wave wAuxNewWaveNames = $sAuxNewWaveNames
		wAuxNewWaveNames /= 1000
	endif
	
	MoveWavesToFolder(sweep)
End

Function MoveWavesToFolder(sweep)
	Variable sweep
	Variable i
	Wave/T AuxNewWaveNames
	String Aux2 = "root:Sw"+num2str(sweep)+"Folder:"
			String sweep2 = num2str(sweep)///
			do ////////////////////////////////////////Little trick for referring to Axon file
				sweep2 = "0"+sweep2////////
			while(strlen(sweep2)<4)/////////
	//String sSweepParamsAux = "root:SweepParams_"+sweep2
	//MoveWave $sSweepParamsAux, $Aux2
	for(i=0;i<18;i+=1)
		String Aux1 = "root:Sw"+num2str(sweep)+"_"+AuxNewWaveNames[i]
		MoveWave $Aux1, $Aux2
	endfor
End

//Function PreDepolIVDialog()
//	Variable sweep, Totaltime = .23
//	Prompt sweep, "File number?"
//	Prompt Totaltime, "Sweeps order? (0=Direct, 1=Inverse)"
//	DoPrompt "File", sweep, totaltime//, order//, TestStepPot
//	String cmd
//			sprintf cmd, "PreDepolIV(%g, %g)", sweep, totaltime//, order//, TestStepPot
//			Print cmd
//			Execute cmd
//End
//
//
//Function PreDepolIV(sweep, totaltime)
//	Variable sweep, Totaltime
////	Wave ParamValues
//	Variable i, j, k,nevents, Tinit, cyclen, auxj
//	Wave ParamWave, TimeWave, AuxFitWave
////	WaveStats/q ParamWave
//	String sSw_Amplitude = ":Sw"+num2str(sweep)+"Folder:Sw"+num2str(sweep)+"_Amplitude"
//	String sSw_Time = ":Sw"+num2str(sweep)+"Folder:Sw"+num2str(sweep)+"_Time"
//	String sSw_Group = ":Sw"+num2str(sweep)+"Folder:Sw"+num2str(sweep)+"_Group"
//	String sSw_Rise = ":Sw"+num2str(sweep)+"Folder:Sw"+num2str(sweep)+"_Rise"
//	Wave wSw_Amplitude = $sSw_Amplitude
//	Wave wSw_Time = $sSw_Time
//	Wave wSw_Group = $sSw_Group
//	Wave wSw_Rise = $sSw_Rise
//	String sPostAmp = "PostAmp_"+num2str(sweep)
//	String sPostDelayCorr = "PostDelayCorr_"+num2str(sweep)
//	Make/O/N=(1) $sPostAmp, $sPostDelayCorr//,$sPostDelay
//	Wave wPostAmp = $sPostAmp
//	Wave wPostDelayCorr = $sPostDelayCorr
//	//Now, variable setting
//	wPostAmp=0
//	wPostDelaycorr=10000
// 	WaveStats/Q wSw_Amplitude
//	nevents = V_npnts
////	WaveStats/q TimeWave
////	for(k=0;k<V_npnts; k+=1)
////		if(TimeWave[k] != 1000)
////			Totaltime += TimeWave[k]
////		endif
////	endfor
////	k=0
//	Do
//		if(TimeWave[k]!=1000)
//			Tinit += TimeWave[k]
//		endif
//		k+=1
//	While(AuxFitWave[k] == 0)
//	//
//	for(i=0;i<nevents;i+=1)
//		auxj = floor(wSw_Time[i] / (1000*TotalTime))
//		if(auxj != j)
//			InsertPoints (j+1),1, $sPostAmp, $sPostDelayCorr
//			wPostDelaycorr[j+1]=10000
//			Totaltime += P
//		endif
//		j = auxj
////		if(order==0)
////			cyclen = j
////		elseif(order==1)
////			cyclen = 5 - j
////		endif
//		wPostAmp[j] += wSw_Amplitude[i]
//		wPostDelayCorr[j] = min(wPostDelaycorr[j], (wSw_Time[i] - wSw_Rise[i] - 1000*(Tinit + ParamWave[j]) - j*Totaltime*1000))
//	endfor
//End

Function UltimateMiniAnalDialog()
	Variable file, Totaltime
	Prompt file, "File number?"
	Prompt Totaltime, "Total duration of the protocol (s)?"
	DoPrompt "File", file, totaltime
	String cmd
			sprintf cmd, "UltimateMiniAnal(%g, %g)", file, totaltime
			Print cmd
			Execute cmd
End

Function UltimateMiniAnal(file, totaltime)
	//20Dec12=> Included rise time
	Variable file, Totaltime
	Variable TotalSweeps
	Variable i, j, k=0,  Nsweep, ntestp =0, l, TotalTestP=0, Onset, TTest, TestDur, m
	Variable flag, flag1, EventRateSS = 0
	Wave ParamWave, TimeWave, AuxFitWave, ParamWave1
	String sSw_Amplitude = ":Sw"+num2str(file)+"Folder:Sw"+num2str(file)+"_Amplitude"
	String sSw_Time = ":Sw"+num2str(file)+"Folder:Sw"+num2str(file)+"_Time"
	String sSw_Group = ":Sw"+num2str(file)+"Folder:Sw"+num2str(file)+"_Group"
	String sSw_Rise = ":Sw"+num2str(file)+"Folder:Sw"+num2str(file)+"_Rise"
	Wave wSw_Amplitude = $sSw_Amplitude
	Wave wSw_Time = $sSw_Time
	Wave wSw_Group = $sSw_Group
	Wave wSw_Rise = $sSw_Rise
			
	WaveStats/Q wSw_time
	if(V_npnts > 1)
		TotalSweeps = ceil(V_max / totaltime)			//Set Number of sweeps
	elseif(wSw_Time[0] < totaltime)
		TotalSweeps = 1
	else	
		TotalSweeps = ceil(V_max / totaltime)
	endif
	Variable NEvents = V_npnts
	
	WaveStats/Q TimeWave
	for(i=0;i<V_npnts;i+=1)					//Now, set number of test pulses in protocol and 
		if(AuxFitWave[i] > 0)					//simultaneously, create amp and delay waves for collecting data.
			TotalTestP += 1
			String sPostAmp = "PostAmp_"+num2str(file)+"_"+num2str(TotalTestP)
			String sPostDelay = "PostDelay_"+num2str(file)+"_"+num2str(TotalTestP)
			String sPostRT = "PostRT_"+num2str(file)+"_"+num2str(TotalTestP)
			Make/O/N=(TotalSweeps) $sPostDelay
			Make/O/N=(TotalSweeps) $sPostAmp
			Make/O/N=0 $sPostRT
			Wave wPostDelay = $sPostDelay
			Wave wPostAmp = $sPostAmp
			Wave wPostRT = $sPostRT
			wPostDelay =1000
			wPostAmp = 0
		endif
	endfor
	//
	String sPostAmp_Onset = "PostAmp_Onset_" + num2str(file)
	String sPostAmp_SS = "PostAmp_SS_" + num2str(file)
	Make/O/N=(TotalSweeps) $sPostAmp_Onset, $sPostAmp_SS			//Added to macro 26Mar2013
	Wave wPostAmp_Onset = $sPostAmp_Onset
	Wave wPostAmp_SS = $sPostAmp_SS
	wPostAmp_Onset = 0
	wPostAmp_SS = 0
	
	
	Do  //NEvents, counts on k,	//Loops over test pulse in each sweep, j is sweep counter
		l=0			//l counts steps in protocol
		TTest = 0
		ntestp = 0
		flag = 0
		if(wSw_Time[k] < (j+1)*TotalTime)				
	  		Do								//Loops over the depolarizing pulses in protocol, counter is ntestp (total number of pulses is TotalTestP
				TestDur = 0
				Do
					if(TimeWave[l] == 1000)						//Sets time of test pulse for two purposes:
						TTest += ParamWave[j]
					elseif(TimeWave[l] == 2000)
						TTest += ParamWave1[j]
					else	
						TTest +=TimeWave[l]
					endif
					l+=1
				While(AuxFitWave[l] <= 0)
				if(TimeWave[l] == 1000)
					TestDur = ParamWave[j]
				elseif(TimeWave[l] == 2000)
					TestDur = ParamWave1[j]
				else
					TestDur = TimeWave[l]
				endif
				sPostAmp = "PostAmp_"+num2str(file)+"_"+num2str(ntestp+1)			//Sets wave name for collecting results
				sPostDelay = "PostDelay_"+num2str(file)+"_"+num2str(ntestp+1)			//
				sPostRT = "PostRT_"+num2str(file)+"_"+num2str(TotalTestP)
				Wave wPostAmp = $sPostAmp										//
				Wave wPostDelay = $sPostDelay										//
				Wave wPostRT = $sPostRT
				Onset = wSw_Time[k] - wSw_Rise[k] - j*TotalTime - TTest				//
				if((Onset > 0) && (Onset < TestDur+.01))
					wPostAmp[j] += wSw_Amplitude[k]
					wPostDelay[j] = min(Onset, wPostDelay[j])
					InsertPoints flag1, 1, $sPostRT	///		20.5.13 => Para arreglar mas adelante
					if(ntestp == 0)
					  if(Onset < .01)
						wPostAmp_Onset[j] += wSw_Amplitude[k]
					  elseif((Onset>(TestDur - .2)) && (Onset < TestDur))
						wPostAmp_SS[j] += wSw_Amplitude[k]
						EventRateSS += 1
					  endif
					endif
					flag = 1			
				endif
				ntestp +=1
			While((flag == 0) && (ntestp < TotalTestP))
			k+=1
			//endfor	//Loops over pulse number, ntestp
		else
			j+=1
		endif	//checks if event k corresponds to sweep, j
	While((k<NEvents) && (j < TotalSweeps))//endfor		//Loops over sweeps number, j
	
	for(j=0; j<totalSweeps; j+=1)
		if(wPostDelay[j] == 1000)
			wPostDelay[j]=nan
		endif
	endfor
	EventRateSS *= 5/6
	Printf "Event rate at steady-state is: %g\r", EventRateSS
End

Function DelayList_NOT1stLatONLYDialog()
	Variable file,  SweepN, SweepDur, ExcludeLast = 1
	Prompt file, "File number?"
	Prompt SweepN, "Sweep number (0 for all sweeps)?"
	Prompt SweepDur, "Total duration of the protocol (s)?"
	Prompt ExcludeLast, "Exclude last cycle (test pulse) (1: yes, 0: no)"
	DoPrompt "File", file, SweepN, SweepDur, ExcludeLast
	String cmd
			sprintf cmd, "DelayList_NOT1stLatONLY(%g, %g, %g, %g)", file, SweepN, SweepDur, ExcludeLast
			Print cmd
			Execute cmd
End

Function DelayList_NOT1stLatONLY(file, SweepN, SweepDur, ExcludeLast)
//Will exclude last cycle, to exclude test pulse
//30Jul2012
	Variable  file, SweepN, SweepDur, ExcludeLast
	Variable NSweeps, Tinit, Nsteps, Ndepol =0
	Variable i,j,k,m,DelayInCycle, Nevents, CumTime, CycleCounter, flag = 0, E, flagE
	Wave TimeWave, AuxFitWave, VProtWave, ParamWave
	Make/O/N=2 PeriodDur
	
	String sTime = ":Sw"+num2str(File)+"Folder:Sw"+num2str(File)+"_Time"
	String sRise = ":Sw"+num2str(File)+"Folder:Sw"+num2str(File)+"_Rise"
	String sAmp = ":Sw"+num2str(File)+"Folder:Sw"+num2str(File)+"_Amplitude"
	String sGroup = ":Sw"+num2str(File)+"Folder:Sw"+num2str(File)+"_Group"
	Wave wTime = $sTime
	Wave wRise = $sRise
	Wave wAmp = $sAmp
	Wave wGroup = $sGroup

	WaveStats/q $sTime
	Nevents = V_npnts
	NSweeps = ceil(V_max/SweepDur)
	WaveStats/Q AuxFitWave
	NSteps = V_npnts
	
	for(i=0;i<NSteps;i+=1)											//	This section sets a PeriodDur wave
		CumTime += TimeWave[i]									//	that collects the period duration for each depol
		if(AuxFitWave[i] > 0)										//	(constant for a periodic train).
			Ndepol += 1											//	
			if(Ndepol == 1)										//	
				PeriodDur[0] = CumTime - TimeWave[i]				//	PeriodDur[0] is the train initiation point
				PeriodDur[1] = TimeWave[i] + TimeWave[i+1]		//
			else													//
				InsertPoints (Ndepol), 1, PeriodDur
				PeriodDur[Ndepol] = TimeWave[i] + TimeWave[i+1]	//
			endif												//
		endif													//
	endfor														//
	
	String sAllDelayList = "AllDelayList_"+num2str(file)
	Make/o/n=0 $sAllDelayList
	Wave wAllDelayList = $sAllDelayList

	////////////////////////////////////////Actual calculation//////////////////////////////////
	i=0													// i counts events in MiniAnalysis table
	k=0													//k counts sweep number. 
	if(SweepN != 0)
		k = SweepN-1
	endif
	E=0													//E count event number in DelayList
	Do
	if(wGroup[i] != 255)
		CycleCounter = 1									//counts cycles
		CumTime = PeriodDur[0]							//PeriodDur[0] is train onset time
		flag = 0											//flag 
		If(wTime[i]<SweepDur*(k+1))														// Test if event (i) occurred in Sweep (k)
				Do																			//	Loops over CycleCounter in order to find the cycle at which
					DelayInCycle = wTime[i] - wRise[i] -  CumTime - k*sweepDur					//	event (i) occurred
					if((DelayInCycle < PeriodDur[CycleCounter]) && (DelayInCycle >= 0))			//	Tests for this.
//						wAmpByCycle[CycleCounter-1] += wAmp[i]
						InsertPoints E,1, wAllDelayList
						wAllDelayList[e] = DelayInCycle
//						wDelayByCycle[CycleCounter-1] = min(DelayInCycle, wDelayByCycle[CycleCounter-1])
						flag = 1
						E+=1
						i+=1
					elseif (DelayInCycle < 0)												// To avoid late events in a train that intefere in measurements
						i+=1															// of following train
					else																		
						CumTime += PeriodDur[CycleCounter]
						CycleCounter += 1													//  If event (i) doesn't occur in cycle (cyclecounter)
					endif																	//  adds 1 to cyclecounter
				While((flag == 0) && (CycleCounter <= (Ndepol-ExcludeLast)))									// And keeps doing it, while cyclecounter<Ndepol
		  else
			   k+=1
			   if(SweepN != 0)
			   	printf "Only analyzed events in sweep number# %g\r", SweepN
			   	abort
			   endif
		  endif
		  if(cyclecounter > (Ndepol-ExcludeLast))
		  	i+=1
		  endif
	else
		i+=1
	endif
	While((i<Nevents) && (k <= NSweeps))
End
	
	

//Function AmpDelayByCycle(File)
//	Variable File
//	Variable Tinit = 127.4, Frequency =100, Npulses = 20, SweepDur = 410, Nsweeps=4
//	Variable i,j,k,m,DelayInCycle, Nevents
//	String sDelaybyCycle = "DelayByCycle_"+num2str(File)+"_1"
//	Make/O/N=(Npulses) $sDelaybyCycle
//	Wave wDelayByCycle = $sDelaybyCycle
//	wDelayByCycle = 1000
//	String sTime = ":Sw"+num2str(File)+"Folder:Sw"+num2str(File)+"_Time"
//	String sRise = ":Sw"+num2str(File)+"Folder:Sw"+num2str(File)+"_Rise"
//	String sAmp = ":Sw"+num2str(File)+"Folder:Sw"+num2str(File)+"_Amplitude"
//	WaveStats/q $sTime
//	Nevents = V_npnts
//	Wave wTime = $sTime
//	Wave wRise = $sRise
//	Wave wAmp = $sAmp
//
//		Do	
//			DelayInCycle = wTime[i] -  Tinit - j*1000/Frequency - k*sweepDur - wRise[i]
//			if(wTime[i] > (SweepDur*(k+1)))
//				for(m=0;m<Npulses;m+=1)
//					if(wDelayByCycle[m] == 1000)
//						wDelayByCycle[m]=nan
//					endif
//				endfor
//				k+=1
//				j=0
//				String sDelaybyCycle2 = "DelayByCycle_"+num2str(File)+"_"+num2str(k+1)
//				Make/O/N=(Npulses) $sDelaybyCycle2
//				Wave wDelayByCycle = $sDelaybyCycle2
//				wDelayByCycle = 1000
//			else
//				if(DelayInCycle<(1000/Frequency))// && DelayInCycle<(1000/Frequency))
//					wDelayByCycle[j] = min(DelayInCycle, wDelayByCycle[j])
//					i+=1
//				else
//					j+=1
//				endif
//			endif
//		While(i<Nevents)
//	for(m=0;m<Npulses;m+=1)
//		if(wDelayByCycle[m] == 1000)
//			wDelayByCycle[m]=nan
//		endif
//	endfor
//End

Function ConstructSinglePhaseListDialog()
		String FilesList
		Variable Group
	//Prompt
		Prompt FilesList, "List of Files (separated by commas)"
		Prompt Group, "Group number?"
		DoPrompt "Single phase list construction", FilesList, Group
			String cmd
			sprintf cmd, "ConstructSinglePhaseList(\"%s\", %g)", FilesList, Group
			Print cmd
			Execute cmd
End


Function ConstructSinglePhaseList(FileList, NSweeps, Half)
	String FileList
	Variable NSweeps,Half
	Variable i,j, tag0, k
	String AuxPhaseList, AuxPhaseList2
	Make/O/N=0 FinalPhaseList
	Do
		AuxPhaseList = StringFromList(i, FileList, ",")
			if(strlen(AuxPhaseList)==0) 
				break
			endif
	   for(k=0;k<NSweeps;k+=1)
		AuxPhaseList2 = "root:n20mV:DelayByCycle_" + AuxPhaseList + "_"+ num2str(k)
		Wave wAuxPhaseList = $AuxPhaseList2
		WaveStats/Q wAuxPhaseList
		InsertPoints (j+tag0), V_npnts, FinalPhaseList
		for(j=0;j<V_npnts;j+=1)
			FinalPhaseList[j+tag0] = wAuxPhaseList[j]
		endfor
		WaveStats/Q FinalPhaseList
		tag0 = V_npnts
		endfor
	   i+=1
	While(1)
	//
	Edit FinalPhaseList
	String NewName
	Variable binwidth, Nbins
	Prompt NewName, "Choose New Name for Final Phase List"
	Prompt binwidth, "Choose bin widht for histogram (ms)"
	Prompt Nbins, "Number of bins?"
	DoPrompt "Parameters for histogram", NewName, binwidth, Nbins
	Make/N=(Nbins) FinalPhaseList_Hist
	String cmd
	sprintf cmd, "Histogram/B={0,%g, %g} FinalPhaseList, FinalPhaseList_Hist", binwidth, Nbins
	print cmd
	Execute cmd
	Rename FinalPhaseList, $NewName
	String NewName_Hist = NewName+"_Hist"
	Rename FinalPhaseList_Hist, $NewName_Hist
	Display $NewName_Hist
End


//Function AmpDelayByCycle_Test()
//	Variable  file
//	String Aux = WaveList("AmpbyCycle*", ";", "")
//	Variable Tinit = 137.4, Frequency = 25, Npulses = 20, SweepDur =1050, Nsweeps=4, TrainEnd=899.4
//	if(strlen(Aux) == 0)
//		Prompt file, "File number?"
//		Prompt Tinit, "Train initiation time?"
//		Prompt Frequency, "Frequency?"
//		Prompt Npulses, "Number of pulses?"
//		Prompt Nsweeps, "Number of sweeps?"
//		Prompt TrainEnd, "Train end time?"
//		DoPrompt "Train Post Analysis", file, Tinit, Frequency, Npulses, Nsweeps, TrainEnd
//		if(V_flag==1)
//			Print "Should indicate file number"
//			abort
//		endif
////		Printf "File: _%g \r", file
//	else
//		Prompt file, "File number?"
//		DoPrompt "ICa Analysis", file
//		if(V_flag==1)
//			Print "Should indicate file number"
//			abort
//		endif
//		Printf "File: _%g \r", file
//	endif
//	
//	Variable i,j,k,m,DelayInCycle, Nevents
//	String sTime = ":Sw"+num2str(File)+"Folder:Sw"+num2str(File)+"_Time"
//	String sRise = ":Sw"+num2str(File)+"Folder:Sw"+num2str(File)+"_Rise"
//	String sAmp = ":Sw"+num2str(File)+"Folder:Sw"+num2str(File)+"_Amplitude"
//	String sGroup = ":Sw"+num2str(File)+"Folder:Sw"+num2str(File)+"_Group"
//	WaveStats/q $sAmp
//	Nevents = V_npnts
//	Wave wTime = $sTime
//	Wave wRise = $sRise
//	Wave wAmp = $sAmp
//	Wave wGroup = $sGroup
//	   	String sAmpByCycle = "AmpByCycle_"+num2str(File)+"_1"
//		String sDelayByCycle = "DelayByCycle_"+num2str(File)+"_1"
//		Make/O/N=(Npulses+1) $sAmpByCycle, $sDelayByCycle
//		Wave wAmpByCycle = $sAmpByCycle
//		Wave wDelayByCycle = $sDelayByCycle
//		wAmpByCycle=0
//		wDelayByCycle=1000
//	Do
//		  If(wTime[i]<SweepDur*(k+1))
//			DelayInCycle = wTime[i] -  Tinit - j*1000/Frequency - k*sweepDur - wRise[i]
//			if((wTime[i]<(TrainEnd+k*SweepDur)) && (wTime[i] > (Tinit+k*SweepDur)))
//				if(DelayInCycle<(1000/Frequency))
//					wAmpByCycle[j] += wAmp[i]
//					wDelayByCycle[j] = min(DelayInCycle, wDelayByCycle[j])
//					i+=1
//				else
//					j+=1
//				endif
//			elseif((wTime[i]>(TrainEnd+10+k*SweepDur)) && (wTime[i]<(TrainEnd+30+k*SweepDur)))
//				DelayInCycle = wTime[i] - wRise[i] - (TrainEnd+10+k*SweepDur)
//				wAmpByCycle[Npulses+1] += wAmp[i]
//				wDelayByCycle[Npulses+1] = min(DelayInCycle, wDelayByCycle[Npulses+1])
//				i+=1
//			else
//				i+=1
//			endif
//		  else
//			   k+=1
//			   j=0
//			   for(m=0;m<(Npulses+1);m+=1)
//				if(wDelayByCycle[m] == 1000)
//					wDelayByCycle[m]=nan
//				endif
//			   endfor
//	   		  sAmpByCycle = "AmpByCycle_"+num2str(File)+"_"+num2str(k+1)
//			  sDelayByCycle = "DelayByCycle_"+num2str(File)+"_"+num2str(k+1)
//			  make/O/N=(Npulses+1) $sAmpByCycle, $sDelayByCycle
//			  Wave wAmpByCycle = $sAmpByCycle
//			  Wave wDelayByCycle = $sDelayByCycle
//			  wAmpByCycle=0
//			  wDelayByCycle=1000
//		  endif
//	While(i<Nevents)
//		   for(m=0;m<(Npulses+1);m+=1)
//			if(wDelayByCycle[m] == 1000)
//				wDelayByCycle[m]=nan
//			endif
//		    endfor
//End

Function UltimateTrainMiniAnalDialog()
	//13 Jan 2012
	//Now, calculates single EPSC
	Variable file , Exclude = 1, Totaltime = .42, RTByCycle = 2

	Prompt file, "File number?"
	Prompt Totaltime, "Total duration of the protocol (s)?"
	Prompt Exclude, "Exclude events#255 from analysis? (0: No. 1: Yes)"
	Prompt RTByCycle, "Calculate RT by Cycle? (0: No. If yes, indicate from which cycle #)"
	DoPrompt "File", file, totaltime, Exclude, RTByCycle
	String cmd
		sprintf cmd, "UltimateTrainEPSCAnal(%g, %g, %g, %g)", file, totaltime, Exclude, RTByCycle
		Print cmd
		Execute cmd
End

Function UltimateTrainEPSCAnal(file, SweepDur, Exclude, RTByCycle)
	Variable  file, SweepDur, Exclude, RTByCycle
	Variable NSweeps, Tinit, Nsteps, Ndepol =0, step, step1
	Variable i,j,k,m,DelayInCycle, Nevents, CumTime, CycleCounter, flag = 0, E, flagE
	Wave TimeWave, AuxFitWave, VProtWave, ParamWave, ParamWave1
	Make/O/N=2 PeriodDur
	String sSingleEPSCAmp = "SingleEPSCAmp_"+num2str(file)
	Make/O/N=0 $sSingleEPSCAmp
	Wave wSingleEPSCAmp = $sSingleEPSCAmp
	
	String sTime = ":Sw"+num2str(File)+"Folder:Sw"+num2str(File)+"_Time"
	String sRise = ":Sw"+num2str(File)+"Folder:Sw"+num2str(File)+"_Rise"
	String sAmp = ":Sw"+num2str(File)+"Folder:Sw"+num2str(File)+"_Amplitude"
	String sGroup = ":Sw"+num2str(File)+"Folder:Sw"+num2str(File)+"_Group"
	Wave wTime = $sTime
	Wave wRise = $sRise
	Wave wAmp = $sAmp
	Wave wGroup = $sGroup

	WaveStats/q $sTime
	Nevents = V_npnts
	NSweeps = ceil(V_max/SweepDur)
	WaveStats/Q AuxFitWave
	NSteps = V_npnts
	
	for(j=0; j<Nsweeps; j+=1)
		CumTime = 0
		NDepol = 0
		//////////////////////////////////////First set protocol paradigm to follow
		for(i=0;i<NSteps;i+=1)											//	This section sets a PeriodDur wave
			if(TimeWave[i]==2000)
				CumTime += ParamWave1[j]							//	that collects the period duration for each depol
				Step = ParamWave1[j]
			elseif(TimeWave[i]==1000)
				CumTime += ParamWave[j]
				Step = ParamWave[j]
			else
				CumTime += TimeWave[i]
				Step = TimeWave[i]
			endif
			if(TimeWave[i+1] == 2000)
				Step1 = ParamWave1[j]
			elseif(TimeWave[i+1] == 1000)
				Step1 = ParamWave[j]
			else
				Step1 = TimeWave[i+1]
			endif
			if(AuxFitWave[i] > 0)										//	(constant for a periodic train).
				Ndepol += 1											//	
				if(Ndepol == 1)										//
					PeriodDur[0] = CumTime - Step					//	PeriodDur[0] is the train initiation point
					PeriodDur[1] = Step + Step1						//
				else													//
					InsertPoints (Ndepol), 1, PeriodDur
					PeriodDur[Ndepol] = Step + Step1					//
				endif												//
			endif													//
		endfor														//
		///////////////////////////////////////
	   	String sAmpByCycle = "AmpByCycle_"+num2str(File)+"_"+num2str(j+1)			// Creates Amp ,Delay
		String sDelayByCycle = "DelayByCycle_"+num2str(File)+"_"+num2str(j+1)			// and First EPSC rise time
		if(RTByCycle > 0)																//waves for each sweep
			String sFirstRTByCycle = "FirstRTByCycle_"+num2str(File)+"_"+num2str(j+1)	//
			Make/o/n=(ndepol)  $sFirstRTByCycle
			Wave wFirstRTByCycle = $sFirstRTByCycle
		endif
		Make/O/N=(Ndepol) $sAmpByCycle, $sDelayByCycle						//
		Wave wAmpByCycle = $sAmpByCycle										//
		Wave wDelayByCycle = $sDelayByCycle									//
		wAmpByCycle=0
		wDelayByCycle=1000
	endfor
	sAmpByCycle = "AmpByCycle_"+num2str(File)+"_1"
	sDelayByCycle = "DelayByCycle_"+num2str(File)+"_1"
	Wave wAmpByCycle =  $sAmpByCycle
	Wave wDelayByCycle =  $sDelayByCycle
	if(RTByCycle > 0)
		sFirstRTByCycle = "FirstRTByCycle_"+num2str(File)+"_1"
		Wave wFirstRTByCycle = $sFirstRTByCycle
		wFirstRTByCycle = 0
	endif
	////////////////////////////////////////Actual calculation//////////////////////////////////
	i=0													// i counts events in MiniAnalysis table
	k=0													//k counts sweep number. 
	E=0
	Do
		CycleCounter = 1									//counts cycles
		CumTime = PeriodDur[0]							//PeriodDur[0] is train onset time
		flag = 0											//flag 
		If(wTime[i]<SweepDur*(k+1))						// Test if event (i) occurred in Sweep (k)
			If((wGroup[i] == 255) && (Exclude == 1))		// && (k != 0))
		     		i+=1
			else
				Do																			//	Loops over CycleCounter in order to find the cycle at which
					DelayInCycle = wTime[i] - wRise[i] -  CumTime - k*sweepDur					//	event (i) occurred
					if((DelayInCycle < PeriodDur[CycleCounter]) && (DelayInCycle >= 0))			//	Tests for this.
						wAmpByCycle[CycleCounter-1] += wAmp[i]
						wDelayByCycle[CycleCounter-1] = min(DelayInCycle, wDelayByCycle[CycleCounter-1])
						if(wFirstRTByCycle[CycleCounter-1] > 0)								/////////Now, checks whether event (i) is first 
						elseif(RTByCycle > 0)														//in cycle	
							wFirstRTByCycle[CycleCounter-1] = wRise[i]								// If yes, it would be considered for 
						endif																	//10-90% rise time measurement per cycle
						flag = 1
						i+=1
						if(CycleCounter > 2 && CycleCounter < Ndepol)							//Checks now if event occurred after cycle 2
							InsertPoints E,1, wSingleEPSCAmp								//If so, will use it for collecting amplitudes
							wSingleEPSCAmp[E] = wAmp[i-1]									//and calculating average amplitude later on.
							E+=1
						endif
					elseif (DelayInCycle < 0)												// To avoid late events in a train that intefere in measurements
						i+=1															// of following train
					else																		
						CumTime += PeriodDur[CycleCounter]
						CycleCounter += 1													//  If event (i) doesn't occur in cycle (cyclecounter)
					endif																	//  adds 1 to cyclecounter
				While((flag == 0) && (CycleCounter <= Ndepol))									// And keeps doing it, while cyclecounter<Ndepol
				if(CycleCounter >	 Ndepol)														// flag = 1 represents that an event occurred in that one cycle
					k+=1
					i+=1
					for(m=0;m<(Ndepol+1);m+=1)
						if(wDelayByCycle[m] == 1000)
							wDelayByCycle[m]=nan
						endif
						if(wFirstRTByCycle[m] == 0)
							wFirstRTByCycle[m] = nan
						endif
					endfor
		   			sAmpByCycle = "AmpByCycle_"+num2str(File)+"_"+num2str(k+1)
					sDelayByCycle = "DelayByCycle_"+num2str(File)+"_"+num2str(k+1)
					Wave wAmpByCycle = $sAmpByCycle
					Wave wDelayByCycle = $sDelayByCycle
					if(RTByCycle > 0)
						sFirstRTByCycle = "FirstRTByCycle_"+num2str(File)+"_"+num2str(k+1)
						Wave wFirstRTByCle = $sFirstRTByCycle
					endif
				endif
			endif
		  else
			   k+=1
//			   CycleCounter = 1
			   for(m=0;m<(Ndepol+1);m+=1)
				if(wDelayByCycle[m] == 1000)
					wDelayByCycle[m]=nan
				endif
				if(wFirstRTByCycle[m] == 0)
					wFirstRTByCycle[m] = nan
				endif
			   endfor
	   		  sAmpByCycle = "AmpByCycle_"+num2str(File)+"_"+num2str(k+1)
			  sDelayByCycle = "DelayByCycle_"+num2str(File)+"_"+num2str(k+1)
			  Wave wAmpByCycle = $sAmpByCycle
			  Wave wDelayByCycle = $sDelayByCycle
			  if(RTByCycle > 0)
				   sFirstRTByCycle = "FirstRTByCycle_"+num2str(File)+"_"+num2str(k+1)
				  Wave wFirstRTByCycle = $sFirstRTByCycle
			endif
		  endif
	While(i<=Nevents)
		   for(m=0;m<(ndepol+1);m+=1)
			if(wDelayByCycle[m] == 1000)
				wDelayByCycle[m]=nan
			endif
			if(RTByCycle > 0)
				if(wFirstRTByCycle[m] == 0)
					wFirstRTByCycle[m] = nan
				endif
			endif
		   endfor
End

//Function PostDtn20_test()
//		Variable  file
//		Prompt file, "File number?"
//		DoPrompt "ICa Analysis", file
//		if(V_flag==1)
//			Print "Should indicate file number"
//			abort
//		endif
//	SVAR CurrentFileName
//	Variable i,j, s, k,m,EPSCOnset, Nsteps, Nevents, SweepDur= 250, T1ini = 83.9
//	Wave ParamWave, TimeWave
//
//	// Defining Leak Steps and sweeps
//	String sweep = num2str(file)
//	do
//		sweep="0"+sweep
//	while(strlen(sweep)<4)
//		Printf "File: _%s \r", sweep
////	String sAux1 = CurrentFileName[0,7]+"_"+sweep+"_*_1"
////	String WavesToLeakS = WaveList(sAux1, ";","")
////	Variable Nsweeps = ItemsInList(WavesToLeakS)
//	WaveStats/Q ParamWave
//	Variable Nsweeps = V_npnts
//
//	///////////////////////////////////////////////////////////////////////////////////////
//	String sSw_Amplitude = ":Sw"+num2str(file)+"Folder:Sw"+num2str(file)+"_Amplitude"
//	String sSw_Time = ":Sw"+num2str(file)+"Folder:Sw"+num2str(file)+"_Time"
//	String sSw_Group = ":Sw"+num2str(file)+"Folder:Sw"+num2str(file)+"_Group"
//	String sSw_Rise = ":Sw"+num2str(file)+"Folder:Sw"+num2str(file)+"_Rise"
//	Wave wSw_Amplitude = $sSw_Amplitude
//	Wave wSw_Time = $sSw_Time
//	Wave wSw_Group = $sSw_Group
//	Wave wSw_Rise = $sSw_Rise
//	
//	String sPostAmp1 = "PostAmp_"+num2str(file)+"_1"
//	String sPostAmp2 = "PostAmp_"+num2str(file)+"_2"
//	String sPostDelayCorr1 = "PostDelayCorr_"+num2str(file)+"_1"
//	String sPostDelayCorr2 = "PostDelayCorr_"+num2str(file)+"_2"
//	Make/O/N=(Nsweeps) $sPostAmp1, $sPostDelayCorr1,$sPostAmp2, $sPostDelayCorr2
//	Wave wPostAmp1 = $sPostAmp1
//	Wave wPostAmp2 = $sPostAmp2
//	Wave wPostDelayCorr1 = $sPostDelayCorr1
//	Wave wPostDelayCorr2 = $sPostDelayCorr2
//	
//	wPostAmp1=0
//	wPostAmp2=0
//	wPostDelayCorr1=1000
//	wPostDelayCorr2=1000
//	//wPostDelay[0] = wSw_Time[0]	- 1000*(Tinit - PreStepDur[j])
// 	WaveStats/Q wSw_Amplitude
//	nevents = V_npnts
//	for(i=0;i<nevents;i+=1)
//		EPSCOnset = wSw_Time[i] - wSw_Rise[i]
//		k=0
//		Do
//			k+=1
//		While(EPSCOnset>(SweepDur*k))
//		k-=1
//		if(EPSCOnset<(T1ini+ParamWave[k]*1000+10+SweepDur*k))
//			wPostAmp1[k] += wSw_Amplitude[i]
//			wPostDelayCorr1[k] = min(wPostDelaycorr1[k], (EPSCOnset-T1ini-k*SweepDur))
//		elseif(EPSCOnset<(T1ini+ParamWave[k]*1000+110+SweepDur*k))
//			wPostAmp2[k] += wSw_Amplitude[i]
//			wPostDelayCorr2[k] = min(wPostDelaycorr2[k], (EPSCOnset-T1ini-100-ParamWave[k]*1000-k*SweepDur))
//		endif
//	endfor
//		for(m=0;m<(Nsweeps);m+=1)
//			if(wPostDelayCorr1[m] == 1000)
//				wPostDelayCorr1[m]=nan
//			endif
//			if(wPostDelayCorr2[m] == 1000)
//				wPostDelayCorr2[m]=nan
//			endif
//		endfor
//	Edit $sPostAmp1, $sPostAmp2, $sPostDelayCorr1, $sPostDelayCorr2
//End

Function InvertDialog()
		String sWave1
		Prompt sWave1, "Wave?"
		DoPrompt "Wave to invert", sWave1
		if(V_flag==1)
			Print "Should indicate a wave name"
			abort
		endif
//		Wave wave1 = $sWave1
		Invert($sWave1)
end

Function Invert(wave0)
	Wave wave0
	Variable Aux, Aux1, Aux2, Aux3, i
	WaveStats/Q wave0
	Aux3 = V_npnts/2
	Aux2 = trunc(Aux3)
	If((Aux3 - Aux2) == 0)
		Aux = V_npnts/2
	else
		Aux = (V_npnts/2) -1
	endif
	for(i=0; i<Aux; i+=1)
		Aux1 = wave0[i]
		wave0[i] = wave0[V_npnts - i -1]
		wave0[V_npnts - i -1] = Aux1
	endfor
End

Function RemoveArtifactZero()
	Variable t1, t2, i, av
	Wave w=CsrWaveRef(A)
  
	t1=pcsr(A); t2=pcsr(B)

	for (i=t1;i<t2;i+=1)
		w[i]=0
		
	endfor 
End


Function RemoveArtifact_Fill()
	Variable t1, t2, i, av
	NVAR SampleInterval
	Wave w=CsrWaveRef(A)
  
	t1=pcsr(A); t2=pcsr(B)
	for (i=t1+1;i<t2;i+=1)
		w[i]=nan
	endfor
	
CurveFit/NTHR=0/Q/TBOX=0 line w[pcsr(A), pcsr(B)] /D
	for (i=t1;i<t2;i+=1)
		w[i]=K1*i*SampleInterval*1e-6 + K0
	endfor 
	 
End

Function RemoveArtifact_FillFit()

string sFrequencies= "5;10;20;80;"

	Variable t1, t2, i, av
 Variable SampleInterval = 19.49// (19.49)
 	Variable Freq= 5
 		variable TotalNstim=11
 	
 	string sFReq
 	
 	Prompt SampleInterval, "Sampling Interval:"
 	Prompt sFreq, "Train Stimulation Frequency:" ,popup ,sFrequencies
 	 	Prompt TotalNStim, "Total Pulses:"
 	DoPrompt "Stimulation Characteristics", SampleInterval, sFreq,TotalNstim
 	
		if(V_flag==1)
			abort
		endif
		
		

	If (str2num (sFReq) ==5)
 		Freq=1/0.19999// 5.00025001250062
 		//TotalNstim=16
 	endif
 	
 	If (str2num (sFReq) ==10)
 		Freq=1/0.049992// 5.00025001250062
 		//TotalNstim=10
 	endif
 	
 	
 	If (str2num (sFReq)==20)
 	Freq=1/0.049993 //20.0032005120819
 	//TotalNstim=60
 	endif
 	
	If (str2num(sFReq)==80)
	Freq= 1/0.012494 //80.0448251020571
	//TotalNstim=240
	endif
	
	
	variable Nstim
	
	Wave w=CsrWaveRef(A)
 	

	t1=pcsr(A); t2=pcsr(B)
	
		
	for(nstim=1;nstim<=totalnstim;nstim+=1)
	
	 for (i=t1+1;i<t2;i+=1)
		w[i]=nan
	endfor 
	
	
	CurveFit/NTHR=0/Q/TBOX=0 line w[t1, t2+1] /D
	
	for (i=t1;i<t2;i+=1)
		w[i]=K1*i*SampleInterval*1e-6 + K0
	endfor 
	
	t1=pcsr(A) +nstim*(1/(SampleInterval*1e-6*Freq))
	t2=pcsr(B) +nstim*(1/(SampleInterval*1e-6*Freq))
	
	
	endfor
End



Function RemoveArtifact_Fill_train()
	Variable t1, t2, i, j
	Variable Freq=20.0032	
	variable Nstim=60
	variable SampleInterval = 1.949e-005
	Wave w=CsrWaveRef(A)
  
	t1=pcsr(A); t2=pcsr(B)
	CurveFit/NTHR=0/Q/TBOX=0 line w[pcsr(A), pcsr(B)] /D
	for (i=t1;i<t2;i+=1)
		w[i]=K1*i*SampleInterval*1e-6 + K0
	endfor 
End

Function RemoveArtifactZeroInTrain()
	Variable t1, t2, i, j
	Variable Freq=80		
	variable Nstim=10
	
	NVAR SampleInterval
	Wave w=CsrWaveRef(A)
  
	t1=pcsr(A); t2=pcsr(B)
	for(j=0;j<Nstim;j+=1)
		for (i=t1;i<t2;i+=1)
			w[i+j*(1/(19.49*1e-6*Freq))]=nan
		endfor 
 	endfor
End

Function TailCaAnalysis()
		//Before starting, should set Cursor on the trace to analyze
		// right before the tail starts.
		//Then, will keep the parameter for the rest of the train
	NVAR SampleInterval
	Wave TimeWave, AuxFitWave, VProtWave, ParamWave
	Wave wICa=CsrWaveRef(A)
	String sICa = CsrWave(A)
	Variable AuxFileNumber = str2num(sICa[9,12])
	Variable CumTime, i, j, ndepol = 0, AcqRate =  1/(SampleInterval*1e-6)
		Printf "File: _%g \r", AuxFileNumber
	Do
		String sTailQCa = "TailQCa_" + num2str(AuxFileNumber)+"_"+num2str(j+1)
		String sTailPeakCa = "TailPeakCa_" + num2str(AuxFileNumber)+"_"+num2str(j+1)
		String sTailICaDecay = "TailICaDecay" +num2str(AuxFileNumber)+"_"+num2str(j+1)
		if(WaveExists($sTailQCa) == 0)
			break
		endif
		j+=1
	While(1)		

	Make/O/N=0 $sTailQCa, $sTailPeakCa, $sTailICaDecay
	Wave wTailQCa = $sTailQCa
	Wave wTailPeakCa = $sTailPeakCa
	Wave wTailICaDecay = $sTailICaDecay
	Integrate wICa /D=ICaInt
	WaveStats/Q TimeWave
	for(i=0;i<V_npnts; i+=1)									//Loops over # protocol steps
		CumTime += TimeWave[i]
		if(AuxFitWave[i] > 0)									//analyze only in case of depolarization
			InsertPoints ndepol, 1, $sTailQCa, $sTailPeakCa,  $sTailICaDecay
			ndepol+=1
			if(ndepol ==1)
				FindLevel/Q/P/EDGE=2/R=(xcsr(A), (xcsr(A)+.0019)) wICa, 0// Finds onset of tail current
				Variable XGap = V_LevelX - CumTime*AcqRate				//Stores this value on XGap, relative to step duration
				Variable XGap2 = XGap + CumTime*AcqRate				//This gap will be used for the rest of the train
			else
				XGap2 = XGap+CumTime*AcqRate
			endif
			wTailQCa[ndepol] = ICaInt[XGap2+ 50] - ICaInt[XGap2]
			WaveStats/Q/R=[XGap2, XGap2+50] wICa
			wTailPeakCa[ndepol] = V_min
			SetAxis bottom (CumTime-.002),(CumTime+.002)
	CurveFit/Q exp_XOffset wICa [round(V_minloc*AcqRate+2), round(AcqRate*(V_minloc+.0015))-5] /D
			 wTailICaDecay[ndepol] = K2
		endif
	endfor
	Edit $sTailQCa, $sTailPeakCa, $sTailICaDecay
End

Function Find10to90()
	NVAR SampleInterval
	Wave TimeWave, AuxFitWave, VProtWave, ParamWave
	Wave wICa=CsrWaveRef(A)
	String sICa = CsrWave(A)
	Variable AuxFileNumber = str2num(sICa[9,12])
	Variable CumTime, i, j, ndepol = 0
		Printf "File: _%g \r", AuxFileNumber
	
	Variable baseline, top, tbaseline, ttop
	WaveStats/Q/R=(xcsr(A)-.0001, xcsr(a)) wICa
	baseline = V_avg
	WaveStats/Q/R=(xcsr(b), xcsr(b)+.0001) wICa
	top=V_avg
	FindLevel/q/R=(xcsr(a),xcsr(b)) wICa, (.1*(top-baseline)+baseline)
	tbaseline = V_levelX
	FindLevel/q/R=(xcsr(a),xcsr(b)) wICa, (.9*(top-baseline)+baseline)
	ttop = V_levelX	
	print ttop-tbaseline
End


Function DataRed()
	String file
	Variable RedFactor
		Prompt file, "File name? (Leave blank in case of files in active window)"
		Prompt RedFactor, "Reduction factor?"
		DoPrompt "ICa Analysis", file, RedFactor
		if(V_flag==1)
			Print "Should indicate file number"
			abort
		endif
	Variable Interv, Npoints, i,j
	if(stringmatch(file,"") == 1)
		string EnsembleNames = ""
		Do
			Wave WavetoRed = WaveRefIndexed("",j,1)
			if(WaveEXists(WavetoRed) == 0)
				break
			endif
			Interv = deltax(WavetoRed)
			Wavestats/q Wavetored
			NPoints = V_npnts
			String sReducedWave = nameofwave(WavetoRed)+"Red"
			ensembleNames += nameofwave(wavetored) + ", "
			Make/o/n=(Npoints/RedFactor) $sReducedWave
			wave wReducedWave = $sReducedWave
			for(i=0; i<(Npoints/RedFactor); i+=1)
				wReducedWave[i] = WavetoRed[i*RedFactor]
			endfor
			j+=1
			setscale/p x,0, (RedFactor*interv), $sreducedwave
		while(1)
		Printf " %s", Ensemblenames
		Printf "\r Reduction factor: %g\r", RedFactor
	else
		Interv = deltax(file)
		Printf file
		Printf  "\t Reduction factor: %g\r", RedFactor
		Wave wFile = $file
		WaveStats/Q $File
		Npoints = V_npnts
		String RedFile = File+"Red"
		Make/O/N = (NPoints/RedFactor) $RedFile
		Wave wRedFile = $RedFile
		for(i=0; i<(Npoints/RedFactor); i+=1)
			wRedFile[i] = wFile[i*RedFactor]
		endfor
		setscale/p x,0, (RedFactor*interv), $RedFile
	endif
End
Function concatAxon(file)
	variable file
	Variable i
	String sweepcomp = num2str(file)
	String IndexCurrFileName = "MM14306A"
	do
		sweepcomp = "0"+sweepcomp
	while(strlen(sweepcomp)<4)
	String sweepparams = "SweepParams_"+sweepcomp
	Wave/t wSweepParams = $sweepparams
	Variable Nsweeps =100// str2num(wSweepParams[5][1])
	Variable NPoints =1500// round(str2num(wSweepParams[3][1]) / Nsweeps)
	String sWave = IndexCurrFileName+"_" + sweepcomp
	Wave wWave = $sWave
	String sConcatFile = sWave +"Conc"
	Make/o/n=(NPoints) $sConcatFile
	Wave wConcatFile = $sConcatFile
	sWave += "_1_1"
	Wave wWave = $sWave
	wConcatFile = wWave
	for(i=1;i<NSweeps;i+=1)
		sWave = IndexCurrFileName+"_" + sweepcomp + "_"+num2str(i)+"_1"
		Wave wWave = $sWave
		Concatenate/NP{wWave}, $sConcatfile
	endfor
end

Function First10ms(file, Totaltime)
	Variable file, Totaltime
	SVAR CurrentFileName
	Variable i, j=0, Tinit = .2106
	String sTime = ":Sw"+num2str(file)+"Folder:Sw"+num2str(file)+"_Time"
	Wave wTime = $sTime
	String sAmplitude = ":Sw"+num2str(file)+"Folder:Sw"+num2str(file)+"_Amplitude"
	Wave wAmplitude = $sAmplitude
	String sRise = ":Sw"+num2str(file)+"Folder:Sw"+num2str(file)+"_Rise"
	Wave wRise = $sRise
	String sPostamp = "PostAmpFirst_"+num2str(file)+ "_1"
	Make/O/N=7 $sPostAmp
	Wave wPostAmp = $sPostAmp
	wPostAmp = 0
	WaveStats/Q wTime
	for(i=0; i<V_npnts; i+=1)
		Variable Timing = (wTime[i]- wRise[i] - j*Totaltime)
		if((Timing < (Tinit + .01)) && (Timing > 0))
			wPostAmp[j] += wAmplitude[i]
		elseif(Timing > 0)
			j+=1
		endif
		
	endfor
End

Function CumPlot(wWave)
	Wave wWave
	Variable i, NPoints
	WaveStats/Q wWave
	Npoints = V_npnts - 1
	String sCumWave = NameofWave(wWave) + "Cum"
	Make/O/N=(Npoints) $sCumWave
	Wave wCumWave = $sCumWave
	wCumWave[0] = wWave[0]
	for(i=1; i<Npoints; i+=1)
		wCumWave[i] = wCumWave[i-1] + wWave[i]
	endfor
End

Function VectorStrengthDialog()
	String sPhaseList
	Variable NPi, Period
	
	Prompt sPhaseList, "Name of List of Times Wave", popup, WaveList("*list*",";","")
	Prompt NPi, "N Pi?"
	Prompt Period, "Period (s)?"
	DoPrompt "Phase calculation + Vector Strength", sPhaseList, NPi, Period
	string cmd
	sprintf cmd, "VectorStrength(%s, %g, %g)", sPhaseList, NPi, Period
	Print cmd
	Execute cmd
end

Function VectorStrength(PhaseList, NPi, Period)
	Wave PhaseList
	Variable NPi, Period
	Variable SumCos, SumSin, PhaseList_vector, Phase
//	Wave FinalPhaseListCorr_n30mV_250Hz
	WaveStats/q PhaseList
	Make/O/N=(V_npnts) PhaseList_Ang, PhaseList_cos, PhaseList_sin
	
	PhaseList_Ang = PhaseList*2*pi/Period
	PhaseList_cos = cos(PhaseList_Ang)
	WaveStats/Q PhaseList_cos
	SumCos= V_Sum
	PhaseList_sin = sin(PhaseList_Ang)
	WaveStats/Q PhaseList_sin
	SumSin = V_Sum
	PhaseList_vector = sqrt(SumCos^2 + SumSin^2)/V_npnts
	Phase = ((atan(SumSin/SumCos))+NPi*pi)*Period/(2*pi)
//	print sumsin, sumcos
	printf "Vector Strength = %g\t Average phase = %g\r", phaselist_vector, Phase
End

function MakeDelayList()
	Variable FirstCycle, LastCycle
	String root
	Prompt FirstCycle, "Indicate 1st cycle to use"
	prompt LastCycle, "Indicate last cycle to use"
	Prompt root, "Subfolder?"
	DoPrompt "Will select waves from top graph", FirstCycle, LastCycle, root
//	if(Half>2)
//		printf "Half should be 0, 1st or 2nd"
//		abort
//	endif
//	if(strlen(root)>0)
//		root = ":"+root+":"
//	endif
//	String Table0
	String sAuxWave
//	String WavesToInc = WaveList( "*", ";","WIN:Table2")
	String WavesToInc = TraceNameList("", ";", 1)
	printf "MakeDelayList from: %g\t to %g\r%s\r", FirstCycle, LastCycle, WavestoInc
	Variable NWaves = ItemsInList(WavesToInc)
	variable i,j=0, npnts, counter=0
	make/o/n=0 DelayList
//	if(Half != 0)
		for(j=0; j<NWaves;j+=1)
			sAuxWave =root+StringFromList(j, WavesToInc)
			Wave wAuxWave = $sAuxWave
			wavestats/q wAuxWave
			npnts = 20// V_npnts + V_numnans
			for(i=(FirstCycle-1);i<(LastCycle);i+=1)
				if(wAuxWave[i] >0)
					InsertPoints counter, 1, DelayList
					DelayList[counter] = wAuxWave[i]
					counter+=1
				endif
			endfor
		endfor
//	elseif(Half == 0)
//		for(j=0; j<NWaves;j+=1)
//			sAuxWave = root+StringFromList(j, WavesToInc)
//			Wave wAuxWave = $sAuxWave
//			wavestats/q wAuxWave
//			npnts = 20//V_npnts + V_numnans
//			for(i=0;i<npnts;i+=1)
//				if(wAuxWave[i] >0)
//					InsertPoints counter, 1, DelayList
//					DelayList[counter] = wAuxWave[i]
//					counter+=1
//				endif
//			endfor
//		endfor
//	endif
	edit delaylist
end

function sine1()
	variable i
	wave timewave, auxfitwave,vprotwave
	for(i=0;i<100;i+=1)
		timewave[(2*i)+22] = timewave[2]
		timewave[(i*2+1)+22] = timewave[3]
		AuxFitwave[(2*i)+22] = AuxFitwave[2]
		AuxFitwave[(2*i+1)+22] = AuxFitwave[3]
		vprotwave[(2*i)+22] = vprotwave[2]
		vprotwave[(2*i+1)+22] = vprotwave[3]
	endfor
end
function sine2()
	variable i
	String sWave1 = "SineProt_100Hz_n30mV"
	Make/o/n=(50000*.41) $sWave1
	Wave wWave1 = $sWave1
	setscale/p x,0,2e-5, wWave1
	wWave1 = -.07
	for(i=(.07644*50000);i<(50000*.12644);i+=1)
		wWave1[i] =-.05
	endfor
	for(i=(.12644*50000);i<(.32644*50000);i+=1)
		wWave1[i] = -.05+.02*cos(i*2*pi/500)
	endfor
end

Function OffsetBaselineDialog()
	variable FirstP=0, Npoints = 100, CloseWin = 1
	Prompt FirstP, "First point to consider for baseline?"
	Prompt NPoints, "Number of points at record onset to average for baseline?"
	Prompt CloseWin, "Close current window (1: yes, 0: no?)"
	DoPrompt "Baseline subtraction", FirstP, NPoints, CloseWin
	String cmd
	sprintf cmd, "OffsetBaseline(%g, %g, %g)", FirstP, NPoints, CloseWin
	Print cmd
	Execute cmd
End


Function OffsetBaseline(FirstP, NPoints, CloseWin)
	Variable FirstP, NPoints, CloseWin
	Variable i,j=0, baseline, SInterval 
	String AuxNameofWave
	Make/o/T/N=0 AuxNewNameofWaves
	Do
		wave Wavenam = waverefindexed("",i,1)
		if(WaveExists(Wavenam) == 0)
			break
		endif
	//	Wave wavenam = $sWavenam
		wavestats/q/r=[FirstP,(FirstP+NPoints)] wavenam
		baseline = V_avg
		AuxNameofWave = NameofWave(wavenam)+"dup"
		InsertPoints i,1, AuxNewNameofWaves
		AuxNewNameofWaves[i] = AuxNameofWave

		Duplicate/o wavenam, $AuxNameofWave
		Wave waux_dup = $AuxNameofWave
		
		SetScale/p x,0,(19.49e-6),""  Waux_dup
		
		waux_dup -= baseline
		
		i+=1
	while(1)
	if(CloseWin == 1)
		DoWindow/C ToBeDeleted
		DoWindow/K ToBeDeleted
	endif
	Display $AuxNewNameofWaves[0]
	for(j=1; j<i; j+=1)
		AppendtoGraph $AuxNewNameofWaves[j]
	endfor	
		
end

Function DialogLeakSPost()
	variable file
	Prompt file, "File to leaks subt"
	Doprompt "Post trace Leak Subtraction", file
	string cmd
	sprintf cmd, "LeakSPost(%g)", file
	print cmd
	Execute cmd
end

Function LeakSPost(file)
	Variable file
	Variable IHCAsk = 0
	UltimateLeakSubt(file, IHCAsk)
end

Function ExtractRaFromTrace(file, KillTraces)
	Variable file, KillTraces // KilllTraces =0: NO, KillTraces = 1: YES
	Variable IHCAsk = 0// if IHCAsk = 0 will leak subtract post files
	UltimateLeakSubt(file, IHCAsk)			//Leak subtracts post traces
	SVAR IndexCurrFileName
	string sweep = num2str(file)
	do
		sweep = "0" + sweep
	while(strlen(sweep)<4)
	variable i
	String sAux = IndexCurrFileName+"_"+sweep+"_*_1"
	String WavesToLeakS = WaveList(sAux, ";","")
	Variable Nsweeps = ItemsInList(WavesToLeakS)
	String sRa = "Ra_"+num2str(file)		//
	Make/o/n=(Nsweeps) $sRa			// Ra will collect Ra for each sweep in File
	Wave wRa = $sRa					//
	for(i=0;i<NSweeps;i+=1)
		sAux = IndexCurrFileName+"_"+sweep+"_"+num2str(i+1)+"_1LeakS"
		Wave wAux = $sAux
		WaveStats/Q/R=(.023,.025) wAux		//seeks for V_min in current transient at onset of step to -80mV
		wRa[i] = -1e12*(.01/V_min)			//
		if(KillTraces == 1)
			KillWaves $sAux
			sAux=IndexCurrFileName+"_"+sweep+"_"+num2str(i+1)+"_2"
			KillWaves $sAux
		endif
	endfor
end

Function RaCalcPostDialog()
	variable file
	Prompt file, "File to calculate Ra"
	Doprompt "Ra calculation", file
	string cmd
	sprintf cmd, "RaCalcPost(%g)", file
	print cmd
	Execute cmd
End

Function RaCalcPost(file)
	Variable file
	Variable i=0, j,k=0, LeakatStep, T1, T2, NPoints, basal, l
	Make/o/n=2 Vh = {-.07,-.06}
	Make/o/n=2 Ileak
	SVAR CurrentFileName
	NVAR SampleInterval
	Variable AcqRate = 1/(SampleInterval*1e-6)
	  String filecomp = num2str(file)
	  Do
	  	filecomp = "0"+filecomp
	  While(strlen(filecomp)<4)
	String sAuxParam = "SweepParams_" + FileComp 
	Wave/T wSweepParams = $sAuxParam
	Variable NSweeps1 = str2num(wSweepParams[35][1])
	String sTrace = CurrentFileName + "_2_1"
	String sTrace1
	if(WaveExists($sTrace) == 0)
		printf ""
		abort
	else
		WaveStats/q $sTrace
		NPoints = V_npnts
	endif
	String sAvg = "AvgTestPulse_"+num2str(file)
	Make/o/n=(NPoints) $sAvg
	Wave wAvg = $sAvg
	wAvg = 0
	variable NSweeps = 0
	do
//	for(i=1;i<(NSweeps+1);i+=1)
	   sTrace = CurrentFileName+"_" +num2str(i)+"_1"
	   k=0;l=0
	   if(WaveExists($sTrace) == 1)
		Wave wTrace = $sTrace
		Duplicate/O wTrace, wTrace_diff
		Smooth 1000, wTrace_diff
		differentiate wTrace_diff
		do
			if(wTrace_diff[k] > 100000)
				Wavestats/Q/r=[30,(k-50)] wTrace
				basal = V_avg
				l = k-20
				Do
					if(wTrace[l] > (2*V_rms+basal))
						T1 = l
						break
					endif
					l+=1
				while(1)
				break
			endif
			k+=1
		while(1)
		k+=200
		do
			if(wTrace_diff[k] < -100000)
				Wavestats/Q/R=[(k-20), (k-50)] wTrace
				l=k-20
				Do
					if(wTrace[l] < (V_avg-2*V_rms))
						T2 = l
						break
					endif
					l+=1
				while(1)
				break
			endif
			k+=1
		while(1)		
		WaveStats/q/r=[0,(T1-50)] wTrace
		Ileak[0] = V_avg
		WaveStats/q/r=[(T1+50),(T2-50)] wTrace
		Ileak[1] = V_Avg
		LeakAtStep = interp(-.07, Vh, Ileak)
		for(j=0;j<(T1);j+=1)
			wAvg[j] += wTrace[j] - LeakAtStep
		endfor
		for(j=(T2);j<(NPoints);j+=1)
			wAvg[j] += wTrace[j] - LeakAtStep
		endfor		
		LeakAtStep = interp(-.06, Vh, Ileak)
		for(j=(T1); j< (T2);j+=1)
			wAvg[j] += wTrace[j] - leakAtStep
		endfor
		KillWaves $sTrace
		if(stringmatch(wSweepParams[28][1], "2") == 1)
			sTrace1=CurrentFileName+"_"+num2str(i)+"_2"
			KillWaves $sTrace1
		endif
	   endif
	   i+=1
//	endfor
	While(i<NSweeps1)
	
	wAvg /= i
	SetScale/p x, 0, SampleInterval*1e-6, $sAvg
	WaveStats/q wAvg
	Variable Ra = 1e12*(.01/V_max)
	printf "Ra = %g Ohms", Ra
	display wAvg
	ModifyGraph rgb($sAvg)=(0,0,0)
	CurveFit/q dblexp_XOffset wAvg [V_maxloc*AcqRate, (T2-10)] /D
	variable tau = K2
	printf "\tTau1 = %g", tau
	Variable Cm = (tau/Ra)
	printf "\tCm =%g\r", Cm
end

Function SRComp (I_wave, Rs,Cm,fraction,Vh,Vrev)
	wave I_wave		//the data wave
	Variable Rs,Cm,fraction,Vh,Vrev
	Variable numpoints = numpnts(I_wave), sampInt = deltax(I_wave), i
	Duplicate/o I_Wave, Trace_corr
	Trace_corr *= 1e-12
	Variable Vi =0, Vmi =0, Vcorr = 0, Icap
	Vmi = Vh - Trace_corr[0]*Rs
	if(Vmi != Vrev)
		Vcorr = fraction*(1-(Vh-Vrev)/(Vmi - Vrev))
	else
		Vcorr = 0
	endif
	
	Trace_corr[0] = Trace_corr[0] - Trace_corr[0]*Vcorr
	for(i=1;i<numpoints;i+=1)
		Vi = (Vh - Trace_corr[i]*Rs)
		if(Vi != Vrev)
			Vcorr = fraction * (1- (Vh - Vrev)/(Vi - Vrev))
		else
			Vcorr = 0
		endif
		Icap = Cm*(Vi - Vmi)/sampInt
		ICap *= (1 - exp (-2*pi*sampInt*10000))
		Trace_corr[i-1]  -= fraction*ICap
		Trace_corr[i-1] -= Trace_corr[i-1] * Vcorr
		Vmi = Vi
	endfor
	Trace_corr /= 1e-12
end

Function EffAnaldialog()
	string file
	Prompt file, "dd"
	Doprompt "dgfada", file
	string cmd
	sprintf cmd, "EffAnalysis(%g)", file
	print cmd
	Execute cmd
end


Function EffAnalysis()
	//Indicar ventana de tiempo para buscar pico del IPSC (entre Win1 y Win2, en ms)
	//Indicar NoiseFactor: define umbral como X veces el RMS
	//
	NVAR SampleInterval
	variable j=0, FlagNewAnal=0, NTimeScale, AcqRate = (1e6/SampleInterval)
	Wave ParamWave// 1111111
	Variable file = ParamWave[0], Win1 = ParamWave[5], Win2 = ParamWave[6], NoiseFactor = ParamWave[4]//22222222222222
	Variable NStimuli = ParamWave[2], NSweeps = ParamWave[1], QeffF = ParamWave[7]
	Variable Period = 1/ParamWave[3]
	String sNFailures = "NFailures_"+num2str(file)
	Make/o/n=(NStimuli) $sNFailures
	Wave wNFailures = $sNFailures
	wNfailures = 0
	if(period == inf)
		Period = 0
	elseif(Win2 > Period)
		printf "Win2 debe ser menor que el periodo del tren"
		abort
	endif

	String FileComp = num2str(file)
	Do
		FileComp = "0"+FileComp
	While(strlen(FileComp)<4)
	Variable NewAnal = 1
	if(WaveExists(TimeScale) == 1)
		Wave TimeScale
		NTimeScale = DimSize(TimeScale,0)
		For(j=0;j<NTimeScale;j+=1)
			if(TimeScale[j][0] == file)
				Newanal = 0
			endif
		endfor
	endif
		
	String sSweepName
	SVAR IndexCurrFileName
	Variable flag, flag1, SweepEnd, i, PrevPerforThreshP1, PrevPerforThreshP2, threshold2, LocalPeak
	String sAmplitudeWave
	for(j=0;j<NStimuli;j+=1)
		sAmplitudeWave = "AmplitudeWave_"+num2str(file)+"_"+num2str(j+1)
		Make/o/n=(NSweeps) $sAmplitudeWave
	endfor
	Make/o/n=(Nsweeps) RMS =0

	Make/o/n=5160 SmoothSweep, DiffSweep////////////???????????????
	Variable baseline, threshold, sweepnumber = 0, Nfallas=0
	sSweepName = IndexCurrFileName +"_"+FileComp+ "_1_1"
	Wave SweepName = $sSweepName
	Wavestats/q SweepName
	Variable Npnts = V_npnts
	Do
		SweepEnd = 0
		i=0
		sSweepName = IndexCurrFileName +"_"+FileComp+ "_"+ num2str(SweepNumber+1) + "_1"
		Wave SweepName = $sSweepName
		Duplicate/o $sSweepName, SmoothSweep
//		Smooth 3, SmoothSweep							//12.11.12 Anulamos filtrado 
		Differentiate $sSweepName/D= DiffSweep
		wavestats/q/r=[0,80] SmoothSweep
		Baseline = V_avg
		SmoothSweep -= baseline
		Wavestats/q/r=[0,80] SmoothSweep
		threshold = -1*NoiseFactor*V_rms
//			smoothsweep = SweepName - baseline
//		Wavestats/q/r=[0,80] smoothsweep
		RMS[sweepnumber] = V_rms//J + baseline
		variable flagcorr, criteria = 0, localint
		Variable IntThresh = -.5*QeffF * (1 - (exp(-Period/0.026))
		Variable IntThresh2 = -.5*QeffF
		//Now, look for event in the smooth trace corresponding  to sweep "SweepNumber"
		Integrate SmoothSweep/D=SmoothSweep_int
		Do
			flagcorr = 0
			flag = DiffSweep[i]
			if(flag > 2e5)												//Detects artifact
				for(j=0;j<NStimuli;j+=1)/////////////////////////////////////////
					criteria = 0
					sAmplitudeWave = "AmplitudeWave_"+num2str(file)+"_"+num2str(j+1)
					Wave wAmplitudeWave = $sAmplitudeWave
					Wavestats/q/r=[(i+AcqRate*(j*Period+Win1)), (i+AcqRate*(j*Period+Win2))] SmoothSweep
					//12.11.12 Cambiamos manera de calcular Localpeak, agregandole promedio de los 2 puntos vecinos
					LocalPeak = .2*(V_min + SmoothSweep[V_minLoc*AcqRate - 1] + SmoothSweep[V_minLoc*AcqRate + 1] + SmoothSweep[V_minLoc*AcqRate - 2] + SmoothSweep[V_minLoc*AcqRate + 2])
//					LocalPeak=V_min										//Local Peak es pico del (supuesto) evento
					LocalInt = SmoothSweep_int[i + AcqRate*(j+1)*Period-5] - SmoothSweep_int[i + AcqRate*(j*period+win1)]
					if(LocalPeak < threshold)// && (LocalInt < -0.2))
						criteria = 1
					endif						
					if((criteria == 1))// && (j ==0))						//si LocalPeak es mayor al umbral en primera instancia. Luego 
																	//se hacen otras evaluaciones								
						if((flagcorr == 1))								//evaluo si el anterior estimulo en el tren, produjo un evento (o pares de pulses)
							PrevPerforThreshP1 = i + (AcqRate * Period * (j)) - 15			
							PrevPerforThreshP2 = i + (AcqRate * Period * (j)) - 5
							Wavestats/Q/R=[PrevPerforThreshP1, PrevPerforThreshP2] smoothSweep	//calcula threshold2 que es baseline antes del j-esimo estimulo
							threshold2 = V_avg					//
		//					LocalInt = LocalInt - SmoothSweep_int[i + AcqRate*(j*Period + win1)] 			//calcula la integral, menos lo que viene del evento anterior
							if((LocalPeak < (threshold + threshold2)) && (LocalInt < IntThresh))		//si Local Peak es mayor a la suma de los dos umbrales (threshold2 + threshold)
								wAmplitudeWave[sweepnumber] = LocalPeak - threshold2			//(threshold es = RMS * FactorUmbral)
								flagcorr = 1
							else																//falla
								wAmplitudeWave[sweepnumber] = 0
								wNFailures[j] += 1
								flagcorr=0
							endif
						elseif(j == (Nstimuli-1))											//si se trata de un estimulo solo o el ultimo en el tren
							LocalInt = SmoothSweep_int[i + AcqRate*.08] - SmoothSweep_int[i + AcqRate*(j*period+win1)]
							if(LocalInt < IntThresh2)										//el criterio por integral es mas riguroso, sobre la integral del evento entero
								wAmplitudeWave[sweepnumber] = LocalPeak
								flagcorr = 1
							else															//falla
								wAmplitudeWave[sweepnumber] = 0
								wNFailures[j] += 1
								flagcorr = 0
							endif
						else														//en caso de que no hay un evento en el estimulo anterior
		//					doupdate
							if(LocalInt < IntThresh)											//vuelve a evaluar por int ahora
								wAmplitudeWave[sweepnumber] = LocalPeak
								flagcorr = 1
							else															//falla
								wAmplitudeWave[sweepnumber] = 0
								wNFailures[j] += 1
								flagcorr = 0
							endif
						endif													//Termina evaluacion de posible evento
					else												//Si min local NO es 'menor' a umbral
						wAmplitudeWave[sweepnumber] = 0
						wNFailures[j] +=1
						flagcorr = 0
					endif
				endfor												//termina ciclo sobre los estimulos de un tren.
				SweepEnd = 1										//Flag to stop cycle that looks for artifact
				flagcorr = 0
			endif													//busqueda del artefacto
			i+=1
		While((i<NPnts) && (SweepEnd == 0))							//termina ciclo de busqueda del artefacto
		sweepnumber +=1
		//
	While(sweepnumber < NSweeps)									//termina ciclo sobre los sweeps de un file
	
	If(newanal == 1)
		EffAnalTimeScale()
	endif
	printf "File: %g, # Sweeps: %g, # Stimuli: %g, Period: %g, Threshold Factor: %g, Win1: %g, Q event factor: %g\r", file, Nsweeps, NStimuli, Period, NoiseFactor, Win1, QeffF
		
end

Function PrintResultsEffAnal()
	Wave ParamWave
	Variable NStimuli = ParamWave[1]
	variable file = ParamWave[0]
	Variable AmpPromMinis = ParamWave[8]
	string sNFailures = "NFailures_" + num2str(file)
	wave wNFailures = $sNFailures
	string sAmplitudeWave = "AmplitudeWave_"+num2str(file)+"_1"
	variable meanEvoAmp1=mean ($sAmplitudeWave)
	sAmplitudeWave = "AmplitudeWave_"+num2str(file)+"_2"
	variable meanEvoAmp2=mean ($sAmplitudeWave)
	variable pFailures1=wNFailures[0]
	variable pFailures2=wNFailures[1]
	
	printf "File: %g\r", file
	printf "Amp Prom MInis: %g\r", AmpPromMinis
	printf "Num Fallas S1: %g\r", pFailures1
	printf "Amp Prom S1: %g\r", meanEvoAmp1
	printf "CC Directo: %g\r", meanEvoAmp1/AmpPromMinis
	printf "CC Fallas: %g\r", ln(NStimuli/pFailures1)
	printf "Num Fallas: %g\r", pFailures2
	printf "Amp Prom S2: %g\r", meanEvoAmp2
	printf "Amplitud sin fallas: %g\r", meanEvoAmp2/meanEvoAmp1
	printf "S2/S1 con fallas: %g\r", meanEvoAmp2/meanEvoAmp1

	sAmplitudeWave = "AmplitudeWave_"+num2str(file)+"_1"
	wavestats/q $sAmplitudeWave
	variable NumFallas=wNFailures[0]
	printf "Amplitud sin fallas: %g\r", V_sum/(NStimuli-NumFallas)
end


Function EffAnalTimeScale()
//	Variable NewAnal
	Wave ParamWave// 1111111
	Variable file = ParamWave[0], Win1 = ParamWave[5], Win2 = ParamWave[6], NoiseFactor = ParamWave[4]
	Variable NStimuli = ParamWave[2], NSweeps = ParamWave[1]
	Variable Period = 1/ParamWave[3]
	Variable flag0, j
	
	String aux2, aux = num2str(file)
	Do
		aux = "0"+aux
	while(strlen(aux)<4)
	
	
	//String sSweepParams = "SweepParams_"+aux
	//Wave/t wSweepParams = $sSweepParams
	//aux2 = wSweepParams[7][1]
	
	
	//TimeScale is a 2D wave. First column: analized file names
	//						Second column: Absolute Time as taken from SweepParams wave
	if(WaveExists(TimeScale) == 0)
		Make/o/n=(1,2) TimeScale
		TimeScale[0][1] = str2num(aux2)
		TimeScale[0][0] = file
	else
		Wave TimeScale
		flag0 = DimSize(TimeScale,0)
		InsertPoints flag0,1, TimeScale
		TimeScale[flag0][1] = str2num(aux2)
		TimeScale[flag0][0] = file
	endif
	variable p
	flag0 = DimSize(TimeScale,0)
	Make/O/n=(flag0) TimeScale1				//TimeScale1 collects SORTED time points taken from TimeScale[][1]
	Make/O/N=(flag0*100) TimeScale2			//TimeScale2 collects time points for EACH stimulation, calculated from TimeScale1
	for(p=0 ;p < (flag0); p+=1)
		TimeScale1[p] = TimeScale[p][1]
	endfor	
	sort TimeScale1, TimeScale1
	variable k,l, b
	b= TimeScale1[0]						//b will be the first time point in ABSOLUTE VALUES as taken from SweepParams
	TimeScale1 -= b
	for(k=0;k<flag0;k+=1)
		for(l=0;l<100;l+=1)
			TimeScale2[k*100+l] = TimeScale1[k] + l
		endfor
	endfor
	
	
/////////////////////////////////////////
		variable pointofinser
		Variable TimingofFile = str2num(aux2) - b		//TimingofFile will have
		k=0
		Do
			if(TimingofFile == TimeScale1[k])
				PointofInser = k
				break
			endif
			k+=1
		While(k<flag0)
		String sEnsembleAmpWave, sAmplitudeWave
		if(PointofInser == 0)
			for(j=0;j<NStimuli;j+=1)
				sEnsembleAmpWave = "EnsembleAmpWave_"+num2str(j+1)
				Make/O/N=(0) $sEnsembleAmpWave
			endfor
		endif
		for(j=0;j<NStimuli;j+=1)
			sEnsembleAmpWave = "EnsembleAmpWave_"+num2str(j+1)
			sAmplitudeWave = "AmplitudeWave_"+num2str(file)+"_"+num2str(j+1)
			Wave wEnsembleAmpWave = $sEnsembleAmpWave
			Wave wAmplitudeWave = $sAmplitudeWave
			InsertPoints (PointofInser*NSweeps), NSweeps, $sEnsembleAmpWave
			for(l=0;l<100;l+=1)
				wEnsembleAmpWave[l+PointofInser*NSweeps] = wAmplitudeWave[l]
			endfor
		endfor
end


Function EffAnalysisTrain()
	//Indicar ventana de tiempo para buscar pico del IPSC (entre Win1 y Win2, en ms)
	//Indicar NoiseFactor: define umbral como X veces el RMS
	//
	//5.6.13 JG: Cambie i) umbral de deteccion de artefacto de estimulacion, ii) el valor atribuido a 'period'
	//cuando hay un estimulo unico
	//28.6.13 JG: Agregue analisis de eventos eferentes 'positivos' es decir evocados con Vh > Erev K+
	//Como por ej a -40mV. Para esto, adapte analisis, de manera que ahora los eventos son positivos siempre
	//(incluso cuando Vh = -90mV) y la rutina busca maximos, NO minimos.
	//Ademas, hay un subrutina para calcular parametros cineticos, fundamentalmente, para eventos positivos.
	//Calcula, halfwidth, y ajusta la integral de un evento a una exponencial y da el tau. Ademas, se informa 
	//la carga generada por un evento.
	//26feb2015 jg: cambie el Eff_HWandTauCalc para que calcule el decay de la corriente sinaptica y tambien de la integral
	//7dic2018_juan
	//SampleInterval sale del DimDelta de SmoothSweep
	//12dic2018: Eliminamos win2 que no tiene sentido.
	
	variable j=0, FlagNewAnal=0, NTimeScale
	Wave ParamWave// 1111111
	Variable file = ParamWave[0], Win1 = ParamWave[5], NoiseFactor = ParamWave[4], LatencyAnal = ParamWave[13]
	Variable NStimuli = ParamWave[2], NSweeps = ParamWave[1], QeffF = ParamWave[7], KineticAnalFlag = ParamWave[11], ArtifTime = ParamWave[12]
	Variable Period = 1/ParamWave[3]
		//Adjusting for complete name of 'file number', with 4 digits
	String FileComp = num2str(file)
	Do
		FileComp = "0"+FileComp
	While(strlen(FileComp)<4)
//	String sSweepParams = "SweepParams_"+FileComp; Wave/T wSweepParams = $sSweepParams
//	Variable SampleInterval = str2num(wSweepParams[29][1])
	Variable BaselineT1 = 0.200, BaselineT2 = 0.290, Latency
	
	if(BaselineT2 >= ARtifTime)
		print "El tiempo para calcular baseline tiene que ser anterior al artefacto"
		abort
	endif
	String sNFailures = "NFailures_"+num2str(file)
	Make/o/n=(NStimuli) $sNFailures
	Wave wNFailures = $sNFailures
	wNfailures = 0
	String sSweepName
	SVAR CurrentFileName
	Variable  SweepEnd, i, PrevPerforThreshP1, PrevPerforThreshP2, threshold2, LocalPeak, ArtifDetP = 2e6, flag
//	Variable flag, flag1
	String sAmplitudeWave, sCumAmpWave
	for(j=0;j<NStimuli;j+=1)
		sAmplitudeWave = "AmplitudeWave_"+num2str(file)+"_"+num2str(j+1)
		Make/o/n=(NSweeps) $sAmplitudeWave
		Wave wAmplitudeWave = $sAmplitudeWave
		wAmplitudeWave = 0
		if(LatencyAnal == 1)
			String sLatencyWave = "LatencyWave_"+num2str(file)+"_"+num2str(j+1)
			Make/o/n=(NSweeps) $sLatencyWave
			Wave wLatencyWave = $sLatencyWave
			wLatencyWave = nan
		endif
	endfor
//	Make/o/n=(Nsweeps) RMS = 0//, QWave = 0, HWWave = 0, TauQWave = 0
	Variable baseline, threshold, sweepnumber = 0
	//FlagWave will have 1 or 0 in each row indicating if a given stimulus produced a success or failure, respectively
	Make/O/N=(NStimuli) FlagWave
	//Period is 1/freq in template, but should be corrected in case freq = 0
	if((period == inf) || (NStimuli == 1))		//5.6.13 agregue la posibilidad de NStimuli ==1
		if(QeffF < 0)
			Period = 3*.026					//5.6.13 Cambie de Period = 0 a Period = 3*0.026
		elseif(QeffF > 0)
			Period = 3* .06
		endif
//	elseif(Win2 > Period)//		error message
//		printf "Win2 debe ser menor que el periodo del tren\r"
//		abort
	endif
	//
	//The following is to trigger (or not) the Time Scale Function that will construct the ensemble time scale
//	Variable NewAnal = 1
//	if(WaveExists(TimeScale) == 1)
//		Wave TimeScale
//		NTimeScale = DimSize(TimeScale,0)
//		For(j=0;j<NTimeScale;j+=1)
//			if(TimeScale[j][0] == file)
//				Newanal = 0
//			endif
//		endfor
//	endif
	//
	sSweepName = CurrentFileName[0,7]+"_"+Filecomp + "_1_1"
	Wave SweepName = $sSweepName
	Variable SampleInterval = DimDelta($sSweepName,0)
	Variable AcqRate = (1/SampleInterval)
	Wavestats/q SweepName
	Variable Npnts = V_npnts
	Make/o/n=(Npnts) SmoothSweep, DiffSweep////////////???????????????
	If(KineticAnalFlag == 1)
		String sTauDecay = "TauDecay_"+num2str(file)
		String sHWWave = "HWWave_"+num2str(file)
		String sQWave = "QWave_"+num2str(file)
		String sTauQWave = "TauQWave_"+num2str(file)
		Make/O/n=(NSweeps) $sTauDecay, $sTauQWave, $sHWWave, $sQWave
		Wave TauDecay =  $sTauDecay
		Wave HWWave = $sHWWave
		Wave QWave = $sQWave
		wave TauQWave =$sTauQWave
		TauDecay = nan
		TauQWave = nan
		HWWave = nan
		QWave = nan
	endif
	Do																	///// Cycle on sweepnumber
		SweepEnd = 0
		i=ArtifTime * AcqRate
		sSweepName = CurrentFileName[0,7] + "_" +FileComp+"_"+ num2str(SweepNumber+1) + "_1"
		Wave SweepName = $sSweepName
		Duplicate/o $sSweepName, SmoothSweep
//		Smooth 3, SmoothSweep							//12.11.12 Anulamos filtrado 
		Differentiate $sSweepName/D= DiffSweep
		
		Variable BaselFinder = 0 
		Do
			Wavestats/q/r=[((BaselineT1+BaselFinder/10)*AcqRate),((BaselineT2+BaselFinder/10)*AcqRate)] SmoothSweep
			if((V_sdev > 10) && (BaselFinder == 10))
				print "Chequear donde calcular baseline"
				abort
			else
				Baseline = V_avg
				SmoothSweep -= baseline
				threshold = NoiseFactor*V_sdev					//25.6.13 cambio
				break
			endif
			BaselFinder +=1
		While((BaselFinder/10)<1)
		
//		RMS[sweepnumber] = threshold//V_rms//J + baseline
		variable flagcorr, criteria = 0, localint, qcarry, q
		Variable IntThresh, IntThresh2 = QeffF
		if(QeffF < 0)										//25.6.13 cambio
			IntThresh = abs(QeffF * (1 - (exp(-Period/0.026))))	//Si el QeffF es < 0, es decir el Vh = -90
			SmoothSweep *= (-1)							//los eventos son mas rapidos.
														//ADEMAS!! hace que el eventos se POSITIVO
		elseif(QeffF > 0)
			IntThresh = QeffF * (1-(exp(-Period/0.060)))		//Si es >0, es decir el Vh = -40, la fase positivoa
		endif											//de cada evento es mas lenta
		Integrate SmoothSweep/D=SmoothSweep_int		
		//Now, look for event in the smooth trace corresponding  to sweep #"SweepNumber"
		Do															//// Cycles over point number in recording 'i'.
			
			//flagcorr = 0
			flag = DiffSweep[i]										//i cuenta puntos en el trazo y busca artefacto!
//			Wavestats/q/r=((i-win1*.5*AcqRate),(i+win1*.5*AcqRate)) DiffSweep
//			flag1 = V_min
			if(ArtifTime > 0)
				ArtifDetP = 1
			endif
			FlagWave = 0
			if((flag > ArtifDetP))// && (flag1 < (-1*ArtifDetP)))					//Detects artifact. 5.6.13, cambio de 2e5 a 2e6
				for(j=0;j<NStimuli;j+=1)								//cicla sobre numero de estimulos del tren
					QCarry = 0
					sLatencyWave = "LatencyWave_"+num2str(file)+"_"+num2str(j+1)
					Wave wLatencyWave = $sLatencyWave
					sAmplitudeWave = "AmplitudeWave_"+num2str(file)+"_"+num2str(j+1)
					Wave wAmplitudeWave = $sAmplitudeWave
					Wavestats/q/r=[(i+AcqRate*(j*Period+Win1)), (i+AcqRate*(j+1)*Period)] SmoothSweep
					//12.11.12 Cambiamos manera de calcular Localpeak, agregandole promedio de los 2 puntos vecinos
					//25.6.13 Ahora busca maximo, porque SmoothSweep tiene los eventos positivos ahora
					LocalPeak = (mean(SmoothSweep, (V_maxLoc - 2/AcqRate), (V_maxLoc + 2/AcqRate)))
					LocalInt = (SmoothSweep_int[i + AcqRate*(j+1)*Period-5] - SmoothSweep_int[i + AcqRate*(j*period+win1)])
					Latency = V_maxLoc - (i/AcqRate+(j*Period))
					//El proximo if - else largoooo, para determinar si LocalPeak, es decir, la amplitud del evento
					//Y tambien LocalInt, la Q del eventos, son mayores que un dado umbral.
					if(LocalPeak > threshold)		//si LocalPeak, es decir la amplitud del evento, es mayor al umbral en primera instancia. 
						for(q=0;q<j;q+=1)			//Calcula Qcarry que determina cuanta Q del evento anterior influye en la determinacion
							if(QeffF < 0)
								QCarry += FlagWave[q] * QeffF  * exp(((j-q) * (-period))/.026)
							elseif(QeffF > 0)
								QCarry += FlagWave[q] * QeffF  * exp(((j-q) * (-period))/.060)
							endif
						endfor
																			
						if(j == 0)												//En caso de 1 estim o el primero de un tren
							if((LocalPeak > threshold) && (LocalInt > IntThresh))	//Determinacion ahora por criterio de integral
								wAmplitudeWave[sweepnumber] = LocalPeak
								FlagWave[j] = 1
								//
								if(LatencyAnal ==1)
									wLatencyWave[sweepnumber] = Latency
								endif
								//
								if(KineticAnalFlag == 1)						//Opcion para analisis cinetico de eventos
									QWave[sweepnumber] = LocalInt			//esto es nuevo, 25.6.13
									Eff_HWandTauCalc(SmoothSweep, SmoothSweep_int, SweepNumber, i, V_maxLoc, LocalPeak, file, QeffF)
								endif
							else												//Si cumple TAMBIEN con criterio de la Q del evento
								wAmplitudeWave[sweepnumber] = 0			//=>> FALLA!
								wNFailures[j] += 1
								if(LatencyAnal ==1)
									wLatencyWave[sweepnumber] = nan
								endif
							endif
						else										//En caso de que NO sea evento unico o el primero de tren
																//calcula primero threshold2 que es baseline antes del j-esimo estimulo
							PrevPerforThreshP1 = i + (AcqRate * Period * (j)) - AcqRate*.0003
							PrevPerforThreshP2 = i + (AcqRate * Period * (j)) - AcqRate*.0001
							Wavestats/Q/R=[PrevPerforThreshP1, PrevPerforThreshP2] SmoothSweep
							threshold2 = abs(V_avg)
							if((LocalPeak > (threshold + threshold2)) && (LocalInt > (IntThresh + QCarry)))	//25.6.13 cambio
												//si Local Peak es mayor a la suma de los dos umbrales (threshold2 + threshold)
												//y la integral es mayor al umbral + el 'carry-over' de los eventos anteriores
								wAmplitudeWave[sweepnumber] = LocalPeak - threshold2			//(threshold es = RMS * FactorUmbral)
								FlagWave[j] = 1
								if(LatencyAnal ==1)
									wLatencyWave[sweepnumber] = Latency
								endif
							else																//falla
								wAmplitudeWave[sweepnumber] = 0
								wNFailures[j] += 1
								FlagWave[j] = 0
								if(LatencyAnal ==1)
									wLatencyWave[sweepnumber] = nan
								endif
							endif
						endif
					else
						wAmplitudeWave[sweepnumber] = 0
						wNFailures[j] +=1
						FlagWave[j] = 0
					endif
				endfor
				SweepEnd = 1										//Flag to stop cycle that looks for artifact
//				flagcorr = 0
			endif
			i+=1
		While((i<NPnts) && (SweepEnd == 0))							//ciclo de busqueda del artefacto
		sweepnumber +=1
		if(i == NPnts)									//agregado 3.7.13
			printf "Llega al final del sweep y no encuentra artefacto\r"
		endif
		//
	While(sweepnumber < NSweeps)									//ciclo sobre sweeps
	
//	If(newanal == 1)
//		EffAnalTimeScale()
//	endif
	sAmplitudeWave = "AmplitudeWave_"+num2str(file)+"_1"
	wavestats/q $sAmplitudeWave
	variable reporteamp = V_avg
	printf "File: %g, Amp Prom: %g\r", file, reporteamp
	printf "# Sweeps: %g, # Stimuli: %g, Period: %gThreshold Factor: %g, Win1: %g, Q event factor: %g\r", Nsweeps, NStimuli, Period, NoiseFactor, Win1, QeffF
end

Function Eff_HWandTauCalc(SmoothSweep, SmoothSweep_Int, SweepNumber, i, ImaxLoc, Imax, file, QeffF)
//26feb2015_Juan
//en algun momento cambie el macro de modo que ajustaba el decay de la corriente sinaptica. Y no la integral
//recupere hoy el ajuste de la integral tambien. De modo que hace dos ajustes ahora.
//7dic2018_juan
//SampleInterval sale del DimDelta de SmoothSweep
	Wave SmoothSweep, SmoothSweep_Int
	Variable SweepNumber, i, ImaxLoc, Imax, file, QeffF
	Variable SampleInterval = DimDelta(SmoothSweep, 0)
	Variable AcqRate = (1/SampleInterval)
	Wave ParamWave, TauQWave, HWWave
	String sTauWave = "TauDecay_" +num2str(file)
	String sHWWave = "HWWave_" + num2str(file)
	String sTauQWave = "TauQWave_" +num2str(file)
	Wave HWWave = $sHWWave
	Wave TauWave = $sTauWave
	Wave TauQWave = $sTauQWave
	Variable win1 = ParamWave[5], T1, T2, ok = 1
	Duplicate/O smoothSweep, SmoothSweep2
//	Duplicate/O smoothSweep_int, SmoothSweep2_int
	Smooth 100, SmoothSweep2
//	if(ParamWave[7] < 0)
//		SmoothSweep2 *= (-1)
//		SmoothSweep2_int *= (-1)
//	endif
	DoWindow/F Graph2
	FindLevel/Q/EDGE=1/R=(((i/AcqRate)+win1), ImaxLoc) SmoothSweep2, (Imax/2)
	if(V_flag == 0)
		T1 = V_LevelX
	elseif(V_flag == 1)
		T1 = win1 + i/AcqRate
	endif
	FindLevel/Q/EDGE=2/R=(ImaxLoc, .35) SmoothSweep2, (Imax/2)
	if(V_flag == 0)
		T2 = V_LevelX
	endif	
	//fiteo de la integral primero
	curvefit/q exp_xoffset SmoothSweep_int [AcqRate*(t1),AcqRate*(T2*2)] /D
	TauQWave[sweepnumber] = K2
	// fiteo de la caida del evento
	WaveStats/Q/R=(T1, 3*T2) SmoothSweep/////////////////.   ,<<<<===chequear!!!
	CurveFit/Q exp_Xoffset SmoothSweep2 [((V_maxLoc+.001)*AcqRate), (AcqRate*3*T2)] /D
	
	Cursor/P/W=graph2 A ,SmoothSweep, ((V_maxLoc+.001)*AcqRate)
	Cursor/P/W=graph2 B ,SmoothSweep, T2*3*AcqRate
	Cursor/P/W=graph2 C ,SmoothSweep_Int,  T1*AcqRate
	Cursor/P/W=graph2 D ,SmoothSweep_Int,  AcqRate*(T2*2)
	SetAxis int -.2, (.2+SmoothSweep_int[AcqRate*(T2*2)])
	if(Imax > 0)
		SetAxis left -10, (Imax+20)
	else
		SetAxis left Imax, 10
	endif
	SetAxis bottom .0, .25
	textbox/k/n=text0
	TextBox/n=text0 "Sweep #: "+num2str(sweepnumber+1)
	doupdate
	Prompt ok, "OK (0: NO; 1: OK)"
	DoPrompt "Kinetic analysis on events", OK	
	if(ok ==1)
		HWWave[SweepNumber] = T2 - T1
		TauWave[SweepNumber] = K2
	elseif( ok == 99)
		abort
	else
		TauQWave[sweepnumber] = nan
	endif
End



///////////////////////////////////////////////////////////////////////////////////////////////

Function IntegrarTrenes()
	Wave ParamWave
	SVAR IndexCurrFileName
	Variable i=0, j=0, TimeArtif = ParamWave[12], Win1 = ParamWave[5], NEstim = ParamWave[2]
	Variable file = ParamWave[0], Freq = ParamWave[3], NSweeps = ParamWave[1]
	Make/O/n=(NSweeps) SweepExitosos
	String sTrace, sTraceInt, sTrace2, sAmplitudeWave
	String FileComp = num2str(file)
	do
		FileComp = "0"+FileComp
	While(StrLen(FileComp)<4)
	String sSweepParams = "SweepParams_"+FileComp; Wave/T wSweepParams = $sSweepParams
	Variable SampleInterval =(19.49)
	Variable AcqRAte = 1e6/SampleInterval
	for(i=0;i<NSweeps;i+=1)
		for(j=0;j<NEstim;j+=1)
			sAmplitudeWave = "AmplitudeWave_"+num2str(file)+"_"+num2str(j+1)
			Wave wAmplitudeWave = $sAmplitudeWave
			if(wAmplitudeWave[i] > 0)
				SweepExitosos[i] = 1			///Crea el wave SweepExitosos donde senhala cuales sweeps tuvieron exitos
			endif							// esto lo utiliza para integrar SOLO aquellos trazos
		endfor								// y evita integrar trazos que pueden distorsionar el resultado
	endfor
	
//Ahora grafica los sweeps exitosos (los trazos de I) para hacer el 'offsetBaseline'
	Variable flagG = 0
	for(i=0;i<NSweeps;i+=1)				
		sTrace = IndexCurrFileName + "_" + FileComp + "_" + num2str(i+1) + "_1"
		if((flagG==0) && (SweepExitosos[i] > 0))
			display $sTrace
			flagG = 1
		elseif((SweepExitosos[i] > 0))
			Appendtograph $sTrace
		endif
	endfor
	OffsetBaselineDialog()
	String UsedWindow = WinName(0,1)
//
//Ahora recorre los trazos dup (offset) y les hace 'removeartifactzero' y los integra
	for(i=0;i<Nsweeps;i+=1)
		sTrace =  IndexCurrFileName + "_" + FileComp + "_" + num2str(i+1) + "_1dup"
		Wave wTrace = $sTrace
		if(sweepexitosos[i] > 0)
		
			for(j=0;j<NEstim;j+=1)
				Cursor A, $sTrace, (TimeArtif + j/Freq)
				Cursor B, $sTrace, (TimeArtif + j/Freq + Win1)
				doupdate
				RemoveArtifact_Fill()
				//RemoveArtifactZero()
			endfor
						
			
			sTrace = NameofWave(wTrace)
			sTraceInt = sTrace + "_INT"
			Integrate wTrace /D=$sTraceInt
		endif
	endfor
//
//Borra los trazos '_dup', es decir, los que aplica el offset baseline
	DoWindow/K $UsedWindow
	for(i=0;i<Nsweeps;i+=1)
		sTrace =  IndexCurrFileName + "_" + FileComp + "_" + num2str(i+1) + "_1dup"
		if(sweepexitosos[i] > 0)
		//	KillWaves $sTrace
		endif
	endfor
//	
//Ahora grafica las integrales para correr el 'AverageWaves'
	flagG = 0
	for(i=0;i<Nsweeps;i+=1)
		sTrace =  IndexCurrFileName + "_" + FileComp + "_" + num2str(i+1) + "_1dup_INT"
		if((flagG==0) && (SweepExitosos[i] > 0))
			Display/N=IntGraph $sTrace
			flagG = 1
		elseif((SweepExitosos[i] > 0))
			Appendtograph $sTrace
		endif
	endfor
	Doupdate
	String cmd
	sprintf cmd, "AverageWaves(\"%s\")", S_name
	print cmd
	execute cmd
	i=0
	j=0
//
//Ahora grafica el promedio y muestra resultado
	Do
		Wave wAvgQTrace = WaveRefIndexed("", i,1)
		sTrace = NameofWave(wAvgQTrace)
		if(StringMatch(sTrace, "*Avg*") == 1)
			ModifyGraph rgb($sTrace)=(0,0,0)
			ModifyGraph lsize($sTrace)=2
			SetAxis left -0.5,(Nestim*.5)
			SetAxis bottom (TimeArtif-.005),(.01+Nestim/freq)
			SetScale/p x,0, (SampleInterval*1e-6), $sTrace
			String sAvgQ = "AvgQ_" + num2str(file)
			Make/O/N=(NEstim) $sAvgQ
			Wave wAvgQ = $sAvgQ
			for(j=0;j<NEstim;j+=1)
				wAvgQ[j] = wAvgQTrace[((j+1)/Freq + TimeArtif-.0005)*AcqRate]
			endfor
			edit $sAvgQ
			break
		endif
		i+=1
	While(1)
	KillWaves SweepExitosos	
end


Function EffAnalysisCum()

	NVAR SampleInterval
	variable j=0, FlagNewAnal=0, NTimeScale, AcqRate = (1e6/SampleInterval)
	Wave ParamWave
	Variable file = ParamWave[0], Win1 = ParamWave[5], Win2 = ParamWave[6], NoiseFactor = ParamWave[4]
	Variable NStimuli = ParamWave[2], NSweeps = ParamWave[1], QeffF = ParamWave[7], KineticAnalFlag = ParamWave[11], ArtifTime = ParamWave[12]
	Variable Period = 1/ParamWave[3]

	String sSweepName
	SVAR IndexCurrFileName
	Variable flag, flag1, SweepEnd, i, LocalPeak, ArtifDetP = 2e6
	String sCumAmpWave
	for(j=0;j<NStimuli;j+=1)
		sCumAmpWave = "CumAmpWave_"+num2str(file)+"_"+num2str(j+1)
		Make/o/n=(NSweeps) $sCumAmpWave
		Wave wCumAmpWave = $sCumAmpWave
		wCumAmpWave = 0
	endfor
	Variable baseline, threshold, sweepnumber = 0
	//Period is 1/freq in template, but should be corrected in case freq = 0
	if((period == inf) || (NStimuli == 1))		//5.6.13 agregue la posibilidad de NStimuli ==1
		if(QeffF < 0)
			Period = 3*.026					//5.6.13 Cambie de Period = 0 a Period = 3*0.026
		elseif(QeffF > 0)
			Period = 3* .06
		endif
	elseif(Win2 > Period)//		error message
		printf "Win2 debe ser menor que el periodo del tren\r"
		abort
	endif
	//Adjusting for complete name of 'file number', with 4 digits
	String FileComp = num2str(file)
	Do
		FileComp = "0"+FileComp
	While(strlen(FileComp)<4)
	//

	sSweepName = IndexCurrFileName+"_"+Filecomp + "_1_1"
	Wave SweepName = $sSweepName
	Wavestats/q SweepName
	Variable Npnts = V_npnts
	Do																	///// Cycle on sweepnumber
		SweepEnd = 0
		i=ArtifTime * AcqRate
		sSweepName = IndexCurrFileName + "_" +FileComp+"_"+ num2str(SweepNumber+1) + "_1"
		Wave SweepName = $sSweepName
		Duplicate/o $sSweepName, SmoothSweep
		//Smooth 3, SmoothSweep							//12.11.12 Anulamos filtrado // 7.8.15 Marcelo - Reestablezco filtrado
		Differentiate $sSweepName/D= DiffSweep
		wavestats/q/r=[(.355*AcqRate),(.395*AcqRate)] SmoothSweep   // 7.8.15 Marcelo - Cambio Rango (de 0-0.1 a  0.05-0.08)
		Baseline = V_avg
		SmoothSweep -= baseline
		Wavestats/q/r=[(.355*AcqRate),(.395*AcqRate)] SmoothSweep   // 7.8.15 Marcelo - Cambio Rango (de 0-0.1 a  0.05-0.08)
		threshold = NoiseFactor*V_rms					//25.6.13 cambio

		if(QeffF < 0)										//25.6.13 cambio
			SmoothSweep *= (-1)							//los eventos son mas rapidos.
		endif											
		Integrate SmoothSweep/D=SmoothSweep_int		
		//Now, look for event in the smooth trace corresponding  to sweep #"SweepNumber"
		Do															//// Cycles over point number in recording 'i'.

			flag = DiffSweep[i]										//i cuenta puntos en el trazo y busca artefacto!
			Wavestats/q/r=((i-win1*.5*AcqRate),(i+win1*.5*AcqRate)) DiffSweep
			if(ArtifTime > 0)
				ArtifDetP = 1
			endif
			if((flag > ArtifDetP))// && (flag1 < (-1*ArtifDetP)))					//Detects artifact. 5.6.13, cambio de 2e5 a 2e6
				for(j=0;j<NStimuli;j+=1)								//cicla sobre numero de estimulos del tren

					Wavestats/q/r=[(i+AcqRate*(j*Period+Win1)), (i+AcqRate*(j*Period+Win2))] SmoothSweep
					//12.11.12 Cambiamos manera de calcular Localpeak, agregandole promedio de los 2 puntos vecinos
					//25.6.13 Ahora busca maximo, porque SmoothSweep tiene los eventos positivos ahora
					LocalPeak = (mean(SmoothSweep, (V_maxLoc - 2/AcqRate), (V_maxLoc + 2/AcqRate)))
					sCumAmpWave = "CumAmpWave_"+num2str(file)+"_"+num2str(j+1)
					Wave wCumAmpWave = $sCumAmpWave
					wCumAmpWave[sweepnumber] = LocalPeak
				endfor												//Fin ciclo sobre numero de estimulos en un tren
				SweepEnd = 1										//Flag to stop cycle that looks for artifact
//				flagcorr = 0
			endif
			i+=1
		While((i<NPnts) && (SweepEnd == 0))							//ciclo de busqueda del artefacto
		sweepnumber +=1
		if(i == NPnts)									//agregado 3.7.13
			printf "Llega al final del sweep y no encuentra artefacto\r"
		endif
		//
	While(sweepnumber < NSweeps)									//ciclo sobre sweeps
	
end



Function MiniAnalDeconv()
	//2jan2012
	//This macro is based on the method exposed by (?) Jonas 2012, in which they show
	//that deconvolving the recording trace with a Mini template, one has a very good method
	//with high signal to noise ratio to detect events.
	//25feb2012
	//Added couple of things: i) new traces window with full trace view. ii) new options in control window + switch-case command.
	//(now it is possible to make big jumps, abort)
	//Below are settings.
	DoWindow/F Graph10_1
	DoWindow/F Graph10
	Variable i, j, flag = 0, threshold, flag2, qmini, ok, MinLocCurr, TimePreEvent = .015, BaselPeriod = .001, BaselinePreEvent, MinLocCurrT, AvgAmp
	Variable WinJumpP = 200
	Wave AvgMini								//This is Mini template for deconv
	SVAR IndexCurrFileName						//This is the index of the file name (e.g. JG12n23A)
	NVAR SampleInterval							//SampleInterval is a global variable (units: microsec)
	Wave ParamWave
	variable file = ParamWave[0], AnalInitT =ParamWave[9], MiniDeconvThresh = ParamWave[10], FactorUmbral = ParamWave[4]
	string filecomp = num2str(file)
	do
		filecomp = "0"+ filecomp
	while(strlen(filecomp) < 4)
	String sSweepParams = "SweepParams_" + filecomp			//This is the wave where recording file
	Wave/t wSweepParams = $sSweepParams					//data is stored
	if(WaveExists(wSweepParams) == 0)
		print "error in name"
		abort
	endif
	string snsweeps = wSweepParams[5][1]
	variable NSweeps = str2num(snsweeps)				//Number of sweeps in file
	String sNpoints1 =wSweepParams[3][1]
	variable NPoints = str2num(sNpoints1) / NSweeps
	String sMiniAmp = "MiniAmp_"+num2str(file)			//This is the wave where amplitude of events will be stored (1 per file)
	String sMiniTime = "MiniTime_"+num2str(file)		//this is the one where the timing of events will be stored
	String sDecayTau = "DecayTauMinis_"+num2str(file)
	String sRiseTime = "RiseTimeMinis_"+num2str(file)
	Make/o/n=0 $sMiniamp, MiniIndexTemp, $sMiniTime, $sDecayTau, $sRiseTime
	Wave wminiAmp = $sMiniAmp
	Wave wMiniTime = $sMiniTime
	Variable AcqRate = 1e6/SampleInterval			
	////////////////////////////////////////////////////////////////////////////////
	variable TraceSponQ = 0
	Prompt TraceSponQ, "Delete selected spontaneous events traces? (0: No, 1: Yes)"
	DoPrompt "Spont events analysis", TraceSponQ
	
	////////////////////////////////////////////Now the calculation starts//////////////////////////
	for(i=0; i<(NSweeps); i+=1)
		String sTrace = IndexCurrFileName + "_" + FileComp+"_"+num2str(i+1)+"_1"
		wave wTrace = $sTrace
			//Now, AvgMini 's length comparison with recording trace
			//it is important for good deconv results, that both have the same length
			Do
				WaveStats/q AvgMini
				if(V_npnts < NPoints)
					InsertPoints V_npnts, 1, AvgMini
					AvgMini[V_npnts+1] = 0
				elseif(V_npnts > NPoints)
					DeletePoints (V_npnts-1), 1, AvgMini
				else
					break
				endif
			While(1)
			//
		Duplicate/o wTrace, w_smooth				//Recording trace is duplicated into W_Smooth
		Duplicate/o wTrace, wTrace2				//and again for calculation
		Smooth 60, w_smooth					//W_smooth is filtered
		WaveStats/q/r=[0,80] W_Smooth
		W_Smooth -= V_avg						//baseline offset
		wTrace2 -= V_Avg
	
		/////////////////////////////////////
		FFT/OUT=1/DEST=Trace_FFT w_smooth 	//FFT of recording trace (after smoothened and baseline offset)
		FFT/OUT=1/DEST=Mini_FFT AvgMini		//FFT of Mini template
		Make/C/O/N=(Npoints) WaveRatio
		WaveRatio = Trace_FFT / Mini_FFT
		Setscale/p x,0,1, WaveRatio
		IFFT/DEST=WaveRatio_IFFT WaveRatio		//inverse FFT of the ratio of recording trace and mini template
		Smooth 3000, WaveRatio_IFFT				//smoothened this one as well
		SetScale/p  x,0,(sampleinterval*1e-6/2), WaveRatio_IFFT	//For some reason, WaveRatio_IFFT has 2x 
														//the number of points of WaveRatio
			WaveStats/q/r=[20,50] W_Smooth	//Calculate threshold of the smoothened current trace
			threshold = -1*FactorUmbral*V_rms			//
			Integrate wTrace2/D=W_Smooth_Int
			setaxis/a bottom					//Sets axis limits for template graph
			setaxis EPSC -60, 20
			SetAxis left -.005,.03
			doupdate
			//Now, actually searches for events, first in the deconv trace, then in the current trace
			for(j=(2*AnalInitT*AcqRate);j<(2*NPoints-100);j+=1)	//scrolls through the deconv trace looking for events
				WaveStats/Q/R=[j,j+(.01*.5/AcqRate)] WaveRatio_IFFT	//event is detected as a local max in deconv trace
				if(V_max > MiniDeconvThresh)			
 					Cursor/P/W=graph10 C ,W_Smooth_Int , round(j/2)//Whend found a possible one, sets cursos
 																//on top of it (next 6 lines, then DoUpdate to see them on graph
			//		Cursor/P/W=graph10 B, W_Smooth_Int, (round(j/2) + 400)
					SetAxis Bottom (round(j/2)/AcqRate - .04), (round(j/2)/AcqRate + .1)
					setaxis right (W_Smooth_Int[round(j/2)]-1), (W_Smooth_Int[round(j/2)]+.1)
					Cursor/P/W=Graph10 D, WaveRatio_IFFT, round(AcqRate*2*V_maxLoc)
					//very important!!!!!!!!!!!!!!!! ---->>
					WaveStats/Q/r=[round(j/2), round(j/2)+(.015*AcqRate)] W_smooth //this wavestat looks for local min
								//in current trace. And it does it in a 15 ms time window starting from the location of peak in deconv trace!!!!!!!
					MinLocCurrT = V_minLoc										//This is peak of current location (in sec)
					WaveStats/Q/R=[(AcqRate*V_minLoc-2), (AcqRate*V_minLoc +2)] wTrace2
					MinLocCurr = V_avg
					WaveStats/Q/r=[((MinLocCurrT - TimePreEvent)*AcqRate),(MinLocCurrT-(TimePreEvent-BaselPeriod))*AcqRate] wTrace2
					BaselinePreEvent = V_avg
					MinLocCurr -= BaselinePreEvent		//Local minimum in current trace, minus baseline
												//baseline is considered where the peak of deconv trace occurs (j/2)
					Cursor/P/C=(0,0,50000)/W=Graph10 A, W_Smooth, round((MinLocCurrT- TimePreEvent)*AcqRate)
					Cursor/P/C=(0,0,50000)/W=Graph10 B, W_Smooth, round(AcqRate*MinLocCurrT)
					Cursor/P/C=(0,0,50000)/W=Graph10_1 A, W_Smooth, round(AcqRate*MinLocCurrT)
					textbox/k/n=sweepn
					TextBox/n=sweepn "Sweep #: "+num2str(i+1)+"\tEvent #: "+num2str(flag+1)
					DoUpdate
					qmini = W_Smooth_Int[(round(j/2) + .04 * AcqRate)] - W_Smooth_Int[round(j/2)]

					if((MinLocCurr < threshold))// && (qmini < -.1))
						ok = 1
						Prompt ok, "OK (0: NO event; 1: OK; 2: Change time point for baseline; 3: NO+Big Jump, 200ms;"
				//		Prompt ok, "4: ABORT)"	//if local minimum is above threshold
						DoPrompt "Mini Analysis", OK				//a window is prompted asking for ok from the operator
						switch(ok)
							case 1:								//Yes to event, adding to the list
								InsertPoints flag, 1, wMiniAmp
								InsertPoints flag, 1, MiniIndexTemp
								InsertPoints flag,1, wMiniTime
//							MinLocCurr = V_avg - wTrace2[round(j/2)]
								wMiniAmp[flag] = MinLocCurr	//One more event registered
								MiniIndexTemp[flag] = (i+1)	//temporal wave for registering sweep #
								wMiniTime[flag] = MinLocCurrT	//Timing of event
								flag+=1						//event # counter
								j += WinJumpP				//j (=point in trace) jumps a few ms to start with anal again
								TimePreEvent = .015
								AlignAvgEffTraces(wTrace2, MinLocCurrT, timePreEvent, flag, file, TraceSponQ)
							break
							case 0:							//if operator does not confirm event, j jumps
								j+= WinJumpP
							break
							case 2:							//In case need to recalculate baseline
								Prompt TimePreEvent, "time before event for baseline (in s)?"
								DoPrompt "MiniAnalysis", TimePreEvent
								j -= 50
							break
							case 3:							//Do a big jump of 200 ms to avoid noise
								j += (.2 *AcqRate)
							break
							case 4:
								abort
							break
							
						endswitch
					endif					
				endif
			endfor
//		endif
	endfor
	edit $sMiniAmp, $sMiniTime, MiniIndexTemp
	printf "File: %g, # Sweeps: %g, Threshold factor: %g, Start point: %g, Deconv thresh: %g\r", file, Nsweeps, FactorUmbral, AnalInitT, MiniDeconvThresh
	WaveStats/Q $sMiniAmp
	flag = V_npnts
	Avgamp = V_avg
	printf "Average amplitude Minis: %g, # Minis: %g\r", AvgAmp, flag
end

Function AlignAvgEffTraces(TraceName, MinLocCurrT, timePreEvent, flag, file, TraceSponQ)
	Wave TraceName
	Variable MinLocCurrT, TimePreEvent, flag, file, TraceSponQ
	NVAR SampleInterval
	Variable i, AcqRate = 1e6/SampleInterval, NPoints = (AcqRate*(TimePreEvent + .1))
	String sEventTrace = "EventTrace_"+num2str(file)+"_"+num2str(flag)
	Make/o/n=(NPoints) $sEventTrace
	Wave wEventTrace = $sEventTrace
	for(i=0; i<(NPoints); i+=1)
		wEventTrace[i] = TraceName[(MinLocCurrT - TimePreEvent) * AcqRate + i]
	endfor
	SetScale/p x,0, (SampleInterval*1e-6), $sEventTrace
	WaveStats/Q/R=(0, .002) $sEventTrace
	wEventTrace -= V_avg
	KineticParamSpontEff(wEventTrace, file, TraceSponQ)
end

Function KineticParamSpontEff(EventTrace, file, TraceSponQ)
	Wave EventTrace
	variable file, TraceSponQ
	NVAR SampleInterval
	Variable AcqRate = 1/(1e-6*SampleInterval)
	String sDecayTau = "DecayTauMinis_"+num2str(file)
	String sRiseTime = "RiseTimeMinis_"+num2str(file)
	Wave wDecayTau = $sDecayTau
	wave wRiseTime = $sRiseTime
	Variable flag = DimSize($sDecayTau, 0)
	InsertPoints flag, 1, $sDecayTau
	InsertPoints flag, 1, $sRiseTime
	Duplicate/o EventTrace, EventTraceSmth
	SetScale/p x,0, (SampleInterval*1e-6), EventTraceSmth
	Smooth 1, EventTraceSmth
	WaveStats/q EventTraceSmth
//	Display EventTrace, EventTraceSmth
//	DoWindow/C event
	FindLevel/Q/R=(0,V_minLoc) EventTraceSmth (V_min*.8)
	wRiseTime[flag] = V_LevelX
	FindLevel/Q/R=(0,V_minLoc) EventTraceSmth (V_min*.2)
	wRiseTime[flag] -= V_LevelX
	CurveFit/q exp_XOffset  EventTraceSmth [(AcqRate*V_minLoc), (AcqRate*.1)] /d
	wDecayTau[flag] = k2
	if(TraceSponQ == 1)
		KillWaves EventTrace
	endif
	if((K2 >= 1) || (K2 < 0))
		DeletePoints flag,1, $sDecayTau, $sRiseTime
	endif
//	dowindow/k event
end

Function SingleEPSCAmpExtract2(files, TiniAnal, TfinAnal, SweepDur)
	//Variable file
	String files
	Variable TiniAnal, TfinAnal, SweepDur
	variable file, Nfiles = ItemsinList(files)
	variable i, n, flag0=0, flag1=0, flag2=0, flag3=0, flag, sweepn = 0
	Make/O/N=0 SingleEPSCAmp
	for(n = 0; n<Nfiles; n+=1)
		file = str2num(StringFromList(n, files, ";"))
		String sEventAmpList = "root:Sw"+num2str(file)+"Folder:Sw"+num2str(file)+"_Amplitude"
		Wave wEventAmpList = $sEventAmpList
		String sEventTimeList = "root:Sw"+num2str(file)+"Folder:Sw"+num2str(file)+"_Time"
		Wave wEventTimeList = $sEventTimeList
		flag0 = DimSize(SingleEPSCAmp, 0)
		Wavestats/q wEventAmpList
		Variable NEvents = V_npnts
		sweepn = 0
		for(i=0; i<NEvents;i+=1)
			do
				if(wEventTimeList[i] > ((sweepn+1)*SweepDur))
					sweepn+=1
				else
					break
				endif
			while(1)
			if((wEventTimeList[i] > (TiniAnal+SweepDur*sweepn)) && (wEventTimeList[i] < (TfinAnal+sweepn*SweepDur)))
				InsertPoints flag0, 1,SingleEPSCAmp
				SingleEPSCAmp[flag0] = wEventAmpList[i]
				flag0+=1
			endif
		endfor
	endfor
End

Function SingleEPSCAmpExtract(files)
	//Variable file
	String files
	variable file, Nfiles = ItemsinList(files)
	variable i, n, flag0=0, flag1=0, flag2=0, flag3=0, flag, sweepn = 0, SweepDur = 2
	Variable TiniAnal = (.03124+.12+.5), TfinAnal = (TiniAnal + .5)
	Make/O/N=0 SingleEPSCAmp_LongPn20mV, SingleEPSCAmp_LongPn30mV, SingleEPSCAmp_LongPn35mV,SingleEPSCAmp_LongPn40mV
	for(n = 0; n<Nfiles; n+=1)
		file = str2num(StringFromList(n, files, ";"))
		String sEventAmpList = "root:Sw"+num2str(file)+"Folder:Sw"+num2str(file)+"_Amplitude"
		Wave wEventAmpList = $sEventAmpList
		String sEventTimeList = "root:Sw"+num2str(file)+"Folder:Sw"+num2str(file)+"_Time"
		Wave wEventTimeList = $sEventTimeList

//	String sSingleEPSCAmp = "SingleEPSCAmp_" + num2str(file)
//	Make/o/N=0 $sSingleEPSCAmp
//	Wave wSingleEPSCAmp = $sSingleEPSCAmp
	
		flag3 =	DimSize(SingleEPSCAmp_LongPn20mV,0)
		flag2 =	DimSize(SingleEPSCAmp_LongPn30mV,0)
		flag1 =	DimSize(SingleEPSCAmp_LongPn35mV,0)
		flag0 =	DimSize(SingleEPSCAmp_LongPn40mV,0)
		WaveStats/q wEventAmpList
		Variable NEvents = V_npnts
		for(i=0; i<NEvents;i+=1)
//		flag = wEventTimeList[i]
//		do
//			if(wEventTimeList[i] > ((sweepn+1)*SweepDur))
//				sweepn+=1
//			else
//				break
//			endif
//		while(1)
//		if((wEventTimeList[i] > (TiniAnal+SweepDur*sweepn)) && (wEventTimeList[i] < (TfinAnal+sweepn*SweepDur)))
//			InsertPoints flag0, 1,$sSingleEPSCAmp
//			wSingleEPSCAmp[flag0] = wEventAmpList[i]
//			flag0+=1
//		endif
			if((wEventTimeList[i] >(TiniAnal)) && (wEventTimeList[i] < TfinAnal))
				InsertPoints flag0, 1, SingleEPSCAmp_LongPn40mV
				SingleEPSCAmp_LongPn40mV[flag0] = wEventAmpList[i]
				flag0 +=1
			endif		
			if((wEventTimeList[i] > (TiniAnal+SweepDur)) && (wEventTimeList[i] <  (TfinAnal+SweepDur)))
				InsertPoints flag1, 1, SingleEPSCAmp_LongPn35mV
				SingleEPSCAmp_LongPn35mV[flag1] = wEventAmpList[i]
				flag1 +=1
			endif
			if((wEventTimeList[i] > (TiniAnal+2*SweepDur)) && (wEventTimeList[i] <  (TfinAnal+2*SweepDur)))
				InsertPoints flag2, 1, SingleEPSCAmp_LongPn30mV
				SingleEPSCAmp_LongPn30mV[flag2] = wEventAmpList[i]
				flag2 +=1
			endif
			if((wEventTimeList[i] > (TiniAnal+3*SweepDur)) && (wEventTimeList[i] <  (TfinAnal+3*SweepDur)))
				InsertPoints flag3, 1, SingleEPSCAmp_LongPn20mV
				SingleEPSCAmp_LongPn20mV[flag3] = wEventAmpList[i]
				flag3 +=1
			endif
		endfor
	endfor
//	edit SingleEPSCAmp_LongPn20mV, SingleEPSCAmp_LongPn30mV, SingleEPSCAmp_LongPn35mV,SingleEPSCAmp_LongPn40mV
end	


	

Function DeconvPost(PostTrace, MiniTrace, AmpMini)
	Wave PostTrace, MiniTrace
	Variable AmpMini
	Variable interv = DimDelta(PostTrace, 0)
	Duplicate/o PostTrace, PostTrace1
	wave MiniTrace2 = MiniTrace//, AvgMini_3
	Wavestats/Q MiniTrace2
	if(V_min < 0)
		MiniTrace2*= ((-1)*AmpMini*1e-12)/V_min
	endif
//	Duplicate/o AvgMini_3, MiniTrace
	PostTrace1 *= 1e-12
	Wavestats/q PostTrace
	variable npoints = V_npnts

	Do
		WaveStats/q MiniTrace2
		if(V_npnts < NPoints)
			InsertPoints (V_npnts), 1, MiniTrace2
			MiniTrace2[V_npnts+1] = 0
		elseif(V_npnts > NPoints)
			DeletePoints (V_npnts-1), 1, MiniTrace2
		else
			break
		endif
	While(1)
	Smooth 10, PostTrace1
	FFT/OUT=1/DEST=PostTrace_FFT PostTrace1
	FFT/OUT=1/DEST=MiniTrace2_FFT MiniTrace2
	make/c/o/n=(V_npnts) waveratiotemp
	setscale/p x,0, (V_npnts), waveratiotemp
	waveratiotemp = PostTrace_FFT / MiniTrace2_FFT
	IFFT/DEST=waveratiotemp_IFFT waveratiotemp
	setscale/p x,0, interv/2, WaveRatioTemp_IFFT
	Smooth 250, WaveRatioTemp_IFFT
	display WaveRatioTemp_IFFT
	WaveRatioTemp_IFFT *= 50
//	String torename = WaveName("", 0,1) + "_deconv"
//	Rename PostTrace, $torename
end

function AvgEnsemble(period)
	Variable period
	Wave EnsembleAmpWave_1, EnsembleAmpWave_2,TimeScale2
	variable i
	WaveStats/Q EnsembleAmpWave_1
	Variable NPointsAvg = floor(V_npnts/period)
	Make/O/N=(NPointsAvg) AvgEnsembleWave_1, SEEnsembleWave_1, AvgEnsembleWave_2, SEEnsembleWave_2, AvgEnsembleTime
	for(i=0; i< NPointsAvg; i+=1)
		WaveStats/q/r=[(period*i), (period*(i+1)-1)] EnsembleAmpWave_1
		AvgEnsembleWave_1[i] = V_avg
		SEEnsembleWave_1[i] = V_sdev/sqrt(period)
		WaveStats/q/r=[period*i, period*(i+1)] EnsembleAmpWave_2
		AvgEnsembleWave_2[i] = V_avg
		SEEnsembleWave_2[i] = V_sdev/sqrt(period)
		AvgEnsembleTime[i] = TimeScale2[period*i]
	endfor
	Display AvgEnsembleWave_1, AvgEnsembleWave_2 vs AvgEnsembleTime
	ModifyGraph mode=4,marker=8,msize=3,rgb(AvgEnsembleWave_1)=(0,0,0);DelayUpdate
	ErrorBars AvgEnsembleWave_1 Y,wave=(SEEnsembleWave_1,SEEnsembleWave_1);DelayUpdate
	ErrorBars AvgEnsembleWave_2 Y,wave=(SEEnsembleWave_2,SEEnsembleWave_2)
End


Function AverageAmpPoints(NtoAvg, EnsembleAmpWave, TimeScale)
	Variable NtoAvg
	Wave EnsembleAmpWave, TimeScale
	WaveStats/Q EnsembleAmpWave
	Variable NNewElem = V_npnts
	Variable i
	Make/o/n=(NNewElem) EnsembleAmpWave_red, TimeScale_red
	for(i=0;i<NNewElem; i+=1)
		WaveStats/Q/R=[(i*NtoAvg), ((i+1)*NtoAvg-1)] EnsembleAmpWave
		EnsembleAmpWave_red[i] = V_avg
		TimeScale_red[i] = TimeScale[i*NtoAvg]
	endfor
	Display EnsembleAmpWave_red vs TimeScale_red
end

Function BarAndIndividualGraph(NameofTable)
	String NameofTable
	Wave/T textWave1 = textwave0
	
	Variable NVariables = ((DimSize(textWave1,0) - 2)
	Wave wParameterValues = WaveRefIndexed(NameofTable, 0, 3)
	Wavestats/q wParameterValues
	Variable NRecordings = (V_npnts - 2*NVariables)/NVariables
	String sNParameterstoGraph=""// = TraceNameList(NameofTable, ";",1)
	Variable NParameterstoGraph = 0
	Do
		if(WaveExists(WaveRefIndexed(NameofTable, NParameterstoGraph, 1)) ==0)
			break
		endif
		NParameterstoGraph += 1
	While(1)	
	
//	Variable NParameterstoGraph = ItemsInList(sNParameterstoGraph)
	String Aux2, sAvgParam, sSEParam, aux3
	Variable i,j,k
	for(i=0; i< NParameterstoGraph; i+=1)
//		Aux2 = StringFromList(i, sNParameterstoGraph)
		Wave wAux2 = WaveRefIndexed(NameofTable, i, 1)//$Aux2
		for(j=0; j<NRecordings; j+=1)
			String sAuxParamtoGraph = "ParametertoGraph"+num2str(i)+"_RecordN"+num2str(j)
			Make/o/n=(NVariables) $sAuxParamtoGraph
			Wave wAuxParamtoGraph = $sAuxParamtoGraph
			for(k=0;k<NVariables; k+=1)
				wAuxParamtoGraph[k] = wAux2[k+j*NVariables]
			endfor
			if(j==0)
				Display $sAuxParamtoGraph
				ModifyGraph mode( $sAuxParamtoGraph)=4;DelayUpdate
				ModifyGraph marker( $sAuxParamtoGraph)=8;DelayUpdate
				ModifyGraph msize( $sAuxParamtoGraph)=3;DelayUpdate
				ModifyGraph rgb( $sAuxParamtoGraph)=(39168,39168,39168)
			else
				appendtograph $sAuxParamtoGraph
				ModifyGraph mode( $sAuxParamtoGraph)=4;DelayUpdate
				ModifyGraph marker( $sAuxParamtoGraph)=8;DelayUpdate
				ModifyGraph msize( $sAuxParamtoGraph)=3;DelayUpdate
				ModifyGraph rgb( $sAuxParamtoGraph)=(39168,39168,39168)
			endif
		endfor

		for(k=0;k<NVariables;k+=1)
			aux3 = textWave1[k]
			sAvgParam = "AvgParameter"+num2str(i)+"_VarN"+num2str(k)//+aux3
			sSEParam = "SEParameter"+num2str(i)+"_VarN"+num2str(k)//+aux3
			Make/O/N=(1) $sAvgParam, $sSEParam
			Wave wAvgParam = $sAvgParam
			Wave wSEParam = $sSEParam
			wAvgParam[0] = wAux2[k+NRecordings*NVariables]
			wSEParam[0] = wAux2[k+(NRecordings+1)*NVariables]
			string baxis = "b"+num2str(k)
			appendtograph/b=$baxis $sAvgParam vs textWave2
			ModifyGraph axisEnab($baxis)={(1/NVariables)*k,(1/NVariables)*(k+1)}
			ErrorBars $sAvgParam Y,wave=($sSEParam,)
			ModifyGraph hbFill($sAvgParam)=0,rgb($sAvgParam)=(0,0,0)
			ModifyGraph noLabel($baxis)=2,axThick($baxis)=0
			ModifyGraph catGap($baxis)=0.3
			ErrorBars/T=2/L=2 $sAvgParam Y,wave=($sSEParam,)
		endfor
		ModifyGraph fSize=8,btLen=4
	endfor
	
End


Function EPSCKinetics(GraphName, file)
	String GraphName
	Variable file
	String sDecayTau = "DecayTauMinis_" + num2str(file)
	String sRiseTime = "RiseTimeMinis_" + num2str(file)
	Make/O/N=0 $sDecayTau, $sRiseTime
	Variable TraceNumber = 0, i
	Do
		if(WaveExists(WaveRefIndexed(GraphName, TraceNumber, 1)) == 0)
			break
		endif
		Wave wWave = WaveRefIndexed(GraphName, TraceNumber, 1)
		KineticParamSpontEff(wWave, file, 0)
		TraceNumber += 1
	While(1)
End


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 04.03.2015 Marcelo

Function ExporttoPrism()
	

	variable file
	
	for(file=0;file<17;file+=1)
	
	string sNFailures = "NFailures_" + num2str(file)
	wave wNFailures = $sNFailures	
	
	print waveexists(wnfailures)
	if (waveexists(wnfailures)==1)
		
		make/o/t/n=11 PrismTableText
		
	PrismTableText[0] ="File"
	PrismTableText[1] = "Failures"
	PrismTableText[2] = "Average"
	PrismTableText[3] = "Average Succes"
	PrismTableText[4] = "m (Failures)"
	PrismTableText[5] = "Q"
	PrismTableText[6] = "HW"
	PrismTableText[7] = "Tau Q"
	PrismTableText[8] = "Tau Decay"
	PrismTableText[9] = "Time Decay 90/10"
	PrismTableText[10] = "Tau Decay 90/10"

	
	//Prompt file, "File to Export"
	//	Doprompt "Export to Prism", file
	//	if (V_flag==1)
	//		Abort
	//	endif
		
	wave paramwave
	variable nsweeps = ParamWave[1]
	
	
	string sAmplitudeWave = "AmplitudeWave_"+num2str(file)+"_1"
	wave wAmplitudeWave= $sAmplitudeWave
		
	variable pFailures1 = wNFailures[0]
	
	wavestats/q  wAmplitudeWave
	
	string sPrismTable= "PrismTable_"+num2str(file)
	Make/o/n=(11,3) $sPrismTable=0
	wave wPrismTable=$sPrismTable
	
	wPrismTable[0][0]= file
	
	wPrismTable[1][0]= pfailures1
	wPrismTable[2][0]= V_avg
	wPrismTable[2][1]= V_sdev
	wPrismTable[3][0]= V_sum/(nsweeps-pfailures1)
	wPrismTable[4][0]= ln(Nsweeps/pFailures1)
			
	string sQWave = "QWave_"+num2str(file)
	wave wQWave= $sQWave
	
	wavestats/q wQWave
	wPrismTable[5][0]= v_avg
	wPrismTable[5][1]= V_sdev
	wPrismTable[5][2]= V_npnts

	string sHWWave = "HWWave_"+num2str(file)
	wave wHWWave= $sHWWave
	
	wavestats/q wHWWave
	wPrismTable[6][0]= v_avg
	wPrismTable[6][1]= V_sdev
	wPrismTable[6][2]= V_npnts
	
	string sTauQWave = "TauQWave_"+num2str(file)
	wave wTauQWave= $sTauQWave
	
	wavestats/q wTauQWave
	wPrismTable[7][0]= v_avg
	wPrismTable[7][1]= V_sdev
	wPrismTable[7][2]= V_npnts

	string sTauDecay = "TauDecay_"+num2str(file)
	wave wTauDecay= $sTauDecay
	
	wavestats/q wTauDecay
	wPrismTable[8][0]= v_avg
	wPrismTable[8][1]= V_sdev
	wPrismTable[8][2]= V_npnts

	string sTime9010 = "Time_90_10_"+num2str(file)
	wave wTime9010= $sTime9010
	
	wavestats/q wTime9010
	wPrismTable[9][0]= v_avg
	wPrismTable[9][1]= V_sdev
	wPrismTable[9][2]= V_npnts
	
	
	
	string sTau_90_10 = "Tau_90_10_"+num2str(file)
	wave wTau_90_10= $sTau_90_10
		wavestats/q wTau_90_10
	wPrismTable[10][0]= v_avg
	wPrismTable[10][1]= V_sdev
	wPrismTable[10][2]= V_npnts
	
	endif

//Edit  root:PrismTableText,root:PrismTable

endfor

end

//////////////////////////////////////////////////////////////////////////


Function RemocionArtefacto_Integra() 
 
 string/g currentfilename
 
 variable file
 
 Prompt file, "File:" 
 DoPrompt "# File a analizar", file
 	
		if(V_flag==1)
			abort
		endif
 
String filedata
sprintf filedata,"%04d",file


string filesheader= currentfilename+"_"+filedata+"*"
 
 
string/g Files=WaveList(filesheader, ";" , "") 
string sw=StringFromList(0, Files, ";")
wave w = $sw

display/n=Wave_ACTUAL w
ShowInfo/CP=0/W=Wave_ACTUal
Cursor/P/W=Wave_ACTUal A ,$sw, 5000
Cursor/P/W=Wave_ACTUal B ,$sw, 5200
  
	DoWindow/F WMImageROIPanel
	if( V_Flag==1 )
		return 0
	endif
	
	NewPanel /K=1/w=(600,80,730,130) as "Artifact Substraction"
	DoWindow/C WMImageROIPanel
	ModifyPanel fixedSize=0

	Button StartButton,size={115,25}, pos={7,7}, proc=RemArt_FillFit_Automat,title="Start Procedure"
	
	end


Function RemArt_FillFit_Automat(ctrlname)

String ctrlName

string/g Files

if( CmpStr(ctrlName,"StartButton") == 0 ) 
	
killwindow  WMImageROIPanel

variable t1a,t2B
Variable t1, t2, i, av
 Variable SampleInterval = 19.99
 Variable Freq=  80
 variable TotalNstim
 		
string sFrequencies= "5;20;80;"

string sFReq
 	
variable index
variable totalfiles=ItemsInList(Files,";")	

do

string sw=StringFromList(index, Files, ";")
wave w = $sw

string sDATA = "DATA_"+sw
make/o/n=3 $sdata
wave wDATA=$sdata

if(index==0)

Prompt TotalNstim, "# Estímulos"
Prompt sFreq, "Train Stimulation Frequency:" ,popup ,sFrequencies
 	 	 	DoPrompt "Stimulation Characteristics",TotalNstim, sFreq
 	
		if(V_flag==1)
			abort
		endif
		
		
	If (str2num (sFReq) ==5)
 		Freq=1/0.19999// 5.00025001250062
 	endif
 	
 	If (str2num (sFReq)==20)
 	Freq=1/0.049993 //20.0032005120819
 	//TotalNstim=60
 	endif
 	
	If (str2num(sFReq)==80)
	Freq= 1/0.012494 //80.0448251020571
	//TotalNstim=240
	endif
	

else

appendtograph/q/W=Wave_ACTUal w
ShowInfo/CP=0/W=Wave_ACTUal

Cursor/P/W=Wave_ACTUal A ,$sw,  t1A
Cursor/P/W=Wave_ACTUal B ,$sw,  t2B	

doupdate

endif

 	

string sw_dup="WOArtifact_"+sw

duplicate/o w, $sw_dup

wave wdup= $sw_dup
 
 	 t1A=pcsr(A) 
	 t2B=pcsr(B) 
	
	t1=t1a
	t2=t2b
		
variable nstim

	for(nstim=1;nstim<=totalnstim;nstim+=1)
	
	 for (i= t1+1;i<t2;i+=1)
		wdup[i]=nan
	endfor 
	
	CurveFit/NTHR=0/Q/TBOX=0 line wdup[ t1, t2+1]
	
	for (i= t1;i<t2;i+=1)
		wdup[i]=K1*i*SampleInterval*1e-6 + K0
	endfor 
	
	t1=t1a+nstim*(1/(SampleInterval*1e-6*Freq))
	t2=t2b+nstim*(1/(SampleInterval*1e-6*Freq))
	
	endfor
	
string sw_int="INT_"+sw
duplicate/o wdup, $sw_int

wave w_int=$sw_int

WaveStats/Q/R=(0.005/SampleInterval*1e-6, 0.90/SampleInterval*1e-6) w_int

variable baseline = V_avg 
wdup-=V_avg
w_int-=baseline

Integrate/METH=2 w_int


If (str2num (sFReq) ==5)
	WaveStats/Q/R=(2.395, 2.405) w_int
 	wdata[0]=v_avg
 endif
 	
 If (str2num (sFReq)==20)
	WaveStats/Q/R=(0.745, 0.755) w_int
 	wdata[0]=v_avg
 	 endif
 	
If (str2num(sFReq)==80)

	WaveStats/Q/R=(0.325, 0.3425) w_int
 	wdata[0]=v_avg
 	
endif

WaveStats/Q/R=(0.005, 0.09) wdup

variable baselineamp = V_avg 

wavestats/q/R=(0.2, 6)  wdup
variable peakloc= V_minloc
variable peak=V_min-baselineamp

wDATA[1]= peak
wDATA[2]= peakloc


index+=1	
	
removefromgraph $sw


while(index<totalfiles)

killwindow 	Wave_ACTUal
	endif
End

