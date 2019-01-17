#pragma rtGlobals=1		// Use modern global access method.

FUNCTION LoadABF()


	Variable number
	String /G CurrentFile, CurrentFileName, IndexCurrFileName
	Variable /G NumChannels, lADCResolution, DataSectionPtr, SampleInterval, refnum, lDataSectionPtr
	
	//---------- FIRST STEP: EXAMINING THE FILE'S HEADER ----------
	Variable counter
	open /d/r/t="????" refnum					// does not actually open the file, puts the file name into S_filename
	CurrentFile = S_filename
	counter = -12								// 12: number of characters in the name of a .abf file
	CurrentFileName=""
//	Do
//		CurrentFileName = CurrentFileName + CurrentFile[strlen(currentfile) + counter]
//		counter += 1
//	while (counter < 1)
	CurrentFileName = CurrentFile[(strlen(currentfile)-17), (strlen(currentfile)-5)] 	//Added to change name by Juan 16Dec09
	IndexCurrFileName = CurrentFileName[0,7]
	open /r/t="????" refnum as CurrentFile		// opens the file, allows the fstatus operation
		fstatus refnum						// returns 6 variables, in particular S_filename and V_logEOF (the total number of bytes in the file)
	close refnum
	if (V_logEOF < 2048)
		return(1)								// the current procedure stops executing immediately
	endif
	String sSweepParams = "SweepParams_"+CurrentfileName[9,12]
	Make/O/n=(1,2)/t $sSweepParams
	Wave/t sweep_params = $sSweepParams
	LOAD_FILE_PARAMETERS(CurrentFile)	// load parameters from header
	//execute "SampleInterval = str2num(sweep_params[29][1])"
	//execute "NumChannels = str2num(sweep_params[28][1])"
	SampleInterval = str2num(sweep_params[29][1])
	NumChannels = str2num(sweep_params[28][1])
		
	if (NumChannels == 2)
		SampleInterval = SampleInterval * 2
	endif
	lADCResolution = str2num(sweep_params[54][1])
	lDataSectionPtr = str2num(sweep_params[12][1])
	//KillWaves sweep_params
	// ---------- END OF FIRST STEP ----------

	// ---------- SECOND STEP: PROMPTING THE GAIN ---------- 	In the future, the gain should be found in the header
	If (NumChannels==1)
		Variable /G Gain
		Variable GainValue ; GainValue = 1		// Local variable used for prompting
		Prompt GainValue, "Enter gain value (mV/pA)"
		Doprompt "Gain", GainValue
		if (V_flag==1)
			Abort
		endif
		Gain = GainValue			// Gain is a global variable
		Variable ScaleFactor
		ScaleFactor = 1 / (GainValue*.001*lADCResolution/10) ; PRINT lADCResolution
	endif
	if (NumChannels==2)
		Variable /G Gain1, Gain2
		Variable GainValue_1 ; GainValue_1 = 1
		Variable GainValue_2 ; GainValue_2 = 1
		Variable FileType = 1
		Prompt GainValue_1, "Enter gain value for channel 1 (mV/pA)"
		Prompt GainValue_2, "Enter gain value for channel 2 (mV/pA)"
		Prompt FileType, "Is it a new (1) or an old (0) file?"
		DoPrompt "Gain", GainValue_1, GainValue_2, FileType
		if (V_flag==1)
			Abort
		endif
		Gain1 = GainValue_1 ; Gain2 = GainValue_2
		Variable ScaleFactor1, ScaleFactor2
		ScaleFactor1 = 1 / (GainValue_1*.001*lADCResolution/10)
		ScaleFactor2 = 1 / (GainValue_2*.001*lADCResolution/10)
	endif
	
		//¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤ ajouté le 17-04-2005 ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
		Variable fADCRange, lADCResolution2
		Execute "GBLoadWave/O/B/Q/N=header/T={32,4}/W=1/U=512 (CurrentFile)"
		Wave Header0
		lADCResolution2 =  header0[63]
		Execute "GBLoadWave/O/B/Q/N=header/T={2,4}/W=1/U=511 (CurrentFile)"
		fADCRange = header0[61]
		ScaleFactor = fADCRange/(lADCResolution*Gain*.001)

	
	// ---------- END OF SECOND STEP ----------
	
	// ---------- THIRD STEP: LOADING THE FILE ----------
	
	if (NumChannels == 2 && FileType == 1)
		execute "GBLoadWave/Q/B=2/T={16,4}/S=2048/O/N=Data/W=2/V/Y={0,1} (CurrentFile)"
		Wave Data0, Data1
		Data0 = Data0 * ScaleFactor1 ; Deletepoints 0, 1024, Data0	// !!! Corrected for 1024, 16Dec09 Juan
		Data1 = Data1 * ScaleFactor2 ; Deletepoints 0, 1024, Data1	// !!!
	elseif (NumChannels ==2 && FileType == 0)
		execute "GBLoadWave/Q/B=2/T={16,4}/S=2048/O/N=Data/W=2/V/Y={0,1} (CurrentFile)"
		Wave Data0, Data1
		Data0 = Data0 * ScaleFactor1 ; Deletepoints 0, 1536, Data0	// !!! Corrected for 1024, 16Dec09 Juan
		Data1 = Data1 * ScaleFactor2 ; Deletepoints 0, 1536, Data1	// !!!
	endif
	if (NumChannels == 1)
		execute "GBLoadWave/Q/B=2/T={16,4}/S=2048/O/N=Data/W=1/Y={0,1} (CurrentFile)"
		Wave Data0
		Data0 = Data0 * ScaleFactor
		Deletepoints 0, 0, Data0		// !!! Simillarly to NumChann =2
