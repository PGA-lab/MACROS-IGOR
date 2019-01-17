#pragma rtGlobals=1	// Use modern global access method.
#include <FilterDialog> menus=0


// This routine returns the name of the top image in the top graph
Function/S WMTopImageName1()    //Marcelo - Esta Funcion la duplique a partir de un macro de un paquete de Igor para adaptarla a mi Propio analisis de imagenes

	String grfName
	Variable i=0
	do
		grfName= WinName(i, 1)
		if( strlen(grfName) == 0 )
			break
		endif
		String list=ImageNameList(grfName, ";")
		if( strlen( list) != 0 )
			return StringFromList(0,list,";")
			break
		endif
		i += 1
	while(1)
	return ""
end		


// This routine is used to fetch a full path to the image wave in the top
// graph. A zero length string is returned if failure

Function/S WMGetImageWave1(grfName)            // Marcelo - Esta Funcion la duplique a partir de un macro de un paquete de Igor para adaptarla a mi Propio analisis de imagenes
	String grfName							// use zero len str to speicfy top graph

	String s= ImageNameList(grfName, ";")
	Variable p1= StrSearch(s,";",0)
	if( p1<0 )
		return ""			// no image in top graph
	endif
	s= s[0,p1-1]
	Wave w= ImageNameToWaveRef(grfName, s)
	return GetWavesDataFolder(w,2)		// full path to wave including name
end


// This routine fetches the name of the top graph containing an image
Function/S WMTopImageGraph1()

	String grfName
	Variable i=0
	do
		grfName= WinName(i, 1)
		if( strlen(grfName) == 0 )
			break
		endif
		if( strlen( ImageNameList(grfName, ";")) != 0 )
			break
		endif
		i += 1
	while(1)
	return grfName
end	


//////////////////////////////////////////////////////////////////

Function AutoROIImgProcV2() /// Non-ratiometric dyes Calcium imaging analysis. ///////////////// 
					

//Generate Panel Which controls Background-ROI drawing
 
