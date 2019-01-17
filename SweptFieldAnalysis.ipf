#pragma rtGlobals=1		// Use modern global access method.
#include <FilterDialog> menus=0
#include <All IP Procedures>
#include <Image Saver>



//////////////////////////////////////////////////////////////////////////

Function SweptFieldAnalysisFeeder()

String test
variable nfile,totplanes=10,images=90,deleteimages=2

	Prompt test, "Image File:", popup Wavelist("Img*", ";", "")
	prompt nfile, "File Number:"
	prompt totplanes, "Total planes:"
	Prompt Images, "Images per plane:"
	Prompt deleteimages, "Delete # Images:"
	
	
	DoPrompt "Select waves",test,nfile,totplanes,Images,deleteimages

	If (v_flag)
		return -1
	endif
	
nvar file

file=nfile
	
	SyncingSweeps(totplanes,file)
	
variable/g z=0

nvar folder

duplicate/o $test,original

wave original


DeletePoints/M=2 0, deleteimages, original
 
variable i,j

variable Rows=dimsize (original, 0) 
variable columns= dimsize (original, 1)


For(z=0;z<totplanes;z+=1)
	
	string Sweep=test+"_Plane_"+num2str(z)
	
			Make/o/n=(rows,columns,Images) $Sweep=0
		
			Wave wSweep=$sweep
			
			for (j=0; j<images;j+=1)
	
				wsweep[][][j] = Original [p][q][j+images*z]

			endfor
	
	string Actualplane=test+"_Plane_"+num2str(z)
	Wave  wActualplane=$actualplane
	
	if(z==0)
		Newimage  wActualplane
		doWindow/c Graph102	

		nvar folder
		
		folder=0
		
		AutoROIImgProcSweptField()
	
		killwindow  Graph102
		killwaves wactualplane
	
	elseif((z>=1) ) 
		
		folder=z
		
		newimage wActualplane
		doWindow/c Graph102	
		
		WMRoiDrawButtonProc3("FinishROI")
	
		killwindow  Graph102
		killwaves wactualplane	
		
	endif

endfor

if(WaveExists(BackgroundROI)==0)

killwaves backgroundROI

endif

DoWindow/K WMImageROIPanel //Close panel that controls Background ROI drawing

End



//////////////////////////////////////////////////////////////


Function AutoROIImgProcSweptField() ///

//This macro automatically generates ROIs after creating a background ROI and
//defining and exterior circle and an inner one covering the cellular surface.


//Generate Panel Which controls Background-ROI drawing
 
variable/g file, NTotImgs, Nsweeps, folder
variable/g DepoImgs,EffImgs
variable/g x0,y0,rint,rext,angle
variable/g criteria
variable/g integral
variable/g ThresholdMin,ThresholdMax

 
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
	
	NewPanel /K=1/W=(0,250,595,505) as "ROI Creation Parameters"
	DoWindow/C WMImageROIPanel
	AutoPositionWindow/E/M=1/R=$igName
	ModifyPanel fixedSize=1
	Button StartROI,pos={14,9},size={150,20},proc=WMRoiDrawButtonProc3,title="Start Background-ROI Draw"
	Button StartROI,help={"Adds drawing tools to top image graph. Use rectangle, circle or polygon."}
	Button clearROI,pos={14,63},size={150,20},proc=WMRoiDrawButtonProc3,title="Erase ROI"
	Button clearROI,help={"Erases previous ROI. Not undoable."}
	Button FinishROI,pos={14,35},size={150,20},proc=WMRoiDrawButtonProc3,title="Finish Background-ROI"
	Button FinishROI,help={"Click after you are finished editing the ROI"}
	DrawText 52,90,"FILE PROPERTIES"
	DrawText 229,90,"LOCATION PROPERTIES"
	DrawText 420,90,"ANALYSIS PARAMETERS"
	
	Groupbox Fileprop, pos={19,68},size={176,179}
	Groupbox Location, pos={209,68},size={176,179}
	Groupbox Analysis, pos={398,68},size={176,179}
	
	SetVariable FILE,pos={47,97},size={109,15},title="FILE:",value= file
	SetVariable folder,pos={47,97},size={109,15},title="FOLDER:", value= folder
	SetVariable NTotImgs,pos={47,97},size={109,15},title="TOTAL IMAGES:", value= ntotimgs
	SetVariable Nsweeps,pos={47,97},size={109,15},title="TOTAL SWEEPS:", value= nsweeps
	
	
	SetVariable DepoImgs,pos={47,67},size={109,15},title="# Depo Images",value= DepoImgs
	SetVariable EffImgs,pos={47,67},size={109,15},title="# Eff Images", value= EffImgs
	
	SetVariable rint,pos={47,67},size={109,15},title="Inner Radius:", value= rint
	SetVariable rext,pos={47,67},size={109,15},title="External Radius:", value= rext
	SetVariable angle,pos={47,67},size={109,15},title="Angle:",value= angle
	SetVariable criteria,pos={47,67},size={109,15},title="Peak Criteria:", value= criteria
	SetVariable Integral,pos={47,67},size={109,15},title="Integral Criteria:", value= integral
	SetVariable ThresholdMin,pos={47,67},size={109,15},title="Threshold Min:", value= ThresholdMin
	SetVariable ThresholdMax,pos={47,67},size={109,15},title="Threshold Max:", value= ThresholdMax
	CheckBox zeroRoiCheck,pos={15,90},size={94,14},title="Zero ROI Pixels",value= 1
	//CheckBox TrainDepo,pos={25,90},size={94,14},title="Train/Depo",value= 1
	
	Button StartROI,pos={33,7},size={150,20},proc=WMRoiDrawButtonProc3,title="Start Background-ROI Draw"
	Button StartROI,help={"Adds drawing tools to top image graph. Use rectangle, circle or polygon."}
	Button clearROI,pos={409,7},size={150,20},proc=WMRoiDrawButtonProc3,title="Erase ROI"
	Button clearROI,help={"Erases previous ROI. Not undoable."}
	Button FinishROI,pos={222,7},size={150,20},proc=WMRoiDrawButtonProc3,title="Finish Background-ROI"
	Button FinishROI,help={"Click after you are finished editing the ROI"}
	
	SetVariable FILE,pos={40,105},size={135,16},title="FILE:"
	SetVariable folder,pos={39,142},size={135,16},title="FOLDER:"
	SetVariable NTotImgs,pos={39,179},size={135,16},title="TOTAL IMAGES:"
	SetVariable Nsweeps,pos={39,216},size={135,16},title="TOTAL SWEEPS:"
	SetVariable DepoImgs,pos={231,105},size={135,16},title="# Depo Images:" 
	SetVariable EffImgs,pos={232,133},size={135,16},title="# Eff Images:"
	SetVariable rint,pos={232,161},size={135,16},title="Inner Radius:"
	SetVariable rext,pos={232,189},size={135,16},title="External Radius:"
	SetVariable angle,pos={232,217},size={135,16},title="Angle:"
	SetVariable criteria,pos={420,105},size={135,16},title="Peak Criteria:"
	SetVariable Integral,pos={420,142},size={135,16},title="Integral Criteria:"
	SetVariable ThresholdMin,pos={420,179},size={135,16},title="Threshold Min:"
	SetVariable ThresholdMax,pos={420,216},size={135,16},title="Threshold Max:"
	
	CheckBox zeroRoiCheck,pos={436,50},size={92,10},title="Zero ROI Pixels"
	CheckBox zeroRoiCheck,value= 1

	CheckBox DoMovie,pos={436,32},size={92,10},title="Average Images"
	CheckBox Domovie,value= 0
		
	PopupMenu ExperimentType,pos={20,39},size={209,19},title="Experiment:"
	PopupMenu ExperimentType,value= #"\"Efferent Stimulation;Depolarization;Train Stimulation\""
		
	PopupMenu AnalysisMode,pos={215,39},size={209,19},title="Analysis Output:"
	PopupMenu AnalysisMode,value= #"\"Delta F\F0;Delta F\""
	
	CheckBox AutoCenterDEtermination,pos={401,50},size={92,10},title="Automatic Center Determination"
	CheckBox AutoCenterDEtermination,value= 1
	
	PauseForUser  WMImageROIPanel
	
end

//Launch panel functions

Function WMRoiDrawButtonProc3(ctrlName) : ButtonControl
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
	
	if( CmpStr(ctrlName,"StartROI") == 0 )
		ShowTools/A  oval
		SetDrawLayer ProgFront
		setdrawenv fillpat=0,linefgc=(0,52224,0)
		SetDrawEnv gstart,gname=ROIoutline
	endif
	
	
if( CmpStr(ctrlName,"FinishROI") == 0 ) 
	
	drawaction/l=progfront getgroup=ROIoutline, commands //genera S_recreation con lo dibujado
	GraphNormal
	HideTools/A
	
	nvar z
	
	if(z==0)
		ControlInfo/w=WMImageROIPanel Domovie
		variable/g v_domovie = V_value 
	
		ControlInfo/w=WMImageROIPanel Experimenttype
		variable/g v_experimenttype = V_value 
	
		ControlInfo/w=WMImageROIPanel AnalysisMode
		variable/g v_AnalysisMode = V_value 

		ControlInfo/w=WMImageROIPanel AutoCenterDEtermination
		variable/g v_autocenter = V_value 
	
	else
	
	variable/g v_domovie
	variable/g v_experimenttype
	variable/g v_AnalysisMode
	variable/g v_autocenter
		
	endif
	
//Define file, total number of images acquired for that file and number of sweeps

	nvar file, NTotImgs, Nsweeps, folder
	String sFolder= "File_"+num2str(file)+"_plane_"+num2str(Folder)	////generates The folder where all the waves will be stored in case you want to perform multiple analysis
	
	if( DataFolderExists(sFolder) == 0)
	NewDataFolder  $sFolder
	
	else
			DoAlert 0,"Version Number Exists"
			return 0	
			
	endif
		
	