//		SetScale/P x 0,SampleInterval*1e-6, "s", Data0
//		Variable /G FileLength ; FileLength = (numpnts(Data0)-1) * SampleInterval*1e-6	// will be used later...
		String TEMP
		TEMP = CurrentFileName
//		Wave wTemp = $TEMP modificado el 13/11/14	
//		Rename Data0 $TEMP
//		Save/C wTemp///$TEMP modificado el 13/11/14
	endif
	// ---------- END OF THIRD STEP ----------
	
	// ---Third step prime--- Juan 16Dec2009
	Variable SweepN = 1, counterj
	Variable NumSweeps = str2num(Sweep_Params[5][1])
	Variable SweepNPnts = str2num(Sweep_Params[3][1]) / (NumChannels*str2num(Sweep_Params[5][1]))
	if(NumChannels == 2)
		Do
			String NewTemp1 = CurrentFileName + "_" + num2str(SweepN) +"_1"
			Make/O/N=(SweepNPnts) $NewTemp1
			Wave wNewTemp1 = $NewTemp1					
			String NewTemp2 = CurrentFileName + "_" + num2str(SweepN) + "_2"
			Make/O/N=(SweepNPnts) $NewTemp2
			Wave wNewTemp2 = $NewTemp2
		
			for(counterj=0;counterj<SweepNPnts;counterj+=1)
				wNewTemp1[counterj] = Data0[((SweepN-1)*SweepNPnts)+counterj]
				wNewTemp2[counterj] = Data1[((SweepN-1)*SweepNPnts)+counterj]
			endfor
			
		SetScale/P x 0,SampleInterval*1e-6, "s", wNewTemp1
		SetScale/P x 0,SampleInterval*1e-6, "s", wNewTemp2
		Variable /G FileLength ; FileLength = (numpnts(wNewTemp2)-1) * SampleInterval*1e-6
		
			SweepN +=1
		While (SweepN<=NumSweeps)
	endif
	
	if(NumChannels == 1)
		Do
			String NewTemp = CurrentFileName + "_" + num2str(SweepN) + "_1"
			Make/O/N=(SweepNPnts) $NewTemp
			Wave wNewTemp = $NewTemp
			for(counterj=0;counterj<SweepNPnts;counterj+=1)
				wNewTemp[counterj] = Data0[(SweepN-1)*SweepNPnts+counterj]
			endfor
						
			SetScale/P x 0,SampleInterval*1e-6, "s", wNewTemp
			Variable /G FileLength ; FileLength = (numpnts(wNewTemp)-1) * SampleInterval*1e-6			
			SweepN+=1
		While(SweepN <=NumSweeps)	
	endif
	
	//-----------------------------------------------------------
	
	
	// ---------- FOURTH STEP: PRINTING VARIABLES IN COMMAND WINDOW ----------
	if (NumChannels==1)
		print "File name: " + CurrentFileName + " - 1 channel" + " - Sample interval = " + num2str(SampleInterval) + " µs/pt - Output gain = " + num2str(Gain) + " mV/pA"
	endif
	if (NumChannels==2)
		print "File name: " + CurrentFileName + " - 2 channels" + " - Sample interval = " + num2str(SampleInterval) + " µs/pt - Output gain channel 1 = " + num2str(Gain1) + " mV/pA - Output gain channel 2 = " + num2str(Gain2) + " mV/pA"
	endif
	// ---------- END OF FOURTH STEP ---------
	
	KillWaves Data0, Data1