variable/g file, NTotImgs, Nsweeps, folder
variable/g x0,y0,rext=15,angle=15
variable/g criteria
variable/g integral
variable/g ThresholdMin=0.4,ThresholdMax=0.9
variable/g stimulus,SubrangeROIa,SubrangeROIb
 
 String igName= WMTopImageGraph1()
	
	if( strlen(igName) == 0 )
		DoAlert 0,"No image plot found"
		return 0
	endif
	
	DoWindow/F $igname
	DoWindow/F WMImageROIPanel
	
	if( V_Flag==1 )
		return 0
	endif
	
	NewPanel /K=1/W=(00,260,595,535) as "ROI Creation Parameters"
	DoWindow/C WMImageROIPanel
	AutoPositionWindow/E/M=1/R=$igName
	ModifyPanel fixedSize=1
	Groupbox Fileprop, pos={19,58},size={176,179}
	Groupbox Location, pos={209,58},size={176,179}
	Groupbox Analysis, pos={398,58},size={176,179}
	DrawText 52,80,"FILE PROPERTIES"
	DrawText 229,80,"LOCATION PROPERTIES"
	DrawText 420,80,"ANALYSIS PARAMETERS"
			
	Button StartROI,pos={33,245},size={150,20},proc=AUTOROIStart,title="Start Background-ROI Draw"
	Button StartROI,help={"Adds drawing tools to top image graph. Use rectangle, circle or polygon."}
	Button clearROI,pos={409,245},size={150,20},proc=AUTOROIStart,title="Erase ROI"
	Button clearROI,help={"Erases previous ROI. Not undoable."}
	Button FinishROI,pos={222,245},size={150,20},proc=AUTOROIStart,title="Finish Background-ROI"
	Button FinishROI,help={"Click after you are finished editing the ROI to start analysis"}
	
	SetVariable FILE,pos={39,95},size={135,16},title="FILE:",value= file 
		SetVariable FILE,help={"Determine the number of the file to analyze"}
		
	SetVariable folder,pos={39,123},size={135,16},title="VERSION:",value=folder
		SetVariable folder,help={"Determine VERSION # in case you want to perform multiple analysis to the same file"}

	SetVariable NTotImgs,pos={39,151},size={135,16},title="TOTAL IMAGES:",value= ntotimgs
			SetVariable ntotimgs,help={"Determine the total number of images you want to analyze"}

	SetVariable Nsweeps,pos={39,179},size={135,16},title="TOTAL SWEEPS:", value= nsweeps
			SetVariable nsweeps,help={"Determine the total number of sweeps you want to analyze"} // Total Images/Total sweeps will determine the number of images per file
			
	SetVariable stimulus,pos={39,207},size={135,16},title= "Stimulus time (ms):", value= stimulus
			SetVariable stimulus,help={"Electrophysiology stimulus time"} 
				
	SetVariable x0,pos={231,95},size={135,16},title="X center:",value=x0
			SetVariable x0,help={"X center of the circunference"}	
			
	SetVariable y0,pos={232,132},size={135,16},title="Y center:", value=y0
			SetVariable y0,help={"Y center of the circunference"}		
	
	SetVariable rext,pos={232,169},size={135,16},title="External Radius:",value= rext
				SetVariable rext,help={"External radius of the circunference"} //This area will set the external limits of the analysis	
				
	SetVariable angle,pos={232,206},size={135,16},title="Angle:",value= angle
			SetVariable angle,help={"Determine circunference angle for each ROI"}  /// This will also determine de number of ROIs ---> 360/angle
	
	SetVariable criteria,pos={420,95},size={135,16},title="Peak Criteria:", value= criteria
			SetVariable criteria,help={"This value determines how many times the STDEV the peak has to be, to be considered an event"}  
	
	SetVariable Integral,pos={420,132},size={135,16},title="Integral Criteria:", value= integral
			SetVariable integral,help={"This value determines the area under the peak so it can be considered an event"}  

	SetVariable ThresholdMin,pos={420,169},size={135,16},title="Threshold Min:",  value= ThresholdMin
			SetVariable ThresholdMin,help={"Minimal relative pixel value threshold"} // All the images in the file are averaged and normalized to the highest pixel value

	SetVariable ThresholdMax,pos={420,206},size={135,16},title="Threshold Max:", value= ThresholdMax
		SetVariable ThresholdMax,help={"Maximal relative pixel value threshold"} 
	
	//CheckBox zeroRoiCheck,value= 1

	PopupMenu AnalysisMode,pos={25,30},size={209,19},title="Analysis Output:"
	PopupMenu AnalysisMode,value= #"\"Delta F\F0;Delta F\""
	
	CheckBox PhotoBleaching,pos={35,10},size={92,10}, title=" Photobleaching Correction"
	CheckBox PhotoBleaching,value= 1
	CheckBox PhotoBleaching,help= {"Photobleaching will be corrected by fitting a straight line to the pre-stimulus signal"}
	
	SetVariable SubrangeROIa,pos={215,8},size={160,16},title="Photobleaching PRE:",value=  SubrangeROIa
			SetVariable ntotimgs,help={""}
			
	SetVariable SubrangeROIb,pos={215,32},size={160,16},title="Photobleaching POST:",value= SubrangeROIb
			SetVariable ntotimgs,help={""}
	
			
	CheckBox Smoothing,pos={405,33},size={92,10}, title=" Smooth ROI traces"
	CheckBox Smoothing,value= 0
	CheckBox Smoothing,help= {"Photobleaching will be corrected by fitting a straight line to the pre-stimulus signal"}
		
	CheckBox AutoCenterDEtermination,pos={405,10},size={92,10},title="Automatic Center Determination"
	CheckBox AutoCenterDEtermination,value= 1
	CheckBox AutoCenterDEtermination,help= {"This will determine the center of the circunference by searching the maximum pixel value in the average"}
	
end

//////////////////////////////////Launch panel functions

Function AUTOROIStart(ctrlName) : ButtonControl
	
	String ctrlName
	String ImGrfName= WMTopImageGraph1()
		if( strlen(ImGrfName) == 0 )
			return 0
		endif
	
	DoWindow/F $ImGrfName
		
	if( CmpStr(ctrlName,"clearROI") == 0 )
		GraphNormal
		SetDrawLayer/K ProgFront
		DoWindow/F WMImageROIPanel

	endif
	
	if( CmpStr(ctrlName,"StartROI") == 0 ) // Press Start Background To
		
		ShowTools/A  oval
		SetDrawLayer ProgFront
		setdrawenv fillpat=0,linefgc=(0,52224,0)
		SetDrawEnv gstart,gname=ROIoutline
	endif
	
	
	if( CmpStr(ctrlName,"FinishROI") == 0 ) 
	
	drawaction/l=progfront getgroup=ROIoutline, commands //genera S_recreation con lo dibujado
	GraphNormal
	HideTools/A
	
	ControlInfo/w=WMImageROIPanel PhotoBleaching
	variable v_PhotoBleaching = V_value 
	
	ControlInfo/w=WMImageROIPanel AnalysisMode
	variable v_AnalysisMode = V_value 

	ControlInfo/w=WMImageROIPanel AutoCenterDEtermination
	variable v_autocenter = V_value 
	
	ControlInfo/w=WMImageROIPanel BackgroundCorrection
	variable V_backcorrect = V_value 
	
	ControlInfo/w=WMImageROIPanel thresholdOption
	variable V_thresholdMODE = V_value
	
	ControlInfo/w=WMImageROIPanel Smoothing
	variable V_Smooth = V_value
	
	