//gets top Image where you`ve drawn the background ROI
		
	String topWave=WMGetImageWave1(WMTopImageGraph1()) 
	WAVE/Z ww=$topWave
	
		if(WaveExists(ww)==0)
			return 0
		endif
	
	String saveDF=GetDataFolder(1)
	String waveDF=GetWavesDataFolder(ww,1 )
	SetDataFolder waveDF
	
	ControlInfo zeroRoiCheck
	
//Generate ROI Mask

		if(WaveExists(BackgroundROI)==0)
	
			if(V_value)
				ImageGenerateROIMask/E=1/I=0 $WMTopImageName1()		
			else
				ImageGenerateROIMask/E=1/I=0 $WMTopImageName1()		
			endif
	
			SetDataFolder saveDF
			
			
			///draw ROI in Userfront and erase it from Progfront
		
			String Q= stringfromlist(4,s_recreation)
			execute "drawaction/l=progfront delete"
			SetDrawLayer UserFront
			setdrawenv fillpat=0,linefgc=(0,52224,0)
			execute/p Q
	
		endif


		
////////////////////////////Create Background wave

nvar file, NTotImgs, Nsweeps
variable/g DepoImgs,EffImgs
nvar x0,y0,rint,rext,angle
nvar criteria
nvar integral
nvar ThresholdMin,ThresholdMax

SVAR S_fileName
String sImgName
String ImgN
string IndexFileName = WMTopImageName1()[4,11]
Variable j,i ////j counts number of sweeps and i counts number of image

////////////////////////Create Background wave

				if(WaveExists(BackgroundROI)==0)

					wave M_ROIMask

				elseif (WaveExists(BackgroundROI)==1)
			
					duplicate/o BackgroundROI,M_ROIMask
				
				endif	



string sImgStackback = "Img"+IndexfileName+"_"+num2str(file)+".tif_Plane_"+num2str(folder)
wave wImgstackback=$sImgStackback	


	String sBackROI = "Back_"+num2str(file)
	Make/O/N=(NTotImgs) $sBackROI
	Wave wbackROI = $sBackROI
		
Make/WAVE/o/N=(NtotImgs) wawback

MultiThread wawback=Worker(wImgStackback,p,M_ROIMask) //////// Multi-thread Function that allows to calculate the average ROI pixel value  using multiple processors.

WAVE w= wawback[0]
Duplicate/O w, wbackROI // w contains references to Free Data Folders that save the average ROI pixel value 

Variable h /// h represents the number of image to be analyzed by worker
for(h=1; h<ntotimgs; h+=1) 
wave w= wawback[h] // Get a reference to the next free data folder
concatenate/NP {w}, wbackROI
endfor

// wawback holds references to the free data folders. By killing wawback,
// we kill the last reference to the free data folders which causes
// them to be automatically deleted. Because there are no remaining
// references to the various M_ImagePlane waves, they too are automatically deleted.

KillWaves wawback

string BackROIMask="ROIMask_"+num2str(file)+"_Back"
duplicate/o M_ROIMask, $BackROIMask
duplicate/o M_ROIMask, BackgroundROI

DoWindow/K WMImageROIPanel //Close panel that controls Background ROI drawing
MoveWave $BackROIMask, :$(sFolder):

///////////////////////////////////PARTICLE ANALYSIS AND CENTER DETERMINATION FOR EACH PLANE


SVAR Currentfilename	
Svar IndexCurrFileName

string sImgStack = "Img"+IndexfileName+"_"+num2str(file)+".tif_Plane_"+num2str(folder)
wave wImgstack=$sImgStack

variable pixelswide=dimsize($sImgStack,0) 
variable pixelsheight=dimsize($sImgStack,1)

imagetransform averageimage  wImgstack

ImageThreshold/I/M=(1)/Q root:M_AveImage

String sAverageImage="AverageImage_"+num2str(file)    ////Creation of an averaged image of all the images in that file

Duplicate/O M_AveImage, $sAverageImage; KillWaves M_AveImage

Wave  wAverageImage=$sAverageImage
wave M_ImageThresh
  
ImageMorphology/O/E=(5)/I=(1) BinaryErosion, M_ImageThresh
 ImageAnalyzeParticles /E/W/Q/M=3/A=5/EBPC stats, M_ImageThresh

wave M_moments

X0= M_moments[0][0]
Y0= M_moments[0][1] 


String sROIMasksThreshold="M_ImageThresh"
Wave  wROIMasksThreshold=$sROIMasksThreshold


wROIMasksThreshold /= 255
wROIMasksThreshold-=1
wROIMasksThreshold*=(-1)

ImageMorphology/E=(5)/I=(3) BinaryErosion, M_ImageThresh

wave M_imagemorph
 M_imagemorph/=255

wROIMasksThreshold-= M_imagemorph

killwaves m_imagemorph

///////////////////////DEFINE INTERIOR AND EXTERIOR CIRCLES

SetDrawLayer UserFront
SetDrawEnv xcoord= top,ycoord= left,save
showtools
setdrawenv fillpat=0,linefgc=(58880,19712,6656),save

string outercircle="drawarc/x/Y "+ num2str(x0)+","+num2str(y0)+","+num2str(rext)+",0,360"
string Innercircle="drawarc/x/Y "+ num2str(x0)+","+num2str(y0)+","+num2str(rint)+",0,360"

execute Innercircle
execute outercircle

///////////////////////Draw triangles based in the given angle

Variable K=0//K counts de number of triangles needed to complete the circle


for(K=0;K<(360/angle);K+=1) 

string nROI=num2str(k+1)

GraphNormal
HideTools/A
SetDrawLayer ProgFront
SetDrawEnv xcoord= top,ycoord= left,save

setdrawenv fillpat=0,linefgc=(0,52224,0),save
drawpoly x0,y0,1,1,{x0,y0,x0+Rext*cos(k*angle*2*pi/360),y0+Rext*sin(k*angle*2*pi/360),x0+Rext*cos(angle*2*pi/360+2*pi*angle*k/360),y0+Rext*sin(angle*2*pi/360+2*pi*angle*k/360),x0,y0}					

setdrawenv fillpat=-1,linefgc=(0,52224,0),save
execute Innercircle
	
		ImageGenerateROIMask/E=0/I=1 $sImgStack	///generates the Mask for that ROI 

Wave M_ROIMask

String sROIMasks="ROIMasks_"+num2str(file)                           
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



//////////////////////Generates the wave that contains the average of that ROI for all the images

String sROI = "ROI_"+num2str(file)+"_"+nROI
	Make/O/N=(NTotImgs) $sROI
	Wave wROI = $sROI 
	
sImgStack = "Img"+IndexfileName+"_"+num2str(file)+".tif_Plane_"+num2str(folder)
	wave wImgstack=$sImgStack

Make/WAVE/o/N=(NtotImgs) waw
		
MultiThread waw=Worker(wImgStack,p,M_ROIMask)

WAVE w= waw[0]
Duplicate/O w, wROI


		for(h=1; h<ntotimgs; h+=1)
		
			wave w= waw[h] // Get a reference to the next free data folder
			concatenate/NP {w}, wROI

		endfor

KillWaves waw

wROI-=wbackROI	 	

endfor					


/////////////////////////////////// Generates an image which concatenates the normalization of each ROI for each sweep

String sStackSweepDepo = "StackSweepDepo"               
Make/o/n=(depoImgs,360/angle) $sStackSweepDepo
Wave wStackSweepdepo= $sStackSweepDepo

String sStackSweep = "StackSweep"               
Make/o/n=(EffImgs,360/angle) $sStackSweep
Wave wStackSweep= $sStackSweep

String sConcatenatedSweeps = "ConcatenatedSweeps"
Make/o/n=(NtotImgs,360/angle) $sConcatenatedSweeps
Wave wConcatenatedSweeps= $sConcatenatedSweeps 



for(K=0;K<(360/angle);K+=1) 

nROI=num2str(k+1)
sROI = "ROI_"+num2str(file)+"_"+nROI
wave wROI = $sROI 

	  /// Calculates deltaF or deltaF/F for each ROI and each Sweeps and generates a Stack of sweeps

		for(i=0;i<(depoimgs);i+=1)	
		
				if(v_analysismode==1)
					wStackSweepdepo [i][K]= (wROI[i] - wROI[0]) /wROI[0]   
	
				elseif(v_analysismode==2)
					wStackSweepdepo [i][K]= (wROI[i] - wROI[0])
	
				endif

			endfor
		
		
			
		for(i=depoimgs;i<(NtotImgs);i+=1)	
		
				if(v_analysismode==1)
					wStackSweep [i-depoimgs][K]= (wROI[i] - wROI[depoimgs]) /wROI[depoimgs]   
	
				elseif(v_analysismode==2)
					wStackSweep [i-depoimgs][K]= (wROI[i] - wROI[40])
	
				endif

		endfor
			
	
endfor

duplicate wStacksweepDepo, DepoFiltered
MatrixFilter/N=5 avg DepoFiltered

duplicate wStacksweep, EffFiltered
MatrixFilter/N=5 avg EffFiltered

Duplicate/O Depofiltered, wConcatenatedSweeps
Concatenate /NP=0  {EffFiltered}, wConcatenatedSweeps

killwaves EffFiltered, Depofiltered


///////////////////////////////Este bloque analiza en multiples nucleos cada sweep de cada ROI y extrae el baseline,desviacion estandar y maximo(Detection)

string sDetection="Detection"	//////generate a 2D wave that shows the peak signal detected in each ROI for each sweep		
make/o/n=(nsweeps,360/angle) $sDetection=0
wave Wdetection=$sDetection

string sAvg="AVG"	//////generate a 2D wave that shows the baseline signal detected in each ROI for each sweep		
make/o/n=(nsweeps,360/angle) $sAVG=0
wave WAVG=$sAVG

string sSDEV="SDEV"	//////generate a 2D wave that shows the sdev of the imaging signal detected in each ROI for each sweep		
make/o/n=(nsweeps,360/angle) $sSDEV=0
wave WSDEV=$sSDEV		