END


FUNCTION LOAD_FILE_PARAMETERS(file_name)
	string file_name

	// given file name, will extract many parameters from the header, placing the values, all as text, in
	// the wave sweep_params
	SVAR CurrentFileName
	String sSweepParams2 = "SweepParams_"+CurrentfileName[9,12]
	Wave/t sweep_params = $sSweepParams2
	
//	wave /t sweep_params = sweep_params
	
	variable numdata			
	variable counter = 0
	variable loopcount
	
	string chardata
	
	Nvar refnum
	
	Svar CurrentFile = CurrentFile
	
	open /r/t="????" refnum as CurrentFile

	counter = load_text(	"sFileType",				refNum, counter, 4)
	counter = load_float(	"fFileVersionNumber", 		refNum, counter)
	counter = load_int(		"nOperationMode", 			refNum, counter)
	counter = load_longint(	"lActualAcqLength", 			refNum, counter)
	counter = load_int(		"nNumPointsIgnored", 		refNum, counter)
	counter = load_longint(	"lActualEpisodes", 			refNum, counter)
	counter = load_longint(	"lFileStartDate", 			refNum, counter)
	counter = load_longint(	"lFileStartTime", 			refNum, counter)
	counter = load_longint(	"lStopwatchTime", 			refNum, counter)
	counter = load_float(	"fHeaderVersionNumber", 	refNum, counter)
	counter = load_int(		"nFileType", 				refNum, counter)
	counter = load_int(		"nMSBinFormat", 			refNum, counter)
	counter = load_longint(	"lDataSectionPtr", 			refNum, counter)
	counter = load_longint(	"lTagSectionPtr", 			refNum, counter)
	counter = load_longint(	"lNumTagEntries", 			refNum, counter)
	counter = load_longint(	"lLongDescriptionPtr", 		refNum, counter)
	counter = load_longint(	"lLongDescriptionLines", 	refNum, counter)
	counter = load_longint(	"lDACFilePtr", 				refNum, counter)
	counter = load_longint(	"lDACFileNumEpisodes", 	refNum, counter)

	FSetPos refNum, 72

	counter = load_longint(	"lDeltaArrayPtr", 			refNum, counter)
	counter = load_longint(	"lNumDeltas", 				refNum, counter)
	counter = load_longint(	"lNotebookPtr", 			refNum, counter)
	counter = load_longint(	"lNotebookManEntries", 	refNum, counter)
	counter = load_longint(	"lNotebookAutoEntries", 	refNum, counter)
	counter = load_longint(	"lSynchArrayPtr", 			refNum, counter)
	counter = load_longint(	"lSynchArrayPtr", 			refNum, counter)
	counter = load_longint(	"lSynchArraySize", 			refNum, counter)
	counter = load_longint(	"nDataFormat", 				refNum, counter)

	FSetPos refNum, 120

	counter = load_int(		"nADCNumChannels", 			refNum, counter)
	counter = load_float(	"fADCSampleInterval", 			refNum, counter)
	counter = load_float(	"fADCSecondSampleInterval", 	refNum, counter)
	counter = load_float(	"fSynchTimeUnit", 				refNum, counter)
	counter = load_float(	"fSecondsPerRun", 				refNum, counter)
	counter = load_longint(	"lNumSamplesPerEpisode", 		refNum, counter)
	counter = load_longint(	"lPreTriggerSamples", 			refNum, counter)
	counter = load_longint(	"lEpisodesPerRun", 				refNum, counter)
	counter = load_longint(	"lRunsPerTrial", 				refNum, counter)
	counter = load_longint(	"lNumberOfTrials", 			refNum, counter)
	counter = load_int(		"nAveragingMode", 				refNum, counter)
	counter = load_int(		"nUndoRunCount", 				refNum, counter)
	counter = load_int(		"nFirstEpisodeInRun", 			refNum, counter)
	counter = load_float(	"fTriggerThreshold", 			refNum, counter)
	counter = load_int(		"nTriggerSource", 				refNum, counter)
	counter = load_int(		"nTriggerAction", 				refNum, counter)
	counter = load_int(		"nTriggerPolarity", 			refNum, counter)
	counter = load_float(	"fScopeOutputInterval", 		refNum, counter)
	counter = load_float(	"fEpisodeStartToStart", 			refNum, counter)
	counter = load_float(	"fRunStartToStart", 			refNum, counter)
	counter = load_float(	"fTrialStartToStart", 			refNum, counter)
	counter = load_longint(	"lNumberOfTrials", 			refNum, counter)
	counter = load_longint(	"lAverageCount", 				refNum, counter)
	counter = load_longint(	"lClockChange", 				refNum, counter)

	FSetPos refNum, 244

	counter = load_float(		"fADCRange", 				refNum, counter)
	counter = load_float(		"fDACRange", 				refNum, counter)
	counter = load_longint(		"lADCResolution", 			refNum, counter)
	counter = load_longint(		"lDACResolution", 			refNum, counter)
	counter = load_int(			"nExperimentType", 		refNum, counter)
	counter = load_int(			"nAutoSampleEnable", 		refNum, counter)
	counter = load_int(			"nAutoSampleADCNum", 	refNum, counter)
	counter = load_int(			"nAutoSampleInstrument", 	refNum, counter)
	counter = load_float(		"fAutoSampleAdditGain", 	refNum, counter)
	counter = load_float(		"fAutoSampleFilter", 		refNum, counter)
	counter = load_float(		"fAutoSampleMembraneCap", refNum, counter)
	counter = load_int(			"nManualInfoStrategy", 		refNum, counter)
	counter = load_float(		"fCelIID1", 					refNum, counter)
	counter = load_float(		"fCelIID2", 					refNum, counter)
	counter = load_float(		"fCelIID3", 					refNum, counter)
	counter = load_text(		"sCreatorInfo",				refNum, counter, 16)
	counter = load_text(		"sFileComment",			refNum, counter, 56)

	FSetPos refNum, 378

	loopcount = 0
	do
		counter = load_int(	"nADCPtoLChannelMap" 		+ num2str(loopcount), refNum,counter)
		loopcount += 1
	while (loopcount < 16)

	loopcount = 0
	do
		counter = load_int(	"nADCSamplingSeq" 			+ num2str(loopcount), refNum, counter)
		loopcount += 1
	while (loopcount < 16)

	loopcount = 0
	do
		counter = load_text(	"sADCChannelName" 			+ num2str(loopcount), refNum, counter, 10)
		loopcount += 1
	while (loopcount < 16)

	loopcount = 0
	do
		counter = load_text(	"sADCUnits" 				+ num2str(loopcount), refNum, counter, 8)
		loopcount += 1
	while (loopcount < 16)

	loopcount = 0
	do
		counter = load_float(	"fADCProgrammableGain" 		+ num2str(loopcount), refNum, counter)
		loopcount += 1
	while (loopcount < 16)

	FSetPos refNum, 922

	loopcount = 0
	do
		counter = load_float(	"fInstrumentScaleFactor" 		+ num2str(loopcount), refNum, counter)
		loopcount += 1
	while (loopcount < 16)

	loopcount = 0
	do
		counter = load_float(	"fInstrumentOffset" 			+ num2str(loopcount), refNum, counter)
		loopcount += 1
	while (loopcount < 16)

	loopcount = 0
	do
		counter = load_float(	"fSignalGain" 				+ num2str(loopcount), refNum, counter)
		loopcount += 1
	while (loopcount < 16)

	loopcount = 0
	do
		counter = load_float(	"fSignalOffset" 				+ num2str(loopcount), refNum, counter)
		loopcount += 1
	while (loopcount < 16)

	loopcount = 0
	do
		counter = load_float(	"fSignalLowPassFilter" 		+ num2str(loopcount), refNum, counter)
		loopcount += 1
	while (loopcount < 16)

	loopcount = 0
	do
		counter = load_float(	"fSignalHighPassFilter" 		+ num2str(loopcount), refNum, counter)
		loopcount += 1
	while (loopcount < 16)

	loopcount = 0
	do
		counter = load_text(	"sDACChannelName" 			+ num2str(loopcount), refNum, counter, 10)
		loopcount += 1
	while (loopcount < 4)

	loopcount = 0
	do
		counter = load_text(	"sDACChannelsUnits"			+ num2str(loopcount), refNum, counter, 8)
		loopcount += 1
	while (loopcount < 4)

	loopcount = 0
	do
		counter = load_float(	"fDACScaleFactor" 			+ num2str(loopcount), refNum, counter)
		loopcount += 1
	while (loopcount < 4)

	loopcount = 0
	do
		counter = load_float(	"fDACHoldingLevel" 			+ num2str(loopcount), refNum, counter)
		loopcount += 1
	while (loopcount < 4)

	counter = load_int(		"nSignalType", 				refNum, counter)

	FSetPos refNum, 1436

	counter = load_int(		"nDigitalEnable", 				refNum, counter)
	counter = load_int(		"nWaveformSource", 			refNum, counter)
	counter = load_int(		"nActiveDACChannel", 		refNum, counter)
	counter = load_int(		"nInterEpisodeLevel", 			refNum, counter)

	loopcount = 0
	do
		counter = load_int(	"nEpochType" 				+ num2str(loopcount), refNum, counter)
		loopcount += 1
	while (loopcount < 10)

	loopcount = 0
	do
		counter = load_float(	"nEpochInitLevel" 			+ num2str(loopcount), refNum, counter)
		loopcount += 1
	while (loopcount < 10)

	loopcount = 0
	do
		counter = load_float(	"nEpochLevelInc" 			+ num2str(loopcount), refNum, counter)
		loopcount += 1
	while (loopcount < 10)

	loopcount = 0
	do
		counter = load_int(	"nEpochInitDuration" 			+ num2str(loopcount), refNum, counter)
		loopcount += 1
	while (loopcount < 10)

	loopcount = 0
	do
		counter = load_int(	"nEpochDurationInc" 			+ num2str(loopcount), refNum, counter)
		loopcount += 1
	while (loopcount < 10)

	counter = load_int(		"nDigitalHolding",				refNum, counter)
	counter = load_int(		"nDigitalInterEpisode", 		refNum, counter)

	loopcount = 0
	do
		counter = load_int(	"nDigitalValue" 				+ num2str(loopcount), refNum, counter)
		loopcount += 1
	while (loopcount < 10)

	counter = load_float(		"fWaveformOffset", 			refNum, counter)

	FSetPos refNum, 1620

	counter = load_float(		"fDACFileScale", 				refNum, counter)
	counter = load_float(		"fDACFileOffset", 				refNum, counter)

	FSetPos refNum, 1630

	counter = load_int(		"nDACFileEpisodeNum", 		refNum, counter)
	counter = load_int(		"nDACFileADCNum", 			refNum, counter)