//////////////////////////// Define all the global variables for the rest of the analysis 

	nvar file, NTotImgs, Nsweeps, folder
	nvar x0,y0,rext,angle
	nvar criteria
	nvar integral
	nvar ThresholdMin,ThresholdMax
	nvar stimulus,SubrangeROIa,SubrangeROIb
	
	If(SubrangeROIa==SubrangeROIb)
	
		SubrangeROIa=0
		SubrangeROIb=(360/angle)-1
		
	endif
	
	String igName= WMTopImageGraph1()
	
	String sImgName
	String ImgN
	string IndexFileName = WMTopImageName1()[4,11] ////Extracts cell file name
	String Q= stringfromlist(4,s_recreation)
	Variable j,i 					////////////////////////////  Throughout the macro: j counts number of sweeps and i counts number of image

	
	String topWave=WMGetImageWave1(WMTopImageGraph1()) 
	WAVE/Z ww=$topWave
	if(WaveExists(ww)==0)
		return 0
	endif
	
//////////////////////////// Generates The folder where all the waves will be stored in case you want to perform multiple analysis
		
	String sFolder= WMTopImageName1()[4,11]+"_F_"+num2str(file)+"_v_"+num2str(Folder)	
		
	if( DataFolderExists(sFolder) == 0)
		NewDataFolder  $sFolder
	else
		DoAlert 0,"Version Number Exists"
		return 0			
	endif


	String saveDF=GetDataFolder(1)
	String waveDF=GetWavesDataFolder(ww,1 )
	SetDataFolder waveDF
			
//////////////////////////// Duplicate and filter Image Stack in blocks related to number of images per sweep

	For(j=0;j<Nsweeps;j+=1)
		Duplicate/O/R=(, )(, )(j*Ntotimgs/Nsweeps,j*Ntotimgs/Nsweeps+Ntotimgs/Nsweeps-1)  ww, TransitionalStack
		wave TransitionalStack
		
		ImageFilter/o/N=3 gauss3d  TransitionalStack
		
		if(j==0)
		duplicate/o  TransitionalStack, FilteredImage
		wave FilteredImage
		
		else
		
		concatenate/np {TransitionalStack},FilteredImage
		
		endif
		
	endfor
		
	Killwaves TransitionalStack
	
//////////////////////////// Generate Background ROI Mask

	ImageGenerateROIMask/E=1/I=0 $WMTopImageName1()		
	SetDataFolder saveDF
	wave M_ROIMask
	
	string BackROIMask="ROIMask_"+num2str(file)+"_Back"
	duplicate/o M_ROIMask, $BackROIMask
	
	//DoWindow/K WMImageROIPanel //Close panel that controls Background ROI drawing


//////////////////////////// Create Background wave

	String sBackROI = "Back_"+num2str(file)
	Make/O/N=(NTotImgs) $sBackROI
	Wave wbackROI = $sBackROI

	Make/WAVE/o/N=(NtotImgs) wawback
	MultiThread wawback=ROI_AVERAGESIGNAL(FilteredImage,p,M_ROIMask) //////// Multi-thread Function that allows to calculate the average ROI pixel value using multiple processors.

	WAVE w= wawback[0]
	Duplicate/O w, wbackROI // w contains references to Free Data Folders that save the average ROI pixel value 

	Variable h /// h represents the number of image to be analyzed by ROI_AVERAGESIGNAL
	
	for(h=1; h<ntotimgs; h+=1) 
		wave w= wawback[h] // Get a reference to the next free data folder
		concatenate/NP {w}, wbackROI
	endfor

	KillWaves wawback
	
	MoveWave $BackROIMask, :$(sFolder):  // Move the Background Mask to the defined Analysis Folder


//////////////////////////// Defining the threshold for each file

//1-Generate An average Image for the whole file

	variable pixelswide=dimsize(FilteredImage,0)  /// here we determine the widht and height of each image in the file
	variable pixelsheight=dimsize(FilteredImage,1)

	imagetransform/o averageImage,  FilteredImage
	wave M_aveImage

//2-Normalize the averaged image 

	ImageThreshold/i/M=(5)/Q M_AveImage // Determination of cellular flourescence limits using Iterative method. M_Imagethresh is the output
	wave M_ImageThresh
	
	Imagetransform invert M_ImageThresh
	wave M_inverted
	M_inverted/=255
	M_AveImage*=M_inverted
		
	String sImageNormalization="ImageNormalization_"+num2str(file) 
	Make/o/n=(pixelswide,pixelsheight) $sImageNormalization
	Wave  wImageNormalization=$sImageNormalization

	wImageNormalization =  M_aveImage
	WaveStats/Q wImageNormalization

	Variable min=V_min
	Variable delta=1.0/(V_max-V_min)
	Variable deltaM=delta*min
		
	Fastop wImageNormalization=(delta)*wImageNormalization-(deltaM)
		