string sIntegralArea="Integral_Area"	//////generate a 2D wave that shows the integral of the imaging signal detected in each ROI for each sweep		
make/o/n=(nsweeps,360/angle) $sIntegralArea=0
wave WIntegralArea=$sIntegralArea	

string sROIConcatenatedSweeps="ROIConcatenatedSweeps"
make/o/n=(NTotImgs) $sROIConcatenatedSweeps
wave wROIConcatenatedSweeps=$sROIConcatenatedSweeps

string sSumImaging="SumImaging"  ////// this wave will show the the sum of the signal of all the ROIs for each sweep
make/o/n=(nsweeps) $sSumImaging 
wave WSumImaging=$sSumImaging
wSumImaging=0

string sAreaImaging="areaImaging"  ////// this wave will show the the sum of the signal of all the ROIs for each sweep
make/o/n=(nsweeps) $sareaImaging 
wave WareaImaging=$sareaImaging
wareaImaging=0

string sDataFile="DataFile_"+num2str(file)
wave wDataFile=$sDataFile

for(K=0;K<(360/angle);K+=1) 	

	wROIConcatenatedSweeps[] = wConcatenatedSweeps[p][k]
	
	variable countersuccesimaging=0,counterfailimaging=0
	
	Make/WAVE/o/N=(nsweeps) waw3
	
	MultiThread waw3=Worker4(wROIConcatenatedSweeps,wdatafile,folder,p,ntotImgs,nsweeps,criteria,integral,depoImgs,EffImgs) ///Analiza en una funcion multithread la existencia de picos en la señal de cada ROI y calcula su amplitud e integral. 
 
 
	WAVE w3= waw3[0]
	
	wdetection[0][k]=w3[0]
	wIntegralArea[0][k]=w3[3]
		
		for(h=1; h<nsweeps; h+=1)
		
			wave w3= waw3[h] 
			wDetection[h][k]= w3[0]
			
			wAVG[h][k]=w3[1]
		
			wSDEV[h][k]=w3[2]
		
			wIntegralArea[h][k]=w3[3]
		
		endfor

	KillWaves waw3
	KillWaves w3

	
nROI=num2str(k+1)
sROI = "ROI_"+num2str(file)+"_"+nROI
Wave wROI = $sROI 
killwaves wRoi
////moveWave :$sROI, :$(sFolder):	

endfor ///// endfor del loop de K=nROI


////////////////////////////////////////////

killwaves wconcatenatedsweep, wAVG,wSDEV

MoveWave :$sIntegralarea, :$(sFolder):

MoveWave :$sROIMasks, :$(sFolder):
MoveWave :$sROIMasksThreshold, :$(sFolder):
MoveWave :$sstacksweep, :$(sFolder):
MoveWave :$sstacksweepdepo, :$(sFolder):
MoveWave $sBackROI, :$(sFolder):
MoveWave :$sDetection, :$(sFolder):
MoveWave $sAverageImage, :$(sFolder):

string/G AutoROIAnalVar="X0="+num2str(x0)+";Y0="+num2str(y0)+";Rint="+num2str(rint)+"Rext="+num2str(rext)+"Angle="+num2str(angle)+"criteria="+num2str(criteria)+"integral="+num2str(integral)
movestring AutoROIAnalVar, :$(sFolder):


GraphNormal
SetDrawLayer UserFront
SetDrawEnv xcoord= prel,ycoord= prel, save
HideTools/A

endif

//killwaves Waverageimage, thresholdwave, baselineimage, DI_calcwave

end

 
  
///////////////

ThreadSafe Function/wave Worker4(wROIConcatenatedSweeps,wDataFile,folder,plane,ntotImgs,nsweeps,criteria,integral,depoImgs,EffImgs) //// calculates the average of each ROI for all the file's images

WAVE wROIConcatenatedSweeps,wDatafile
Variable folder,plane, ntotImgs,nsweeps,criteria,integral,depoImgs,EffImgs


DFREF dfSav= GetDataFolderDFR()
SetDataFolder NewFreeDataFolder()
 


make/free/o/n=(5) wdata

if(plane==0)

WaveStats/Q/R=(1, Wdatafile[folder][2]-Wdatafile[folder][1]) wROIConcatenatedSweeps // Genera baseline
wdata[1]=V_avg
wdata[2]=V_sdev


FindPeak/B=5/P/Q/R=(Wdatafile[folder][2]-Wdatafile[folder][1],15+Wdatafile[folder][2]-Wdatafile[folder][1]) wROIConcatenatedSweeps	
wdata[0]=V_peakval - V_avg

variable XPico=V_PeakLoc

make/free/o/n=(ntotimgs) IntBaseline=V_avg
wdata[3] = area (wROIConcatenatedSweeps,Wdatafile[folder][2]-Wdatafile[folder][1],20+Wdatafile[folder][2]-Wdatafile[folder][1] ) - area(Intbaseline,Wdatafile[folder][2]-Wdatafile[folder][1],20+Wdatafile[folder][2]-Wdatafile[folder][1]) ///Integra desde el punto 10 al 30

else

WaveStats/Q/R=(depoImgs+1, Wdatafile[folder][3]-Wdatafile[folder][1]) wROIConcatenatedSweeps // Genera baseline
wdata[1]=V_avg
wdata[2]=V_sdev


FindPeak/B=5/P/Q/R=(Wdatafile[folder][3]-Wdatafile[folder][1],15+Wdatafile[folder][3]-Wdatafile[folder][1]) wROIConcatenatedSweeps	
wdata[0]=V_peakval - V_avg

XPico=V_PeakLoc

make/free/o/n=(ntotimgs) IntBaseline=V_avg
wdata[3] = area (wROIConcatenatedSweeps,Wdatafile[folder][3]-Wdatafile[folder][1],20+Wdatafile[folder][3]-Wdatafile[folder][1]) - area(Intbaseline,Wdatafile[folder][3]-Wdatafile[folder][1],20+Wdatafile[folder][3]-Wdatafile[folder][1]) ///Integra desde el punto 10 al 30


endif


if((wdata[0] >= wdata[2]*criteria) && (wdata[3]>=Integral))

	wdata[0]=V_peakval - V_avg

	if(numtype(xpico)<2) 
	
		wave W_coef

	endif



else

wdata[0]=0

endif


SetDataFolder dfSav

return  wdata

End




//////////////////



Function SyncingSweeps(totplanes,file)

variable totplanes,file


LoadWave/q/o/J/B="C=1,F=0,T=2,W=20,N='_skip_';  C=1,F=0,W=16,T=4,N=TimeCapture; C=1,F=0,W=16,T=4,N=index; C=1,F=0,W=16,T=4,N=PiezoZ; C=1,F=0,W=16,T=4,N=PiezoZdecimal; C=4,F=0,W=16,T=4,N='_skip_'; C=1,F=-2,W=16,T=4,N=Events;  C=4,F=0,W=16,T=4,N='_skip_';"

	If (v_flag==0)
		return -1
	endif

string sTimecapture= "Timecapture_ "+ num2str(file)

duplicate/o Timecapture, $stimecapture

killwaves timecapture
	
wave/t events

variable i

variable v_value=3
variable IndexsweepStart, IndexStimuliDepo, IndexStimuliEff,Position


string sSweep="DataFile_"+num2str(file)
Make/o/n=(totplanes,5) $sSweep
wave Sweeps=$sSweep

wave Index, PiezoZ,PiezoZdecimal

string text1= "User 5"
string text2= "User 6"



For(i=0;i<totplanes;i+=1)

Sweeps[i][0]=i

FindValue/s=(V_value+1)/Text=(text1)  events
IndexSweepStart= Index[V_value+2] 
Sweeps[i][1]=IndexSweepStart

Position =PiezoZ[V_value+2]+PiezoZdecimal[V_value+2]/100
Sweeps[i][4]=Position


FindValue/s=(V_value+1)/Text=(text2) events
IndexStimuliDepo = Index[V_value-1]
Sweeps[i][2]=IndexStimuliDepo

FindValue/s=(V_value+1)/Text=(text2) events
IndexStimuliEff =Index[V_value-1]
Sweeps[i][3]=IndexStimuliEff


endfor

killwaves index,events,piezoZ,PiezoZdecimal

end


///////////////////////////////////////////////////////////////////


Function ConcatenadoPlanos()


variable totalfiles, firstfile

	prompt totalfiles, "Total files:"
	prompt firstfile,"First File number:"
	DoPrompt "List Files", totalfiles, firstfile

	If (v_flag)
		return -1
	endif

Variable F

variable j

variable i


string folderDir= datafolderdir(1)

for(f=firstfile;f<totalfiles;f+=1)

variable Total= ItemsInList (ListMatch(folderdir, "File_"+num2str(f)+"*", ","),",")

string lastfolder= "File_"+num2str(totalfiles+firstfile+1)+"_plane_"

newdatafolder/o $lastfolder 

 For(j=0;j<total;j+=1)
 
String  Folder ="root:"+StringFromList(j, ListMatch(folderdir, "File_"+num2str(f)+"*", ","),",") + ":"

setdatafolder Folder

string sROIMasks= "ROIMasks_"+num2str(f)
wave wROIMasks=$sROIMasks

wave Integral_area, Detection

Wave wSweep=StackSweep
Wave wSweepDepo=StackSweepDepo


string splanoArea="Plano_Area_"+num2str(f)+"_"+num2str(j)
string splanoAreaDEpo="Plano_AreaDepo_"+num2str(f)+"_"+num2str(j)
string splanoAmp="Plano_Amp_"+num2str(f)+"_"+num2str(j)
string splanoAmpDepo="Plano_AmpDepo_"+num2str(f)+"_"+num2str(j)

string Renamesweep= "StackSweep_"+num2str(f)+"_"+num2str(j)
string Renamesweepdepo= "StackSweepdepo_"+num2str(f)+"_"+num2str(j)


variable row=dimsize(wROIMasks,0)
variable col=dimsize(wROIMasks,1)
variable TotROIs=dimsize(wROIMasks,2)