counter = load_text(		"sDACFileName",				refNum, counter, 12)
counter = load_text(		"sDACFilePath",				refNum, counter, 60)

FSetPos refNum, 1718

counter = load_int(		"nConditEnable", 				refNum, counter)
counter = load_int(		"nConditChannel", 			refNum, counter)
counter = load_longint(	"nConditNumPulses", 			refNum, counter)
counter = load_float(		"fBaselineDuration", 			refNum, counter)
counter = load_float(		"fBaselineLevel", 				refNum, counter)
counter = load_float(		"fStepDuration", 				refNum, counter)
counter = load_float(		"fStepLevel", 					refNum, counter)
counter = load_float(		"fPostTrainPeriod", 			refNum, counter)
counter = load_float(		"fPostTrainLevel", 			refNum, counter)

FSetPos refNum, 1762

counter = load_int(		"nParamToVary", 			refNum, counter)
counter = load_text(		"sParamValueList",			refNum, counter, 80)

counter = load_int(		"nAutopeakEnable", 			refNum, counter)
counter = load_int(		"nAutopeakPolarity", 			refNum, counter)
counter = load_int(		"nAutopeakADCNum", 		refNum, counter)
counter = load_int(		"nAutopeakSearchMode", 		refNum, counter)
counter = load_longint(	"lAutoPeakStart", 			refNum, counter)
counter = load_longint(	"lAutoPeakEnd", 				refNum, counter)
counter = load_int(		"nAutopeakSmoothing", 		refNum, counter)
counter = load_int(		"nAutopeakBaseline", 		refNum, counter)
counter = load_int(		"nAutopeakAverage", 			refNum, counter)