//3-We generate a Mask Using the max and min values that will determine the area of each image that will be considered for analysis based on the threshold values determined
		
	String sROIMasksThreshold="ROIMasksThreshold_"+num2str(file)    //Creation of the wave that will contain the threshold mask               
	Make/o/n=(pixelswide,pixelsheight) $sROIMasksThreshold
	Wave  wROIMasksThreshold=$sROIMasksThreshold
	Fastop wROIMasksThreshold=wImageNormalization
	
	make/n=2/o Thresholdwave={ThresholdMin,ThresholdMax} //Wave that contains threshold values
	Fastop wROIMasksThreshold=wImageNormalization
	imagethreshold/o/w=thresholdwave wROIMasksThreshold
		
	wROIMasksThreshold /= 255

//4-  DEFINING CENTER -  This defines a center based on the average of all the images in the files. The center will be the center of mass, otherwise center indicated in control panel	
		
	If( v_autocenter==1)
		ImageAnalyzeParticles /E/W/Q/M=3/A=5/EBPC stats, wROIMasksThreshold  //Particle analysis to determine contour and center of the cell

		wave M_moments
		
		X0= M_moments[0][0]   
		Y0= M_moments[0][1]    //Particle analysis based center of mass

		
	endif

	killwaves wImageNormalization
/////////////////////// DEFINE INTERIOR AND EXTERIOR CIRCLES

//1-Draw external and internal circunferences 

	SetDrawLayer UserFront
	SetDrawEnv xcoord= top,ycoord= left,save
	showtools
	setdrawenv fillpat=0,linefgc=(58880,19712,6656),save

	string outercircle="drawarc/x/Y "+ num2str(x0)+","+num2str(y0)+","+num2str(rext)+",0,360"

	execute outercircle
	execute Q

//2-Draw triangles based in the given angle. Each triangle will determine a different ROI

	Variable K //K counts de number of triangles needed to complete the circle
	String nROI=num2str(k+1)

	for(K=0;K<(360/angle);K+=1) 

		nROI=num2str(k+1)

		GraphNormal
		HideTools/A
		SetDrawLayer ProgFront
		SetDrawEnv xcoord= top,ycoord= left,save

		setdrawenv fillpat=0,linefgc=(0,52224,0),save
		drawpoly x0,y0,1,1,{x0,y0,x0+Rext*cos(k*angle*2*pi/360),y0+Rext*sin(k*angle*2*pi/360),x0+Rext*cos(angle*2*pi/360+2*pi*angle*k/360),y0+Rext*sin(angle*2*pi/360+2*pi*angle*k/360),x0,y0}					

		setdrawenv fillpat=-1,linefgc=(0,52224,0),save
		
	
		ImageGenerateROIMask/E=0/I=1 $WMTopImageName1()	///generates the Mask for that ROI. The output wave is M_ROIMASK
	
		String sROIMasks="ROIMasks_"+num2str(file)                             //this wave will contain the masks for all the ROIs
		Make/o/n=(pixelswide,pixelsheight,(360/angle)) $sROIMasks
		Wave  wROIMasks=$sROIMasks 
	
		M_ROIMask*= wROIMasksThreshold
		M_ROIMask-=1
		M_ROIMask*=(-1)

		Multithread wROIMasks[][][k]=M_ROIMask[p][q]

		execute "drawaction/l=progfront delete"    /////// this will draw the ROI in userfront layer and erase it from progfront
		SetDrawLayer UserFront
		SetDrawEnv xcoord= top,ycoord= left,save
		setdrawenv fillpat=0,linefgc=(0,52224,0), save
		drawpoly x0,y0,1,1,{x0,y0,x0+Rext*cos(k*angle*2*pi/360),y0+Rext*sin(k*angle*2*pi/360),x0+Rext*cos(angle*2*pi/360+2*pi*angle*k/360),y0+Rext*sin(angle*2*pi/360+2*pi*angle*k/360),x0,y0}		

///3-Calculate the average pixel value in that ROI for each image in the file using the Multi-thread function "Worker"
		
		Make/WAVE/o/N=(NtotImgs) waw
		
		MultiThread waw= ROI_AVERAGESIGNAL(Filteredimage,p,M_ROIMask)
				
		If(K==0)
			Make/o/n=(ntotimgs,360/angle) ConcatenatedSweeps=0
			wave wConcatenatedSweeps=ConcatenatedSweeps
		endif
		
		for(h=0; h<ntotimgs; h+=1)
			WAVE w= waw[h]
			wConcatenatedSweeps[h][K]= w[0]	
		endfor
		
		KillWaves waw

	endfor	
				
///4- Background Substraction 

wConcatenatedSweeps[][]-=wbackROI[p]

//////////////////NUMERICAL ANALYSIS OF EACH ROI LOOKING FOR IMAGING SUCCESFUL EVENTS

//1-Define and create all the waves that will hold the information 

string sAmplitude="Amplitude"	//////generate a 2D wave that shows the peak signal detected in each ROI for each sweep		
make/o/n=(nsweeps,360/angle) $sAmplitude=0
wave wamplitude=$sAmplitude