Duplicate/o wROIMasks, DupROIMaskArea
Duplicate/o wROIMasks, DupROIMaskAreaDepo
Duplicate/o wROIMasks, DupROIMaskAmp
Duplicate/o wROIMasks, DupROIMaskAmpDepo

duplicate/o wsweep,$renamesweep
duplicate/o wsweepdepo, $renamesweepdepo


DupROiMaskarea-=1
DupROiMaskarea*=(-1)

DupROiMaskareadepo-=1
DupROiMaskareadepo*=(-1)

DupROiMaskamp-=1
DupROiMaskamp*=(-1)

DupROiMaskampdepo-=1
DupROiMaskampdepo*=(-1)

Make/o/n=(row,col) $splanoarea=0
wave Planoarea=$splanoarea

Make/o/n=(row,col) $splanoareadepo=0
wave Planoareadepo=$splanoareadepo

Make/o/n=(row,col) $splanoamp=0
wave PlanoAmp=$splanoamp

Make/o/n=(row,col) $splanoampdepo=0
wave Planoampdepo=$splanoampdepo

for(i=0;i<totROIs;i+=1)

	Planoampdepo+=(DupROIMaskAmpDepo[p][q][i]*Detection[0][i])
	Planoamp+=(DupROIMaskAmp[p][q][i]*Detection[1][i])
	Planoareadepo+=(DupROIMaskAreaDEpo[p][q][i]*Integral_area[0][i])
	Planoarea+=(DupROIMaskArea[p][q][i]*Integral_Area[1][i])

endfor

KillWaves DupROIMaskarea
KillWaves DupROIMaskareadepo
KillWaves DupROIMaskamp
KillWaves DupROIMaskampdepo


MoveWave planoamp, root: 
MoveWave planoampdepo, root: 
MoveWave planoarea, root: 
MoveWave planoareadepo, root: 

MoveWave $renamesweep, root: 
MoveWave $renamesweepdepo, root:

setdatafolder root: 

Wave wrenamesweep=$renamesweep
Wave wrenamesweepdepo=$renamesweepdepo

concatenate/np=0 {wrenamesweep} ,Concatenadosweep
concatenate/np=0 {wrenamesweepdepo} , concatenadosweepdepo


concatenate/np=2 { planoamp } , Concatenadoamp
concatenate/np=2 {planoampdepo}, concatenadoampdepo
concatenate/np=2 {planoarea}, concatenadoarea
concatenate/np=2 {planoareadepo}, caoncatenadoareadepo

killwaves planoamp 
killwaves planoampdepo
killwaves planoarea
killwaves planoareadepo

killwaves wrenamesweep
killwaves wrenamesweepdepo



endfor


endfor
killdatafolder $lastfolder


end



/////////////////////////////////////////////////////////////////////////////////////////////////////

Function ImagenRespuesta()

String  FirstImage
variable totalfiles,totplanes


	Prompt FirstImage, "First File Source Image:", popup Wavelist("Img*", ";", "")
	prompt totalfiles, "Total files:"
	prompt totplanes, "Planes per file:"
	DoPrompt "List Files",FirstImage, totalfiles, totplanes

	If (v_flag)
		return -1
	endif


variable z=0

variable f

wave wfirstimage=$firstimage

string name= FirstImage[0,11] 

variable firstfile= str2num(FirstImage[12,13])

	variable Rows=dimsize (wFirstImage, 0) 
	variable columns= dimsize (wFirstImage, 1)
	
	Make/o/n=(rows,columns,totplanes*totalfiles) Respuesta
		Make/o/n=(rows,columns,totplanes*totalfiles) RespuestaDepo
		

for(f=firstfile;f<(totalfiles+firstfile);f+=1)

	string soriginal= name+num2str(f)+".tif"

	duplicate/o $soriginal,original

	wave original
	
	string Datos="datafile_"+num2str(f)

	If (waveexists ($datos)==0)

	SyncingSweeps(totplanes,f)

	endif

	 wave wDatos=$datos


	variable j



	wave respuesta
	wave respuestadepo

	variable i

			For(z=0;z<totplanes;z+=1)
				Make/o/n=(rows,columns) Basal=0
				wave basal	
				Make/o/n=(rows,columns) Basaldepo=0
				wave basaldepo		
				Make/o/n=(rows,columns) pico=0
				wave pico	
				Make/o/n=(rows,columns) picodepo=0
				wave picodepo	
	
	
							for(i=0;i<5;i+=1)		
					
									imagetransform/p=(wdatos[z][3]-1-5+i) getplane original 
									wave M_imageplane
									basal[][]+=M_imageplane
		
							endfor
	
	
							for(i=0;i<5;i+=1)	
	
									imagetransform/p=(wdatos[z][2]-8+i) getplane original 
									basaldepo[][]+=M_imageplane
			
							endfor
	
	
							for(j=0;j<7;j+=1)		
			
									imagetransform/p=(wdatos[z][3]+1+j) getplane original 
									pico[][]+=M_imageplane
			
							endfor
	
		
							for(j=0;j<3;j+=1)		

									imagetransform/p=(wdatos[z][2]+j-1) getplane original 
									picodepo[][]+=M_imageplane
	
							endfor
	

				basal/=5 
				basaldepo/=5
	
				pico/=7
				picodepo/=3
	
				respuesta[][][z+(f-firstfile)*(totplanes)] =pico[p][q] - basal[p][q]
				Respuestadepo[][][z+(f-firstfile)*(totplanes)]= picodepo[p][q] - basaldepo [p][q]
	
				endfor


		endfor

End


//////////////////////////////////////////////////////

Function NormalizeImages()

wave respuestadepo
wavestats Respuestadepo

Variable min=V_min
	Variable delta=1.0/(V_max-V_min)
	Variable deltaM


	delta*=65535
			deltaM=delta*min
			make/o/n=(100,100,40) respuestadeponormalizada=round((delta)*respuestadepo-(deltaM))
			
						

wave respuesta


wavestats Respuesta

 min=V_min
delta=1.0/(V_max-V_min)


	delta*=65535
			deltaM=delta*min
			make/o/n=(100,100,40) respuestanormalizada=round((delta)*respuesta-(deltaM))


end


////////////////////////////////////////////


/// PROCEDIMIENTO:

/// Exportar desde el el archivo de imagenes .nd2 todo el "Image Properties"--->"Recorded Data" a un txt
//// Cargar los datos enm Igor usando la funcion SyncingSweepsSinglePulse(totplanes,file) , en la cual totaplanes= # imagenes
//// Esta funcion genera un 2 waves: 
      //----->>>Timecapture: Tiene la informacion del tiempo en el que se da cada image
      //----->>>DataFile: es un wave multidimensional en el que cada columna representa para cada sweep:
                   ///            1- Numero de sweep
                   ///            2- numero de Imagen Inicial
                   ///            3- 0
                   ///            4- Imagen en la cual se produce el estimulo eferente

Function SyncingSweepsSinglePulse()  ////Crea la wave con los tiempos de cada imagen a partir del txt exportado de la imagen. 
															///// Tambien genera un wave con el numero de imagen en el que ocurre el estimulo.

variable totsweeps,imgpersweep,file

	Prompt totsweeps, "Sweeps Totales"
	prompt imgpersweep, "Imagenes por sweep:"
	prompt file, "Numero de File:"
	
	
	
	DoPrompt "", totsweeps,imgpersweep,file

	If (v_flag)
		return -1
	endif
	





LoadWave/q/o/J/B="C=1,F=0,T=2,W=20,N='_skip_';  C=1,F=0,W=16,T=4,N=TimeCapture; C=1,F=0,W=16,T=4,N=index; C=1,F=0,W=16,T=4,N=PiezoZ; C=1,F=0,W=16,T=4,N=PiezoZdecimal; C=4,F=0,W=16,T=4,N='_skip_'; C=1,F=-2,W=16,T=4,N=Events;  C=4,F=0,W=16,T=4,N='_skip_';"

	If (v_flag==0)
		return -1
	endif

string sTimecapture= "Timecapture_ "+ num2str(file)

duplicate/o Timecapture, $stimecapture

wave timecapture

	
wave/t events

variable i

variable v_value=2
variable IndexsweepStart, IndexStimuliEff,Position,initimg


string sSweep="DataFile_"+num2str(file)
Make/o/n=(totsweeps,5) $sSweep
wave Sweeps=$sSweep

wave Index, PiezoZ,PiezoZdecimal

string text1= "User 5"
string text2= "User 6"


string sTimewave= "Timewave_"+ num2str(file)
make/o/n=(imgpersweep*totsweeps) $sTimewave=0

wave wTimewave= $sTimewave

variable j=0, K=1


variable totalrows= dimsize (PiezoZ,0)



For(k=2;k<totalrows;k+=1)
		
		if(numtype(PiezoZ[K])==0)	
	
				if(timecapture[K]>=3000)	
	
					timecapture[K] =(timecapture[K-1]+timecapture[K+1])/2
	
					j+=1
			
				ENDIF
		
	
			wTimewave[j]=timecapture[K]
	
			j+=1
			
		ENDIF
		

endfor			



For(i=0;i<totsweeps;i+=1)

Sweeps[i][0]=i



if(i==0)

Sweeps[i][1]=imgpersweep*i


FindValue/s=(5)/Text=(text2) events
IndexStimuliEff =Index[V_value-1]
Sweeps[i][2]=IndexStimuliEff-2

else

Sweeps[i][1]=imgpersweep*i

FindValue/t=2/v=(imgpersweep*i+2) index
initimg=V_value


FindValue/s=(initimg)/Text=(text2) events
IndexStimuliEff =Index[V_value-1]
Sweeps[i][2]=IndexStimuliEff-2

Position =PiezoZ[V_value+2]+PiezoZdecimal[V_value+2]/100
Sweeps[i][3]=Position

endif
endfor

killwaves timecapture

killwaves index, events,piezoZ,PiezoZdecimal

end



///////////////////////////


Function concatenateephys()

string nfailures, amplitudewave, HwWAve,TauDecay,tau_90_10,time_90_10, QWave,TauQWave