FSetPos refNum, 1880

counter = load_int(		"nArithmeticEnable", 			refNum, counter)

FSetPos refNum, 1890

counter = load_int(		"nArithmeticADCNumA", 		refNum, counter)
counter = load_int(		"nArithmeticADCNumB", 		refNum, counter)
counter = load_float(		"fArithmeticK1", 				refNum, counter)
counter = load_float(		"fArithmeticK2", 				refNum, counter)
counter = load_float(		"fArithmeticK3", 				refNum, counter)
counter = load_float(		"fArithmeticK4", 				refNum, counter)
counter = load_text(		"sArithmeticOperator",		refNum, counter, 2)
counter = load_text(		"sArithmeticUnits",			refNum, counter, 8)
counter = load_float(		"fArithmeticK5", 				refNum, counter)
counter = load_float(		"fArithmeticK6", 				refNum, counter)
counter = load_int(		"nArithmeticExpression", 		refNum, counter)

FSetPos refNum, 1932

counter = load_int(		"nPNEnable", 				refNum, counter)
counter = load_int(		"nPNPosition", 				refNum, counter)
counter = load_int(		"nPNPolarity", 				refNum, counter)
counter = load_int(		"nPNNumPulses", 			refNum, counter)
counter = load_int(		"nPNADCNum", 				refNum, counter)
counter = load_float(		"fPNHoldingLevel",			refNum, counter)
counter = load_float(		"fPNSettlingTime",			refNum, counter)
counter = load_float(		"fPNInterPulse",				refNum, counter)