string sIntegralArea="Integral_Area"	//////generate a 2D wave that shows the integral of the imaging signal detected in each ROI for each sweep		
make/o/n=(nsweeps,360/angle) $sIntegralArea=0
wave WIntegralArea=$sIntegralArea	

string sTauImaging="TauImaging"  ////// this wave will show the decay TAU for each event
make/o/n=(nsweeps,360/angle) $sTauImaging =0
wave WTauImaging=$sTauImaging

string sPeakTime="PeakTime"  ////// 
make/o/n=(nsweeps,360/angle) $sPeakTime =0
wave wPeakTime=$sPeakTime

String sProbability= "ProbabilityROIs_"+num2str(file)
Make/o/n=(360/angle) $sProbability = 0
Wave wProbability = $sProbability ////////////// this wave will show the probability of each ROI to show a positive EF and IMG event

String sBaselineF= "BaselineF"
Make/o/n=(nsweeps,360/angle) $sBaselineF = 0
Wave wBaselineF = $sBaselineF ////////////// this wave will show the fluorescence baseline for each ROI in each sweep prior to Normalization to F0. 

//2- Select Timewave containing the The timepoints for each images

string ImageWaveName= WMTopImageName1()
variable len= strlen(ImageWaveName)	
string sTimewave="Timewave_"+ImageWaveName[1,len-2] //num2str(file)

wave timewave=$stimewave

Findlevel/q/p timewave,(stimulus/1000) /// Defines time stimulus for each sweep
variable Stim=V_LevelX
				
//3- Photobleaching Correction, Normalization to basal fluorescence and 

		Make/df/o/N=(nsweeps) dfw
		MultiThread dfw= Imaging_Smooth(wConcatenatedSweeps,Stim,p,ntotImgs,nsweeps,angle,V_smooth) // Multithread function that Filters the normalized image of each sweep

		dfref df=dfw [0] 
		string sSubplano="subplano"+num2str(0)
		wave Subplano=df:$sSubplano		
		
		Duplicate/O/R=(0,ntotImgs/nsweeps-1)  Timewave, TimewaveSweep	
		
			Make/df/o/N=(360/angle) dfwR
			MultiThread dfwR= Imaging_CurveFIT(Subplano,TimewaveSweep,p,ntotImgs,nsweeps,angle,v_analysismode,stim,criteria,integral,v_PhotoBleaching,SubrangeROIa,SubrangeROIb) 
			dfref df=dfwR [0] 
			string sSubwave="subwave"+num2str(0)
			string swdata="wdata"+num2str(0)
			
			wave Subwave=df:$sSubwave
			wave wdata=df:$swdata	
			
			Duplicate/O subwave, Subplano
			
			wamplitude[0][0]=wdata[0]
			wPeakTime[0][0]=wdata[1]
			WIntegralArea[0][0]=wdata[2]
			WTauImaging[0][0]=wdata[3]
			wBaselineF[0][0]=wdata[4]
		
			for(k=1; K<360/angle; K+=1)
				df = dfwr[K] 
				sSubwave="subwave"+num2str(k)
				wave Subwave=df:$sSubwave		
				concatenate {Subwave}, Subplano
				
				swdata="wdata"+num2str(k)
				wave wdata=df:$swdata
					
				wamplitude[0][k]=wdata[0]
				wPeakTime[0][k]=wdata[1]
				WIntegralArea[0][k]=wdata[2]
				WTauImaging[0][k]=wdata[3]
				wBaselineF[0][k]=wdata[4]			
			endfor
			
		Duplicate/O Subplano, wConcatenatedSweeps
			
		variable t

		for(j=1; j<nsweeps; j+=1)
			df = dfw[j] 
			sSubplano="subplano"+num2str(j)
			wave Subplano=df:$sSubplano	
			
			Duplicate/O/R=(J*ntotImgs/nsweeps, J*ntotImgs/nsweeps+ntotImgs/nsweeps-1)  Timewave, TimewaveSweep
			SetScale/P x 0,1,"", TimewaveSweep
	
				Make/df/o/N=(360/angle) dfwR
				MultiThread dfwR= Imaging_CurveFIT(Subplano,TimewaveSweep,p,ntotImgs,nsweeps,angle,v_analysismode,stim,criteria,integral,v_PhotoBleaching,SubrangeROIa,SubrangeROIb) 
				dfref df=dfwR [0] 
				sSubwave="subwave"+num2str(0)
				wave Subwave=df:$sSubwave		
				Duplicate/O subwave, Subplano
				
				swdata="wdata"+num2str(0)
				wave wdata=df:$swdata	
				wamplitude[j][0]=wdata[0]
				wPeakTime[j][0]=wdata[1]
				WIntegralArea[j][0]=wdata[2]
				WTauImaging[j][0]=wdata[3]
				wBaselineF[j][0]=wdata[4]		
			
				for(k=1; K<360/angle; K+=1)
					df = dfwr[K] 
					sSubwave="subwave"+num2str(k)
					wave Subwave=df:$sSubwave		
					concatenate {Subwave}, Subplano
					
					swdata="wdata"+num2str(k)
					wave wdata=df:$swdata	
					wamplitude[j][k]=wdata[0]
					wPeakTime[j][k]=wdata[1]
					WIntegralArea[j][k]=wdata[2]
					WTauImaging[j][k]=wdata[3]
					wBaselineF[j][k]=wdata[4]					
				endfor
			
			concatenate/NP=0 {Subplano}, wConcatenatedSweeps

		endfor
		
		KillWaves dfw
		KillWaves dfwR