nfailures=WaveList("nfailures*", ";", "") 
amplitudewave=WaveList("amplitudewave*", ";", "") 
HwWAve=WaveList("HwWAve*", ";", "") 
TauDecay=WaveList("TauDecay*", ";", "") 
tau_90_10=WaveList("tau_90_10*", ";", "") 
time_90_10=WaveList("time_90_10*", ";", "") 
QWave=WaveList("QWave*", ";", "") 
TauQWave=WaveList("TauQWave*", ";", "") 


variable totalfiles= ItemsInList(amplitudewave)

make/o/n=1 nFailures_100=0
wave nFailures_100

variable index,i

for(i=0;i<totalfiles;i+=1)
 
string fa= StringFromList(index, nfailures,";")
string aw= StringFromList(index, amplitudewave,";")
string hww= StringFromList(index, HwWAve,";")
string td= StringFromList(index, TauDecay,";")
string tau9010= StringFromList(index, tau_90_10,";")
string time9010= StringFromList(index, time_90_10,";")
string Q= StringFromList(index, QWave,";")
string TauQ= StringFromList(index, TauQWave,";")


wave wfa =$fa
wave waw =$aw
wave whww =$hww
wave wtd =$td
wave wtau9010 =$tau9010
wave wtime9010 =$time9010
wave wQ =$Q
wave wTauQ =$TauQ

if(waw[0]>1)

nFailures_100+=wfa

else

nFailures_100+=wfa-1

endif


DeletePoints 0, 1, wfa,waw,whww,wtd ,wtau9010,wtime9010,wQ,wTauQ



endfor

amplitudewave=WaveList("amplitudewave*", ";", "") 
HwWAve=WaveList("HwWAve*", ";", "") 
TauDecay=WaveList("TauDecay*", ";", "") 
tau_90_10=WaveList("tau_90_10*", ";", "") 
time_90_10=WaveList("time_90_10*", ";", "") 
QWave=WaveList("QWave*", ";", "") 
TauQWave=WaveList("TauQWave*", ";", "") 


concatenate/np/o amplitudewave,amplitudewave_100
concatenate/np/o HwWAve,HwWAve_100
concatenate/np/o TauDecay,TauDecay_100
concatenate/np/o tau_90_10, tau_90_10_100
concatenate/np/o time_90_10, time_90_10_100
concatenate/np/o QWave,QWave_100
concatenate/np/o TauQWave,TauQWave_100

end


/////////////////////////////////////////////////////////////////

Function AutoImgProcSFSinglePulse() 

//This macro automatically generates ROIs after creating a background ROI and
//defining and exterior circle and an inner one covering the cellular surface.



//Generate Panel Which controls Background-ROI drawing
 
variable/g file, NTotImgs, Nsweeps, folder
variable/g x0,y0,rint,rext,angle
variable/g criteria
variable/g integral
variable/g ThresholdMin,ThresholdMax

 
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
	
	NewPanel /K=1/W=(0,250,595,505) as "ROI Creation Parameters"
	DoWindow/C WMImageROIPanel
	AutoPositionWindow/E/M=1/R=$igName
	ModifyPanel fixedSize=1
	Button StartROI,pos={14,9},size={150,20},proc=WMRoiDrawButtonProcSFSingle,title="Start Background-ROI Draw"
	Button StartROI,help={"Adds drawing tools to top image graph. Use rectangle, circle or polygon."}
	Button clearROI,pos={14,63},size={150,20},proc=WMRoiDrawButtonProcSFSingle,title="Erase ROI"
	Button clearROI,help={"Erases previous ROI. Not undoable."}
	Button FinishROI,pos={14,35},size={150,20},proc=WMRoiDrawButtonProcSFSingle,title="Finish Background-ROI"
	Button FinishROI,help={"Click after you are finished editing the ROI"}
	DrawText 52,90,"FILE PROPERTIES"
	DrawText 229,90,"LOCATION PROPERTIES"
	DrawText 420,90,"ANALYSIS PARAMETERS"
	
	Groupbox Fileprop, pos={19,68},size={176,179}
	Groupbox Location, pos={209,68},size={176,179}
	Groupbox Analysis, pos={398,68},size={176,179}
	
	Button StartROI,pos={33,7},size={150,20},proc=WMRoiDrawButtonProcSFSingle,title="Start Background-ROI Draw"
	Button StartROI,help={"Adds drawing tools to top image graph. Use rectangle, circle or polygon."}
	Button clearROI,pos={409,7},size={150,20},proc=WMRoiDrawButtonProcSFSingle,title="Erase ROI"
	Button clearROI,help={"Erases previous ROI. Not undoable."}
	Button FinishROI,pos={222,7},size={150,20},proc=WMRoiDrawButtonProcSFSingle,title="Finish Background-ROI"
	Button FinishROI,help={"Click after you are finished editing the ROI to start analysis"}
	
	SetVariable FILE,pos={40,105},size={135,16},title="FILE:",value= file 
		SetVariable FILE,help={"Determine the number of the file to analyze"}
		
	SetVariable folder,pos={39,142},size={135,16},title="VERSION:",value=folder
		SetVariable folder,help={"Determine VERSION # in case you want to perform multiple analysis to the same file"}

	SetVariable NTotImgs,pos={39,179},size={135,16},title="TOTAL IMAGES:",value= ntotimgs
			SetVariable ntotimgs,help={"Determine the total number of images you want to analyze"}

	SetVariable Nsweeps,pos={39,216},size={135,16},title="TOTAL SWEEPS:", value= nsweeps
			SetVariable nsweeps,help={"Determine the total number of sweeps you want to analyze"} // Total Images/Total sweeps will determine the number of images per file
			
	SetVariable x0,pos={231,105},size={135,16},title="X center:",value=x0
			SetVariable x0,help={"X center of the circunference"}	
			
	SetVariable y0,pos={232,133},size={135,16},title="Y center:", value=y0
			SetVariable y0,help={"Y center of the circunference"}		

	SetVariable rint,pos={232,161},size={135,16},title="Inner Radius:", value= rint
				SetVariable rint,help={"Internal radius of the circunference"} //This area will not be analyzed	
	
	SetVariable rext,pos={232,189},size={135,16},title="External Radius:",value= rext
				SetVariable rext,help={"External radius of the circunference"} //This area will set the external limits of the analysis	

	
	SetVariable angle,pos={232,217},size={135,16},title="Angle:",value= angle
			SetVariable angle,help={"Determine circunference angle for each ROI"}  /// This will also determine de number of ROIs ---> 360/angle
	
	SetVariable criteria,pos={420,105},size={135,16},title="Peak Criteria:", value= criteria
			SetVariable criteria,help={"This value determines how many times the STDEV the peak has to be, to be considered an event"}  
	
	SetVariable Integral,pos={420,142},size={135,16},title="Integral Criteria:", value= integral
			SetVariable integral,help={"This value determines the area under the peak so it can be considered an event"}  

	SetVariable ThresholdMin,pos={420,179},size={135,16},title="Threshold Min:",  value= ThresholdMin
			SetVariable ThresholdMin,help={"Minimal relative pixel value threshold"} // All the images in the file are averaged and normalized to the highest pixel value

	SetVariable ThresholdMax,pos={420,216},size={135,16},title="Threshold Max:", value= ThresholdMax
		SetVariable ThresholdMax,help={"Maximal relative pixel value threshold"} 
	
	CheckBox zeroRoiCheck,pos={436,50},size={92,10},title="Zero ROI Pixels"
	CheckBox zeroRoiCheck,value= 1

	CheckBox DoMovie,pos={436,32},size={92,10},title="Average Images"
	CheckBox Domovie,value= 0
		CheckBox domovie, help={"If checked, it will generate a set of images averaging al the sweeps"}
		
	PopupMenu ExperimentType,pos={20,39},size={209,19},title="Experiment:"
	PopupMenu ExperimentType,value= #"\"Efferent Stimulation;Depolarization;Train Stimulation\"" //
		PopupMenu ExperimentType,help={"Efferent Stimulation looks for AmplitudeWave and Ephys waves;Depolarization needs no input;Train Stimulation looks for Ephys waves only"}

	PopupMenu AnalysisMode,pos={215,39},size={209,19},title="Analysis Output:"
	PopupMenu AnalysisMode,value= #"\"Delta F\F0;Delta F\""
	
	CheckBox AutoCenterDEtermination,pos={401,50},size={92,10},title="Automatic Center Determination"
	CheckBox AutoCenterDEtermination,value= 0
	CheckBox AutoCenterDEtermination,help= {"This will determine the center of the circunference by searching the maximum pixel value in the average"}
	
end

//////////////////////////////////Launch panel functions

Function WMRoiDrawButtonProcSFSingle(ctrlName) : ButtonControl
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
	
if( CmpStr(ctrlName,"StartROI") == 0 ) // Press Start Background To Draw a mask for the background
		
		ShowTools/A  oval
		SetDrawLayer ProgFront
		setdrawenv fillpat=0,linefgc=(0,52224,0)
		SetDrawEnv gstart,gname=ROIoutline
	endif
	
	
if( CmpStr(ctrlName,"FinishROI") == 0 ) 
	
	drawaction/l=progfront getgroup=ROIoutline, commands //genera S_recreation con lo dibujado
	GraphNormal
	HideTools/A
	
	ControlInfo/w=WMImageROIPanel Domovie
	variable v_domovie = V_value 
	
	ControlInfo/w=WMImageROIPanel Experimenttype
	variable v_experimenttype = V_value 
	
	ControlInfo/w=WMImageROIPanel AnalysisMode
	variable v_AnalysisMode = V_value 

	ControlInfo/w=WMImageROIPanel AutoCenterDEtermination
	variable v_autocenter = V_value 
	
//Define file, total number of images acquired for that file and number of sweeps
	nvar file, NTotImgs, Nsweeps, folder
	
	String sFolder= "File_"+num2str(file)+"_version_"+num2str(Folder)	////generates The folder where all the waves will be stored in case you want to perform multiple analysis
	
	
	if( DataFolderExists(sFolder) == 0)
	NewDataFolder  $sFolder
	
	else
			DoAlert 0,"Version Number Exists"
			return 0	
			
	endif
	
	
	