FSetPos refNum, 1966

counter = load_int(		"nListEnable", 				refNum, counter)

if (dimsize(sweep_params,0) > (counter + 1))
	deletepoints counter, dimsize(sweep_params,0)-counter, sweep_params
endif

end

FUNCTION 		LOAD_TEXT(parameter, refNum, counter, char_count)		// load required number of characters
string parameter
variable refNum
variable counter
variable char_count
SVAR CurrentFileName

string chardata
//wave /t sweep_params// = sweep_params
	String sSweepParams = "SweepParams_"+CurrentfileName[9,12]
	Wave/t sweep_params = $sSweepParams
	
//if (waveexists(sweep_params))
//	wave /t sweep_params = sweep_params
	if (dimsize(sweep_params,0) < (counter + 1))
		insertpoints dimsize(sweep_params,0), 1, sweep_params
	endif
//else
//	make /t/n=(1,2) sweep_params
//endif

FReadLine /n=(char_count) refNum, chardata
sweep_params[counter][0] = parameter
SetDimLabel 0, counter, $parameter sweep_params
sweep_params[counter][1] = chardata

counter += 1

return counter

end




FUNCTION 		LOAD_FLOAT(parameter, refNum, counter)					// load 4-byte float
string parameter
variable refNum
variable counter
SVAR CurrentFileName
variable numdata
string chardata
	String sSweepParams = "SweepParams_"+CurrentfileName[9,12]
	Wave/t sweep_params = $sSweepParams//wave /t sweep_params//= sweep_params