//////////////MOVING ALL THE INFORMATION WAVES TO THE CREATED ANALYSIS FOLDER

MoveWave :$samplitude, :$(sFolder):
MoveWave :$sIntegralarea, :$(sFolder):
MoveWave :$sTauimaging, :$(sFolder):
MoveWave :$sPeakTime, :$(sFolder):
MoveWave :$sProbability, :$(sFolder):
MoveWave :$sBaselineF, :$(sFolder):

string/G AutoROIAnalVar="X0="+num2str(x0)+";Y0="+num2str(y0)+";stim="+num2str(stimulus)+"Rext="+num2str(rext)+"Angle="+num2str(angle)+"criteria="+num2str(criteria)+"integral="+num2str(integral)+"Photobleaching ROIs template="+num2str(SubrangeROIa)+"-"+num2str(SubrangeROIb)
movestring AutoROIAnalVar, :$(sFolder):

MoveWave :$sROIMasks, :$(sFolder):
MoveWave :$sROIMasksThreshold, :$(sFolder):

MoveWave :concatenatedsweeps, :$(sFolder):
MoveWave $sBackROI, :$(sFolder):

killwaves filteredimage,M_aveimage, M_imagethresh, Timewavesweep,M_rOIMASK
killwaves M_moments

	DoWindow/K $igName


endif

end

///////////////////////////////////////////////////////////////////////////////////////////////////////////

ThreadSafe Function/Wave ROI_AVERAGESIGNAL(wImgStack, plane, M_ROIMask) //// This Function allows the Multi-thread  calculation of the average of each ROI for all the file's images

WAVE wImgStack
WAVE M_ROIMask
Variable plane

DFREF dfSav= GetDataFolderDFR()
SetDataFolder NewFreeDataFolder()

ImageStats/p=(plane)/R=M_ROIMask  wImgStack
make/free/o/n=(1) wdata=v_avg

SetDataFolder dfSav

return wdata

End

//////////////////////////////////////////////////////////////////////////////////////////////////////////

ThreadSafe Function/DF Imaging_Smooth(wConcatenatedSweeps,Stim,j,ntotImgs,nsweeps,angle,V_smooth)  //// Smooths the sweep stacks generated after Stacking all the ROIs for each sweep

WAVE wConcatenatedSweeps
Variable Stim,j, ntotImgs,nsweeps,angle,V_smooth

DFREF dfSav= GetDataFolderDFR()
DFREF dfFree= NewFreeDataFolder()
SetDataFolder  dfFree

string sSubplano="Subplano"+num2str(j)

duplicate/o/r=(j*NTotImgs/Nsweeps,j*NTotImgs/Nsweeps+NTotImgs/Nsweeps-1)(0,360/angle)(,) wConcatenatedSweeps,$ssubplano

if(V_smooth==1)

matrixfilter/o/n=2 gauss $ssubplano

endif


SetDataFolder dfSav
return  dfFree

End

////////////////////////////////////////////////////
ThreadSafe Function/DF Imaging_CurveFIT(Subplano,TimewaveSweep,j,ntotImgs,nsweeps,angle,AnalysisMODE,Stim,criteria,integral,v_PhotoBleaching,SubrangeROIa,SubrangeROIb)  

WAVE Subplano,TimewaveSweep
Variable j, ntotImgs,nsweeps,angle,AnalysisMODE,Stim,criteria,integral,v_PhotoBleaching,SubrangeROIa,SubrangeROIb

DFREF dfSav= GetDataFolderDFR()
DFREF dfFree= NewFreeDataFolder()

SetDataFolder  dfFree

imagetransform/g=(j) getcol Subplano
wave W_extractedcol

////Photobleaching Correction by fitting to a straight line  //// Fitting to values before stim and 10 images before the end of the sweep

string sSubwave="subwave"+num2str(j)
Make/n=(ntotImgs/nsweeps) $sSubwave
wave Subwave=$sSubwave