//gets top Image where you`ve drawn the background ROI
		
	String topWave=WMGetImageWave1(WMTopImageGraph1()) 
	WAVE/Z ww=$topWave
	if(WaveExists(ww)==0)
		return 0
	endif
	
	String saveDF=GetDataFolder(1)
	String waveDF=GetWavesDataFolder(ww,1 )
	SetDataFolder waveDF
	
	ControlInfo zeroRoiCheck
	
//Generate Background ROI Mask

	if(V_value)
		ImageGenerateROIMask/E=1/I=0 $WMTopImageName1()		
	else
		ImageGenerateROIMask/E=1/I=0 $WMTopImageName1()		
	endif
	
	SetDataFolder saveDF
	
	
////////////////////////////////draw ROI in Userfront and erase it from Progfront which allows to perform multiple drawings and configure different masks without overlapping them.
		
	String Q= stringfromlist(4,s_recreation)
	execute "drawaction/l=progfront delete"
	SetDrawLayer UserFront
	setdrawenv fillpat=0,linefgc=(0,52224,0)
	execute/p Q
		
////////////////////////////Define all the global variables for the rest of the analysis 

nvar file, NTotImgs, Nsweeps, folder
nvar x0,y0,rint,rext,angle
nvar criteria
nvar integral
nvar ThresholdMin,ThresholdMax


//SVAR S_fileName
String sImgName
String ImgN
string IndexFileName = WMTopImageName1()[4,11]

Variable j,i 						////////////////////////////////////////////////  Throughout the macro: j counts number of sweeps and i counts number of image

wave M_ROIMask


////////////////////////Create Background wave

string sImgStackback = "Img"+IndexfileName+"_"+num2str(file)+".tif"
wave wImgstackback=$sImgStackback	
	

	String sBackROI = "Back_"+num2str(file)
	Make/O/N=(NTotImgs) $sBackROI
	Wave wbackROI = $sBackROI
	
	
	Make/WAVE/o/N=(NtotImgs) wawback

MultiThread wawback=Worker(wImgStackback,p,M_ROIMask) //////// Multi-thread Function that allows to calculate the average ROI pixel value  using multiple processors.

WAVE w= wawback[0]
Duplicate/O w, wbackROI // w contains references to Free Data Folders that save the average ROI pixel value 

Variable h /// h represents the number of image to be analyzed by worker
for(h=1; h<ntotimgs; h+=1) 
wave w= wawback[h] // Get a reference to the next free data folder
concatenate/NP {w}, wbackROI
endfor

// wawback holds references to the free data folders. By killing wawback,
// we kill the last reference to the free data folders which causes
// them to be automatically deleted. Because there are no remaining
// references to the various M_ImagePlane waves, they too are automatically deleted.

KillWaves wawback

string BackROIMask="ROIMask_"+num2str(file)+"_Back"
duplicate/o M_ROIMask, $BackROIMask
DoWindow/K WMImageROIPanel //Close panel that controls Background ROI drawing

make/n=(ntotimgs/nsweeps, nsweeps)/o SMoothBACK=0

for(j=0;j<(NSweeps);j+=1) 
		
		for(i=0;i<(ntotimgs/nsweeps);i+=1) 
					
		SMoothBACK[i][j]=wbackroi[j*(ntotimgs/nsweeps)+i]
		
		endfor

endfor


Smooth/E=3/S=2 5, SmoothBACK

for(j=0;j<(NSweeps);j+=1) 
		
		for(i=0;i<(ntotimgs/nsweeps);i+=1) 
					
		wbackroi[j*(ntotimgs/nsweeps)+i] = SMoothBACK[i][j]
		
		endfor

endfor

killwaves Smoothback

MoveWave $BackROIMask, :$(sFolder):  // Move the Background Mask to the defined Analysis Folder

//////////////////////////// Depending on the ExperimentType selected we will need Ephys waves or not. For single pulse stimulation experiments, we should have previously analyzed the ephys traces.

String sAmpWave = "AmplitudeWave_"+num2str(file)+"_1"  
String sFallas="Nfailures_"+num2str(file)

if (V_experimenttype>=2)							//generate AmplitudeWave and N_failuresfor that file in case train/depo is selected
	make/n=(nsweeps)/o $sampwave=1
	make/n=(nsweeps)/o $sfallas=0
endif

Wave wAmpWave = $sAmpWave
Wave wFallas=$sFallas


/////////////////////////// Creates The average of all the electrophysiological traces if train/depo is not selected. 		

SVAR Currentfilename	
Svar IndexCurrFileName

if (V_experimenttype<1)

String sAvgEffTrace= "AvgEfftrace_"+num2str(file)  	 
Make/o/n=45000 $sAvgEffTrace = 0
Wave  AvgEfftrace=$sAvgEffTrace	
SetScale/p x,0,2e-5, $sAvgEffTrace		

variable counter

String filedata
sprintf filedata,"%04d",file
	
	for(j=0;j<(NSweeps);j+=1) 
					
			String sEffTrace = IndexFileName+"_"+filedata+"_"+num2str(j+1)+"_1"  
			Wave wEffTrace = $sEffTrace
			
		if(wAmpWave[j] > 0)
				for(counter=0;counter<45000;counter+=1)
					Multithread AvgEffTrace[counter] += wEffTrace[counter]
				endfor
		endif
		
	endfor
		
AvgEffTrace/=(Nsweeps-wFallas[0])

MoveWave $sAvgEffTrace, :$(sFolder):

endif

////////////////////////Defining the threshold for each file

//1-Generate An average Image for the whole file

string sImgStack = "Img"+IndexfileName+"_"+num2str(file)+".tif"
wave wImgstack=$sImgStack

variable pixelswide=dimsize($sImgStack,0)  /// here we determine the widht and height of each image in the file
variable pixelsheight=dimsize($sImgStack,1)

String sAverageImage="AverageImage_"+num2str(file)    ////Creation of an averaged image of all the images in that file
Make/o/n=(pixelswide,pixelsheight) $sAverageImage
Wave  wAverageImage=$sAverageImage


imagetransform/o averageImage,  wImgstack
	wave M_aveImage
	wAverageImage= M_AveImage


//2-Normalize the averaged image 

String sImageNormalization="ImageNormalization_"+num2str(file) 
Make/o/n=(pixelswide,pixelsheight) $sImageNormalization
Wave  wImageNormalization=$sImageNormalization

wImageNormalization =  wAverageImage

WaveStats/Q wImageNormalization

Variable min=V_min
Variable delta=1.0/(V_max-V_min)
Variable deltaM=delta*min

Fastop wImageNormalization=(delta)*wImageNormalization-(deltaM)

//3-We generate a Mask Using the max and min values that will determine the area of each image that will be considered for analysis based on the threshold values determined

if(v_autocenter==0)

String sROIMasksThreshold="ROIMasksThreshold_"+num2str(file)            //Creation of the wave that will contain the threshold mask               
Make/o/n=(pixelswide,pixelsheight) $sROIMasksThreshold
Wave  wROIMasksThreshold=$sROIMasksThreshold

make/n=2/o Thresholdwave={ThresholdMin,ThresholdMax} //Wave that contains threshold values

Fastop wROIMasksThreshold=wImageNormalization
imagethreshold/o/w=thresholdwave wROIMasksThreshold	//applying thresholds to the averaged and normalized image

wROIMasksThreshold /= 255


////////////////////////DEFINING CENTER IN CASE AUTOMATIC CENTER  AND THRESHOLD DETERMINATION IS SELECTED

//// This defines a center based on the average of all the images in the files. The center will be the pixel with the highest intensity

elseif(v_autocenter==1)

ImageThreshold/I/M=(1)/Q M_AveImage // Determination of cellular flourescence limits using Iterative method. M_Imagethresh is the output
wave M_ImageThresh
imagestats/r=M_Imagethresh M_AveImage

ImageMorphology/O/E=(5)/I=(1) BinaryErosion, M_ImageThresh  // After determination of fluorescence limits I give an extra pixel to the whole area
ImageAnalyzeParticles /E/W/Q/M=3/A=5/EBPC  stats,M_ImageThresh  //Particle analysis to determine contour and center of the cell

wave M_moments

		
X0= M_moments[0][0]   
Y0= M_moments[0][1]    //Particle analysis based center of mass

M_imagethresh-=255
M_AveImage*=M_Imagethresh

min=V_min
delta=1.0/(V_max-V_min)
deltaM=delta*min
Fastop M_AveImage=(delta)*M_aveImage-(deltaM)  //normalization of the image

wROIMasksThreshold[][]=M_AveImage 

imagethreshold/o/t=(ThresholdMax) wROIMasksThreshold	//applying thresholds to the averaged and normalized image

wROIMasksThreshold /= 255
wRoiMasksThreshold-=1
wRoiMasksThreshold/=255


killwaves M_ImageThresh

Killwaves W_imageobjarea,W_spotx,w_spotY, w_circularity, w_rectangularity, W_imageobjperimeter, W_xmin, W_xmax, W_ymin,W_ymax, W_boundaryX,W_boundaryY,WBoundaryIndex

endif 

killwaves wImageNormalization,thresholdwave

///////////////////////DEFINE INTERIOR AND EXTERIOR CIRCLES

//1-Draw external and internal circunferences 

SetDrawLayer UserFront
SetDrawEnv xcoord= top,ycoord= left,save
showtools
setdrawenv fillpat=0,linefgc=(58880,19712,6656),save

string outercircle="drawarc/x/Y "+ num2str(x0)+","+num2str(y0)+","+num2str(rext)+",0,360"
string Innercircle="drawarc/x/Y "+ num2str(x0)+","+num2str(y0)+","+num2str(rint)+",0,360"

execute Innercircle
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
	execute Innercircle

	
		ImageGenerateROIMask/E=0/I=1 $sImgStack	///generates the Mask for that ROI. The output wave is M_ROIMASK

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

	String sROI = "ROI_"+num2str(file)+"_"+nROI
	Make/O/N=(NTotImgs) $sROI
	Wave wROI = $sROI 
	
	sImgStack = "Img"+IndexfileName+"_"+num2str(file)+".tif"
	wave wImgstack=$sImgStack