//if (waveexists(sweep_params))
//	wave /t sweep_params = sweep_params
	if (dimsize(sweep_params,0) < (counter + 1))
		insertpoints dimsize(sweep_params,0), 1, sweep_params
	endif
//else
//	make /t/n=(1,2) sweep_params
//endif

FBinRead /b=3 /f=4 refNum, numdata				
sweep_params[counter][0] = parameter
SetDimLabel 0, counter, $parameter sweep_params
sprintf chardata ,"%9.6E", numdata
sweep_params[counter][1] = chardata

counter += 1

return counter

end



FUNCTION 		LOAD_INT(parameter, refNum, counter)					// load 2-byte integer
string parameter
variable refNum
variable counter
SVAR CurrentFileName
variable numdata
string chardata
variable places
	String sSweepParams = "SweepParams_"+CurrentfileName[9,12]
	Wave/t sweep_params = $sSweepParams//wave /t sweep_params// = sweep_params

//if (waveexists(sweep_params))
//	wave /t sweep_params = sweep_params
	if (dimsize(sweep_params,0) < (counter + 1))
		insertpoints dimsize(sweep_params,0), 1, sweep_params
	endif
//else
//	make /t/n=(1,2) sweep_params
//endif

FBinRead /b=3 /f=2 refNum, numdata
sweep_params[counter][0] = parameter
SetDimLabel 0, counter, $parameter sweep_params
if ((numdata >= 10) && (numdata > 0))
	places = trunc(log(numdata))
else
	places = 1
endif
sprintf chardata ,"%1.*d", places, numdata
sweep_params[counter][1] = chardata

counter += 1

return counter

end



FUNCTION		LOAD_LONGINT(parameter, refNum, counter)					// load 4-byte integer
string parameter
variable refNum
variable counter
SVAR CurrentFileName
variable numdata
string chardata
variable places
	String sSweepParams = "SweepParams_"+CurrentfileName[9,12]
	Wave/t sweep_params = $sSweepParams//wave /t sweep_params //= sweep_params

//if (waveexists(sweep_params))
//	wave /t sweep_params = sweep_params
	if (dimsize(sweep_params,0) < (counter + 1))
		insertpoints dimsize(sweep_params,0), 1, sweep_params
	endif
//else
//	make /t/n=(1,2) sweep_params
//endif


FBinRead /b=3 /f=3 refNum, numdata
sweep_params[counter][0] = parameter
SetDimLabel 0, counter, $parameter sweep_params
if ((numdata >= 10) && (numdata > 0))
	places = trunc(log(numdata))
else
	places = 1
endif
sprintf chardata ,"%1.*d", places, numdata
sweep_params[counter][1] = chardata

counter += 1

return counter

end