If(v_PhotoBleaching==1)

	//duplicate/o/r=()(SubrangeROIa,SubrangeROIb) Subplano, PhotoExtract
	
	duplicate/o W_extractedcol, PhotoExtract

	//imagetransform sumallrows PhotoExtract
	//wave W_sumRows
	wave W_sumRows=PhotoExtract

	
	//W_sumRows/=(SubrangeROIb-SubrangeROIa+1)

	duplicate/o W_sumRows, Fiteo
	
	Fiteo[stim,ntotImgs/nsweeps-10]=nan
	CurveFit/Q=1/W=2  line,  Fiteo
	
	wave W_coef
	
	Subwave=W_extractedCol[x]-(W_coef[1]*x)
	
	
else

Subwave=W_extractedCol[x]

endif

///// creation of the wave that contains all the output values
string sData="wdata"+num2str(j)
make/o/n=(5)  $sdata
wave wData=$sdata


 ////Normalization to FLuorescence AVerage before stimulus
WaveStats/R = (0, Stim) Subwave
variable F0=V_avg 

wdata[4]= F0

if(AnalysisMODE==1)  	
	Subwave-=F0
	Subwave/=F0
	Subwave[0]=0	

elseif(AnalysisMODE==2)
	Subwave-=F0
endif

///// Imaging Peak Detection and fitting based on parameter : criteria & Integral

duplicate Subwave, Subwave_smooth
FilterFIR/LO={0.08,0.14,19}/WINF=KaiserBessel20 Subwave_smooth

WaveStats/R = (0, Stim) Subwave_smooth
variable SDEV=V_sdev

WaveStats/R = (stim,) Subwave_smooth
variable V_peakval= V_max
variable V_peakloc= V_maxloc

variable PEAKAREA = area(Subwave_smooth,Stim,(NTotImgs/Nsweeps))


///FindPeak/B=50/P/Q/R=(Stim,Stim*2.5) Subwave_smooth

if((V_peakval>= SDEV*criteria) && (PEAKAREA>=Integral))
	wdata[0]=V_peakval
	wdata[1]=TimewaveSweep[V_PeakLoc]-TimewaveSweep[0]
	wdata[2]=PEAKAREA
	
	///CurveFit/N=1/Q=1/W=2  exp_XOffset, Subwave[V_PeakLoc,(NTotImgs/Nsweeps)]/X=TimewaveSweep[V_PeakLoc,] // /NWOK
	wave W_coef
	//wdata[3]=W_coef[2]
	
else
	wdata[0]=0
	wdata[1]=0
	wdata[2]=0
	wdata[3]=0
	
endif

SetDataFolder dfSav
return  dfFree

End

////////////////////////////////////////////////////////////////////////////////////////////////

Function ROIImgProc()   /////////////////////////////////Oct 2012 // Juan

	variable file
	String ROI
	Variable P1,P2,Q1,Q2
	
	Prompt file, "File:"
	Prompt ROI, "ROI:"
	Prompt P1, "start P"
	Prompt P2, "end P"
	Prompt Q1, "start Q"
	Prompt Q2, "end Q"
	Doprompt "Draw ROIs", file,ROI,P1,P2,Q1,Q2
		if (V_flag==1)
			Abort
		endif


	SVAR S_fileName
	String sFileName, ImgN, IndexFileName = S_fileName[0,10],FolderIndexName="Img"
	Variable i, RSAux=0, j=0, k, NSweeps, NTot350Imgs, SweeptoInterp
	Wave RatioScheme
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//Sets NTotImgs: total number of imagens in experiment, NSweeps: number of sweeps	
	variable rows=dimsize(ratioscheme,0)
	ImageStats/G={0,(rows-1),1,1} RatioScheme
	Variable NTotImgs = round(V_avg*V_npnts)
	ImageStats/G={0,(rows-1),0,0} RatioScheme
	Make/O/N=(round(V_avg*V_npnts)) YWaveInterp
//	NTot350Imgs = NTotImgs - round(V_avg*V_npnts)
	Wave XWaveInterp, Time_img
	Nsweeps = DimSize(RatioScheme,0)
	if(NSweeps>1)
		sFileName = "root:"+FolderIndexName+num2str(file)+":"+IndexFileName+"_"+num2str(file)+"_10000"
	else	
//		sFileName = "root:"+FolderIndexName+num2str(file)+":"+ndexFileName+"_"+num2str(file)+"0000"
		sFileName = IndexfileName+"_"+num2str(file)+"0000"
	endif
	wave wFileName = $sFileName
	String sWaveROI, sWaveBack
	//Now, determines if it is determining background values or ROI
	if(CmpStr(ROI, "back") == 0)
		sWaveROI = "Back_"+num2str(file)
		Make/O/N=(NTotImgs,2) $sWaveROI
		Wave wWaveROI = $sWaveROI
	else
		sWaveROI = "ROI_"+num2str(file)+"_"+ROI
		Make/o/n=(NTotImgs,2) $sWaveROI
		Wave wWaveROI = $sWaveROI
		sWaveBack = "Back_"+num2str(file)
		Wave wWaveBack = $sWaveBack
		
		String sROIRatio = "ROI"+ROI+"Ratio_"+num2str(file)
		Make/o/n=(NTotImgs) $sROIRatio
		Wave wROIRatio = $sROIRatio
	endif