Make/WAVE/o/N=(NtotImgs) waw
		
MultiThread waw=Worker(wImgStack,p,M_ROIMask)

WAVE w= waw[0]
Duplicate/O w, wROI


		for(h=1; h<ntotimgs; h+=1)
		
			wave w= waw[h] // Get a reference to the next free data folder
			concatenate/NP {w}, wROI

		endfor

KillWaves waw

wROI-=wbackROI		

endfor				

	


//4-Stack all the ROIs in a 3D wave where each plane represents all the ROIs for a single sweep


String sStackSweep = "StackSweep"               
Make/o/n=(NTotImgs/nsweeps,360/angle,Nsweeps) $sStackSweep
Wave wStackSweep= $sStackSweep


for(K=0;K<(360/angle);K+=1) 

nROI=num2str(k+1)
sROI = "ROI_"+num2str(file)+"_"+nROI
wave wROI = $sROI 


		for(j=0;j<(NSweeps);j+=1)   ///generates a Stack of sweeps. Each plane shows all the ROI vs Time for each sweep

		for(i=0;i<(NTotImgs/Nsweeps);i+=1)	
		
		wStackSweep [i][K][j]= (wROI[i+(NTotImgs/Nsweeps)*j] )
		
		endfor

	endfor

endfor



//5-We smooth each ROI using a Multithread Function ("Worker2") and then we concatenate them in ConcatenatedSweeps


String sConcatenatedSweeps = "ConcatenatedSweeps"
Make/o/n=(NTotImgs,360/angle) $sConcatenatedSweeps
Wave wConcatenatedSweeps= $sConcatenatedSweeps 


Make/df/o/N=(nsweeps) dfw
		
MultiThread dfw= Worker2(wStackSweep,p) // Multithread function that Filters the normalized image of each sweep

dfref df=dfw [0] 
wave M_Imageplane=df:M_Imageplane


		for(K=0;K<(360/angle);K+=1) 

		variable ZeroValue=M_imageplane[2][k]

		for(i=0;i<(NTotImgs/Nsweeps);i+=1)	
		
		if(v_analysismode==1)
		
		M_ImagePlane[i][k]= (M_imageplane[i][k]-ZeroValue)/ZeroValue
		elseif(v_analysismode==2)
		M_imageplane[i][k]= (M_imageplane[i][k]-ZeroValue)
		
		endif
		endfor
		endfor
		
		Duplicate/O M_ImagePlane, wConcatenatedSweeps

variable t

	for(t=1; t<nsweeps; t+=1)
		df = dfw[t] // Get a reference to the next free data folder
	
			wave M_Imageplane=df:M_Imageplane
		
		for(K=0;K<(360/angle);K+=1) 
		ZeroValue=M_imageplane[2][k]
		
		for(i=0;i<(NTotImgs/Nsweeps);i+=1)	
		
		if(v_analysismode==1)
		M_ImagePlane[i][k]= (M_imageplane[i][k]-ZeroValue)/ZeroValue
		elseif(v_analysismode==2)
		M_imageplane[i][k]= (M_imageplane[i][k]-ZeroValue)
		
		endif
		endfor
		endfor
		
		concatenate/NP=0 {df:M_ImagePlane}, wConcatenatedSweeps

	endfor
	
KillWaves dfw

///////////////////NUMERICAL ANALYSIS OF EACH ROI LOOKING FOR IMAGING SUCCESFUL EVENTS

//1-Define and create all the waves that will hold the information 


string sDetection="Detection"	//////generate a 2D wave that shows the peak signal detected in each ROI for each sweep		
make/o/n=(nsweeps,360/angle) $sDetection=0
wave Wdetection=$sDetection

string sDetectionFallaEF="Detection_FallaEF"	
make/o/n=(nsweeps,360/angle) $sDetectionFallaEF=0
wave WdetectionFallaEF=$sDetectionFallaEF


string sIntegralFallaEF="Integral_FallaEF"	
make/o/n=(nsweeps,360/angle) $sIntegralFallaEF=0
wave WIntegralFallaEF=$sIntegralFallaEF


string sAvg="AVG" /////generate a 2D wave that shows the baseline signal detected in each ROI for each sweep		
make/o/n=(nsweeps,360/angle) $sAVG=0
wave WAVG=$sAVG

string sSDEV="SDEV"	//////generate a 2D wave that shows the sdev of the imaging signal detected in each ROI for each sweep		
make/o/n=(nsweeps,360/angle) $sSDEV=0
wave WSDEV=$sSDEV		

string sIntegralArea="Integral_Area"	//////generate a 2D wave that shows the integral of the imaging signal detected in each ROI for each sweep		
make/o/n=(nsweeps,360/angle) $sIntegralArea=0
wave WIntegralArea=$sIntegralArea	

string sROIConcatenatedSweeps="ROIConcatenatedSweeps"
make/o/n=(NTotImgs) $sROIConcatenatedSweeps
wave wROIConcatenatedSweeps=$sROIConcatenatedSweeps

String sAvgNRSucces= "AvgNRSucces_"+num2str(file)
Make/o/n=(NTotImgs/Nsweeps,360/angle) $sAvgNRSucces = 0
Wave wAvgNRSucces = $sAvgNRSucces  ////////////// this wave will show the average imaging signal of all the succesfull event
wAvgNRSucces=0
	
String sAvgNRFail= "AvgNRFail_"+num2str(file)
Make/o/n=(NTotImgs/Nsweeps,360/angle) $sAvgNRFail = 0
Wave wAvgNRFail = $sAvgNRFail ////////////// this wave will show the average imaging signal of all the failures

String sProbability= "ProbabilityROIs_"+num2str(file)
Make/o/n=(360/angle) $sProbability = 0
Wave wProbability = $sProbability ////////////// this wave will show the probability of each ROI to show a positive EF and IMG event

string sSumImaging="SumImaging"  ////// this wave will show the the sum of the signal of all the ROIs for each sweep
make/o/n=(nsweeps) $sSumImaging 
wave WSumImaging=$sSumImaging
wSumImaging=0

string sAreaImaging="areaImaging"  ////// this wave will show the the sum of the signal of all the ROIs for each sweep
make/o/n=(nsweeps) $sareaImaging 
wave WareaImaging=$sareaImaging
wareaImaging=0


string sTauImaging="TauImaging"  ////// this wave will show the the sum of the signal of all the ROIs for each sweep
make/o/n=(nsweeps,360/angle) $sTauImaging 
wave WTauImaging=$sTauImaging
wTauImaging=0

String sDatafile= "DataFile_"+num2str(file)  //// this wave contains the timing of the stimulus
Wave wDataFile = $sDatafile ////////////// 


make/o/n=(nsweeps) Peak


string sTimewave="Timewave_"+num2str(file)

	if(waveexists ($stimewave)==0)   ///This will look for the wave containing the The timepoints for each image

		DoAlert 0,"You Need To Load a Timewave in order to Calculate Decay Kinetics"
		LoadMultipleDelimitedTextFiles()
	
	endif

wave timewave=$stimewave

//2-Performing the analysis for each ROI using another Multi-thread function called ("WorkerSFSingle")


for(K=0;K<(360/angle);K+=1) 	



wROIConcatenatedSweeps[] = wConcatenatedSweeps[p][k]
	
variable countersuccesimaging=0,counterfailimaging=0

	
	Make/WAVE/o/N=(nsweeps) waw3
	
		
	MultiThread waw3= WorkerSFSingle(wROIConcatenatedSweeps,Peak,timewave,wdatafile,p,ntotImgs,nsweeps,criteria,Integral) ///Analiza en una funcion multithread la existencia de picos en la señal de cada ROI y calcula su amplitud e integral. 
 
	WAVE w3= waw3[0]
	
	wdetection[0][k]=w3[0]
	wAVG[0][k]=w3[1]
	wSDEV[0][k]=w3[2]
	wIntegralArea[0][k]=w3[3]
	wTauImaging[0][k]=w3[4]
	wDEtectionFallaEF[0][k]=w3[5]
	wIntegralFallaEF[0][k]=w3[3]
	
		for(h=1; h<nsweeps; h+=1)
		
		wave w3= waw3[h] 
		wDetection[h][k]= w3[0]
		
		wAVG[h][k]=w3[1]
		
		wSDEV[h][k]=w3[2]
		
		wIntegralArea[h][k]=w3[3]
		
		wTauImaging[h][k]=w3[4]
		
		wDEtectionFallaEF[h][k]=w3[5]
		
		wIntegralFallaEF[h][k]=w3[3]

		
		endfor

KillWaves waw3
KillWaves w3

//3- Detecting imaging succesful events	based on the criteria and integral variables determined. 


for(j=0;j<(NSweeps);j+=1) 

	if (V_experimenttype>=2)	
		
		for(i=0;i<(NTotImgs/Nsweeps);i+=1)	
		multithread wAvgNRSucces[i][k] += wStackSweep[i][k][j] 
		endfor 
		countersuccesimaging+= 1
	
	else
	
		if(wAmpWave[j] >0)
		
		WdetectionFallaEF[j][k]=0
		WIntegralFallaEF[j][k]=0
		endif
		
		
	
		if(wAmpWave[j] > 0 && wdetection[j][k]>0)
	
			for(i=0;i<(NTotImgs/Nsweeps);i+=1)	
		
			multithread wAvgNRSucces[i][k] += wStackSweep[i][k][j] 
		
			endfor 
		
			countersuccesimaging+= 1


		elseif(wAmpWave[j] == 0)
	
			multithread wAvgNRFail[][k] += wStackSweep[p][k][j] 	
			
			
				if(wdetection[j][k]>0)
				counterfailimaging += 1
				endif
	
		endif
	
	
	
	Multithread wSumImaging[j]+= wDetection[j][k]
				wareaimaging[j]+=wIntegralArea[j][k]
	endif
	
	endfor 
	
	wAvgNRFail[][k]/=wFallas[0]

		if(countersuccesimaging>0)
			wAvgNRSucces[][k]/=countersuccesimaging
		endif
	
		wProbability[k]=countersuccesimaging+counterfailimaging



nROI=num2str(k+1)
sROI = "ROI_"+num2str(file)+"_"+nROI
Wave wROI = $sROI 
killwaves wRoi

endfor ///// endfor del loop de K=nROI


//////////////MOVING ALL THE INFORMATION WAVES TO THE CREATED ANALYSIS FOLDER

MoveWave :$sAvgNRSucces, :$(sFolder): 
MoveWave :$sAvgNRFail, :$(sFolder):
wavestats/q wProbability
wProbability/=nsweeps	
MoveWave :$sProbability, :$(sFolder):
MoveWave :$sIntegralarea, :$(sFolder):
MoveWave :$sTauimaging, :$(sFolder):

string/G AutoROIAnalVar="X0="+num2str(x0)+";Y0="+num2str(y0)+";Rint="+num2str(rint)+"Rext="+num2str(rext)+"Angle="+num2str(angle)+"criteria="+num2str(criteria)+"integral="+num2str(integral)
movestring AutoROIAnalVar, :$(sFolder):

MoveWave :$sROIMasks, :$(sFolder):
MoveWave :$sROIMasksThreshold, :$(sFolder):

MoveWave :$sconcatenatedsweeps, :$(sFolder):
MoveWave $sBackROI, :$(sFolder):
MoveWave :$sDetection, :$(sFolder):
MoveWave :$sSumImaging, :$(sFolder):
MoveWave  :$sareaimaging, :$(sFolder):
MoveWave :$sDetectionFallaEF, :$(sFolder):
MoveWave :$sIntegralFallaEF, :$(sFolder):


////////////////////////////////// Creates a 3D wave with the averages of all the images corresponding to successful events

If(V_domovie==1)

	i=0
	j=0
	Variable flag=0
	
	string sAvgSuccesNonRatio="AvgsuccesNonratio_"+num2str(file)
	Make/o/n=(pixelswide,pixelsheight,NTotImgs/Nsweeps) $sAvgSuccesNonRatio
	Wave wAvgSuccesNonRatio =  $sAvgSuccesNonRatio
			
	sImgStack = "Img"+IndexfileName+"_"+num2str(file)+".tif"
	wave wImgstack=$sImgStack
				
	for(j=0;j<Nsweeps;j+=1)	//i cuenta #sweep
	
		if(wAmpWave[j] > 0)
			for(i=0;i<(NTotImgs/Nsweeps);i+=1)	//j cuenta numero de imagen en cada sweep
			
				Multithread wAvgSuccesNonRatio[][][i] +=  (wImgstack[p][q][i+(NTotImgs/Nsweeps)*j] - wBackroi[i+(NTotImgs/Nsweeps)*j][0]) - (wImgstack[p][q][(NTotImgs/Nsweeps)*j]- wBackroi[(NTotImgs/Nsweeps)*j][0])
						
					
			endfor
			
		flag+=1
		endif
	
	endfor
	
	wAvgSuccesNonRatio/=flag

	MoveWave $sAvgSuccesNonRatio, :$(sFolder):

	
endif

killwaves wROIconcatenatedsweeps, M_ROIMask,M_AveImage
endif


end


///////////////////////////////////////////////////////////////////////////////////////////////////////////


////  This Function tries to find a peak in the fluorescence signal for each ROI. It also calculates the area under the peak and the Tau Decay.
//// Finally, It will use the amplitude of the peak found and the area calculated to determine whether the event can be considered 
/// a Success based in the indicated criteria. 

ThreadSafe Function/wave WorkerSFSingle(wROIConcatenatedSweeps,Peak,timewave,wdatafile,plane,ntotImgs,nsweeps,criteria,integral) 	

WAVE wROIConcatenatedSweeps,Peak,timewave,wdatafile
Variable plane, ntotImgs,nsweeps,criteria,integral // plane represents image number


DFREF dfSav= GetDataFolderDFR()
SetDataFolder NewFreeDataFolder()
 

make/free/o/n=(6) wdata

WaveStats/Q/R=(3+(NTotImgs/Nsweeps)*plane, wdatafile[plane][2]) wROIConcatenatedSweeps 
wdata[1]=V_avg
wdata[2]=V_sdev

FindPeak/B=5/P/Q/R=(wdatafile[plane][2],wdatafile[plane][2]+15) wROIConcatenatedSweeps	
wdata[0]=V_peakval - V_avg
variable XPico=V_PeakLoc

wdata[5] =(wROIConcatenatedSweeps[1+wdatafile[plane][2]] +wROIConcatenatedSweeps[2+wdatafile[plane][2]]+wROIConcatenatedSweeps[3+wdatafile[plane][2]])/3 - V_avg

Peak[plane]= xpico

	CurveFit/Q=1/W=2  line,  wROIConcatenatedSweeps[3+(NTotImgs/Nsweeps)*plane,50+(NTotImgs/Nsweeps)*plane ]

make/free/o/n=(ntotimgs*nsweeps) IntBaseline

wave W_coef

IntBaseline[] = V_avg //W_coef[0]+W_coef[1]*x


wdata[3] = area(wROIConcatenatedSweeps,wdatafile[plane][2],50+(NTotImgs/Nsweeps)*plane ) - area(intbaseline,wdatafile[plane][2],50+(NTotImgs/Nsweeps)*plane) ///Integra desde el punto 10 al 40


if((wdata[0] >= wdata[2]*criteria) && (wdata[3]>=Integral))

	wdata[0]=V_peakval - V_avg

	if(numtype(xpico)<2) 
	
		CurveFit/N=1/Q=1/W=2  exp,  wROIConcatenatedSweeps[Xpico,(NTotImgs/Nsweeps)+(NTotImgs/Nsweeps)*plane-1 ]/X=TimeWave[(Xpico),((NTotImgs/Nsweeps)*plane)+(NTotImgs/Nsweeps)-1] /NWOK
		
	wave W_coef

		variable tau=W_coef[2]
		wdata[4]=1/tau
	
	endif


else

wdata[0]=0

endif

SetDataFolder dfSav

return  wdata

End

////////////////////////////////////////////////////////////////

ThreadSafe Function/Wave Worker(wImgStack, plane, M_ROIMask) //// This Function allows the Multi-thread  calculation of the average of each ROI for all the file's images

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

//////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////

ThreadSafe Function/DF Worker2(wStackSweep, plane)  //// Smooths the sweep stacks generated after Stacking all the ROIs for each sweep

WAVE wStackSweep
Variable plane


DFREF dfSav= GetDataFolderDFR()
DFREF dfFree= NewFreeDataFolder()
SetDataFolder  dfFree


ImageTransform/P=(plane) getPlane, wStackSweep

wave M_imageplane

Smooth/E=3/S=2 5, M_imageplane
Smooth/dim=1/E=3/S=2 5, M_imageplane

		 SetDataFolder dfSav

return  dfFree

End

////////////////////////////////////////////////////////

////  This Function tries to find a peak in the fluorescence signal for each ROI. It also calculates the area under the peak and the Tau Decay.
//// Finally, It will use the amplitude of the peak found and the area calculated to determine whether the event can be considered 
/// a Success based in the indicated criteria. 
																			

ThreadSafe Function/wave Worker3(wROIConcatenatedSweeps,Peak,timewave,plane,ntotImgs,nsweeps,criteria,integral) 	

WAVE wROIConcatenatedSweeps,Peak,timewave
Variable plane, ntotImgs,nsweeps,criteria,integral // plane represents image number


DFREF dfSav= GetDataFolderDFR()
SetDataFolder NewFreeDataFolder()
 

make/free/o/n=(6) wdata

WaveStats/Q/R=(3+(NTotImgs/Nsweeps)*plane, 10+(NTotImgs/Nsweeps)*plane) wROIConcatenatedSweeps 
wdata[1]=V_avg
wdata[2]=V_sdev

FindPeak/B=5/P/Q/R=(10+(NTotImgs/Nsweeps)*plane,30+(NTotImgs/Nsweeps)*plane) wROIConcatenatedSweeps	
wdata[0]=V_peakval - V_avg
variable XPico=V_PeakLoc

wdata[5] =(wROIConcatenatedSweeps[15+(NTotImgs/Nsweeps)*plane] +wROIConcatenatedSweeps[16+(NTotImgs/Nsweeps)*plane]+wROIConcatenatedSweeps[17+(NTotImgs/Nsweeps)*plane])/3 - V_avg

Peak[plane]= xpico

//	CurveFit/Q=1/W=2  line,  wROIConcatenatedSweeps[3+(NTotImgs/Nsweeps)*plane,37+(NTotImgs/Nsweeps)*plane ]

make/free/o/n=(ntotimgs*nsweeps) IntBaseline

wave W_coef

IntBaseline[] = V_avg //W_coef[0]+W_coef[1]*x


wdata[3] = area(wROIConcatenatedSweeps,10+(NTotImgs/Nsweeps)*plane,40+(NTotImgs/Nsweeps)*plane ) - area(intbaseline,10+(NTotImgs/Nsweeps)*plane,40+(NTotImgs/Nsweeps)*plane) ///Integra desde el punto 10 al 40


if((wdata[0] >= wdata[2]*criteria) && (wdata[3]>=Integral))

	wdata[0]=V_peakval - V_avg

	if(numtype(xpico)<2) 
	
		CurveFit/N=1/Q=1/W=2  exp_XOffset,  wROIConcatenatedSweeps[Xpico,(NTotImgs/Nsweeps)+(NTotImgs/Nsweeps)*plane-1 ]/X=TimeWave[(Xpico),((NTotImgs/Nsweeps)*plane)+(NTotImgs/Nsweeps)-1] /NWOK
		
	wave W_coef

		variable tau=W_coef[2]
		wdata[4]=1/tau
	
	endif


else

wdata[0]=0

endif

SetDataFolder dfSav

return  wdata

End