//	sFileName = IndexFileName+"_"+num2str(file)+"_10000"
	//Drawing settings to mark ROI on first image in sequence
	SetDrawLayer ProgFront
	SetDrawEnv linefgc= (65535,65535,65535),fillpat= 0,xcoord= top,ycoord= left, save
	DrawRect P1,Q1,P2,Q2
	DrawText P1,Q1,ROI; doupdate
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	//Now, sets values of light intensity in ROI for sweeps with both 350 and 380 images
	//Also, gives values to YWaveInterp that will later be used to interpolate in sweep/s where 350 images were not taken
	//
	Variable XOffset = 0, XOffset1 = 0
	for(j=1;j<(NSweeps+1);j+=1) 		//j counts sweeps, 
		if(j > 1)
			XOffset += RatioScheme[(j-2)][1]
			XOffset1 += RatioScheme[(j-2)][0]
		endif
	for(i=0;i<(RatioScheme[(j-1)][0]);i+=1)		//This cycle goes through individual images in EACH sweep with both 350 and 380. 
											//The number of images in each sweep is taken from RatioScheme-column 0
		ImgN = num2str(2*i)					//Now, measures intensities for 350 images first
		do
			if(strlen(ImgN) < 4)
				ImgN = "0"+ImgN
			endif
		while(strlen(ImgN) < 4)
		if(NSweeps>1)
			sFileName = "root:"+FolderIndexName+num2str(file)+":"+IndexFileName+"_"+num2str(file)+"_"+num2str(j)+ImgN
		else	
			//sFileName = "root:"+FolderIndexName+num2str(file)+":"+IndexFileName+"_"+num2str(file)+ImgN
			sFileName = IndexfileName+"_"+num2str(file)+ImgN
		endif
		Wave wFileName = $sFileName
		if((P1 != 0) && (Q1 != 0))
			ImageStats/G={P1,P2,Q1,Q2} $sFileName
		else
			ImageStats/R=roiWave $sFileName
		endif
		wWaveROI[i+XOffset][0] = V_Avg					//This is the wave that collects 350 image intensities
		YWaveInterp[i+XOffset1] = V_Avg					//This wave is to use later in interpolation
										//////////////////////////////////////////////////////////////////////////////////////////////////
		
		ImgN = num2str(2*i+1)					//Now, measures intensities for 380 images
		do
			if(strlen(ImgN) < 4)
				ImgN = "0"+ImgN
			endif
		while(strlen(ImgN) < 4)
//		sFileName = "root:Img"+num2str(file)+":"+IndexFileName+"_"+num2str(file)+ImgN//+"_1"+ImgN
		if(NSweeps>1)
			sFileName = "root:"+FolderIndexName+num2str(file)+":"+IndexFileName+"_"+num2str(file)+"_"+num2str(j)+ImgN
		else	
//			sFileName = "root:"+FolderIndexName+num2str(file)+":"+IndexFileName+"_"+num2str(file)+ImgN
			sFileName = IndexfileName+"_"+num2str(file)+ImgN
		endif
		Wave wFileName = $sFileName
		if((P1 != 0) && (Q1 != 0))
			ImageStats/G={P1,P2,Q1,Q2} $sFileName
		else
			ImageStats/R=roiWave $sFileName
		endif
		wWaveROI[i+XOffset][1] = V_Avg		
	endfor
	endfor
//	

	SweeptoInterp = -1
	Do											//
		SweeptoInterp += 1						//
		if(RatioScheme[SweeptoInterp][0] == 0)		//Looks for sweep that needs interpolation
			For(i=0;i<(RatioScheme[SweeptoInterp][1]);i+=1)//Found one. Takes number of images in that sweep from RatioScheme-column1
				ImgN = num2str(i)
				do
					ImgN = "0"+ImgN
				while(strlen(ImgN) < 4)
				sFileName = "root:"+FolderIndexName+num2str(file)+":"+IndexFileName+"_"+num2str(file)+"_"+num2str(SweeptoInterp+1)+ImgN
				Wave wFileName = $sFileName
				ImageStats/G={P1,P2,Q1,Q2} $sFileName
				wWaveROI[i+RatioScheme[0][0]][1] = V_avg				//This is intensity for 380 image taken from measurement
				wWaveROI[i+RatioScheme[0][0]][0]= interp((time_img[i+RatioScheme[0][0]]),XWaveInterp, YWaveInterp)//This is 350 intensity
			Endfor																						//taken from interpolation
		endif
	While(SweeptoInterp<NSweeps)
	
	wROIRatio = (wWaveROI[p][0] - wWaveBack[p][0])/(wWaveROI[p][1]- wWaveBack[p][1])
	Display wROIRatio// vs Time_img
//	NewImage M_ROIMask
End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
