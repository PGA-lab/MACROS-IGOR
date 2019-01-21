#pragma rtGlobals=3		// Use modern global access method and strict wave access.

"ImagenRespuestaWideField()"
"LoadMultipleDelimitedTextFiles()"
"SliderWAVES()"
"ConcatenateFiles()"
" CorreccionBleachingImagenBYROI()"
" CorreccionBleachingBYPIXEL()"
"WM3DImageSliderProc1()"
"OCS()"

#include <FilterDialog> menus=0
#include <All IP Procedures>
#include <Image Saver>
#include <Ternary Diagram>
#include <Pole and Zero Filter Design> menus=0
#include <Scatter Plot Matrix 2>



Function ImagenRespuestaWideField()

String  FirstImage
variable totsweeps, ImgSweep, StimImg


	Prompt FirstImage, "First File Source Image:", popup Wavelist("*", ";", "")
	prompt totsweeps, "Sweeps per file:"
	prompt ImgSweep, " Images per sweep:"
	prompt StimImg, "Stimulation Time (msec):"
	
	
	DoPrompt "List Files",FirstImage, totsweeps, ImgSweep,StimImg
	
	If (v_flag)
		return -1
	endif


variable z=0

wave wfirstimage=$firstimage
string stimewave="Timewave_"+FirstImage
wave timewave=$stimewave


	variable Rows=dimsize (wFirstImage, 0) 
	variable columns= dimsize (wFirstImage, 1)
	
	Make/o/n=(rows,columns,totsweeps*Imgsweep) Respuesta=0
	wave respuesta
	
	respuesta= wfirstimage
 
	variable j
	variable i

	For(z=0;z<totsweeps;z+=1)
		
		Findlevel/q/p timewave,(StimImg/1000+timewave[Imgsweep*z]-timewave[0]) /// Defines time stimulus for each sweep
		variable Stim=V_LevelX
				
			
				Make/o/n=(rows,columns,Stim-z*Imgsweep) Basal=0
				wave basal	
					
						
				duplicate/o/r=(,)(,)(z*Imgsweep,Stim) wfirstimage, basal
				Imagetransform averageimage basal 
				wave M_AveImage
				
				Make/o/n=(rows,columns) basalU=0
				
				wave basalu
				basalu=M_AveImage
				
				
				For(i=0;i<ImgSweep;i+=1)
				
				respuesta[][][Imgsweep*z+i]-=basalu[p][q]
				
				
				endfor
				
						
	endfor


killwaves M_AveImage, basal, basalU

End

/////////////////////////////////////////////////////////////////////////////////////////////

Function SliderWAVES()
	
	String grfName= WinName(0, 1)
	DoWindow/F $grfName
	if( V_Flag==0 )
		return 0			// no top graph, exit
	endif

	ControlInfo SweepSlide
	if( V_Flag != 0 )
		return 0			// already installed, do nothing
	endif


string/G TName= TraceNameList("", ",",1)

variable TotalSweeps= ItemsInList(TName, "," )

	ControlInfo kwControlBar
	Variable/G gOriginalHeight= V_Height		// we append below original controls (if any)
	ControlBar gOriginalHeight+30
		

	GetWindow kwTopWin,gsize
	Variable/G SweepN= 0
	
	
	Slider SweepSlide,pos={V_left+10,gOriginalHeight+10},size={V_right-V_left,16}, Proc=Moveslide
	Slider SweepSlide,limits={0,TotalSweeps-1,1},value= 0,vert= 0,ticks=0,side=0, variable=SweepN
	
	SetVariable SweepN,pos={V_right+15,gOriginalHeight+9},size={60,14}
	SetVariable SweepN,limits={0,TotalSweeps-1,1},title=" ", proc=WM1DImageSliderSetVarProc
	
	
	String cmd
	sprintf cmd,"SetVariable SweepN,value=%s", "SweepN"
	Execute cmd
	
	String/g Firstsweep=StringFromList(SweepN, TName,",")
	
	ModifyGraph rgb($Firstsweep)=(0,0,0)			
		
	TextBox/w=$grfName/C/N=text0/A=RT Firstsweep	
		
		string/g ORDER= removelistitem (SweepN, TName,",")
		string cmd2
		
		if(TotalSweeps>30)
		
		variable Ninstances=ceil(TotalSweeps/30)
		variable i
		
			For( i=0;i<Ninstances;i+=1)
				
				variable listitem=i*30
				string OrderInstance=""

				do
				
					OrderInstance=AddListItem(StringFromList(listitem, ORDER,","),OrderInstance, ",")
				
				listitem+=1
								
					if (listitem== totalsweeps)
						break						
					endif		
								
				while ((listitem<i*30+30))
				
				OrderInstance=RemoveEnding(OrderInstance)
				
				sprintf cmd2,"ReorderTraces $Firstsweep, {%s}",OrderInstance
				print orderinstance
				Execute cmd2
			
		
			endfor
		
		else
		
			Order=RemoveEnding(ORDER)
			
			
			sprintf cmd2,"ReorderTraces $Firstsweep, {%s}",ORDER
			Execute cmd2
			
		endif
end


Function Moveslide(name, value, event) : SliderControl
		String name	// name of this slider control
		Variable value	// value of slider
		Variable event	// bit field: bit 0: value set; 1: mouse down, 
					//   2: mouse up, 3: mouse moved
				
		NVAR SweepN		
		SVAR TName
		
		String grfName= WinName(0, 1)

		
		SVAR FirstSweep
				FirstSweep=StringFromList(SweepN, TName,",")

		ModifyGraph rgb=(65280,0,0)
				ModifyGraph/W=$grfName rgb($FirstSweep)=(0,0,0)			
		TextBox/w=$grfName/C/N=text0/A=RT FirstSweep	
		
		variable TotalSweeps= ItemsInList(TName, "," )
		
		String ORDER= removelistitem (SweepN, TName,",")
		string cmd2
		
		if(TotalSweeps>30)
		
		variable Ninstances=ceil(TotalSweeps/30)
		variable i
		
			For( i=0;i<Ninstances;i+=1)
				
				variable listitem=i*30
				string OrderInstance=""

				do
				
					OrderInstance=AddListItem(StringFromList(listitem, ORDER,","),OrderInstance, ",")
				
				listitem+=1
					
						if (listitem== totalsweeps)
							break						
						endif				
				while (listitem<i*30+30) //(listitem<TotalSweeps))
				
				OrderInstance=RemoveEnding(OrderInstance)
				
				sprintf cmd2,"ReorderTraces $Firstsweep, {%s}",OrderInstance
				Execute cmd2
			
		
			endfor
		
		else
		
			Order=RemoveEnding(ORDER)
			
			
			sprintf cmd2,"ReorderTraces $Firstsweep, {%s}",ORDER
			Execute cmd2
			
		endif

		
		return 0	// other return values reserved
	
	End

//*******************************************************************************************************
Function WM1DImageSliderSetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		// comment the following line if you want to disable live updates.
		case 3: // Live update
			Variable dval = sva.dval
		
			Moveslide("",0,0)
			break
	endswitch

	return 0
End



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function ConcatenateFiles()

	String panelName = "Wave Selector"
	// figure out what to show in the Wave Selector, and make an appropriate name for the panel
	
			panelName="Waves"
					
	
	if (WinType(panelName) == 7)
		DoWindow/F $panelName
	else
	
		NewPanel/N=$panelName/W=(181,179,471,510) as "Wave Selector Example"

		// list box control doesn't have any attributes set on it
		ListBox ExampleWaveSelectorList,pos={9,13},size={273,241}
			Button FinishSelection,pos+={70,45},size={150,20},win=$panelname,proc=Concatenatelist,title="Finish Selection"
			Button CloseWindow,pos={185,270},size={95,20},win=$panelname,proc=Concatenatelist,title="Close"
		// This function does all the work of making the listbox control into a
		// Wave Selector widget. Note the optional parameter that says what type of objects to
		// display in the list. 
		MakeListIntoWaveSelector(panelName, "ExampleWaveSelectorList", content = WMWS_Waves)

		if( 	WMWS_Waves == WMWS_Waves )
			// This function does all the work of making a PopupMenu control into a wave sorting control
			PopupMenu sortKind, pos={9,270},title="Sort Waves By"
			MakePopupIntoWaveSelectorSort(panelName, "ExampleWaveSelectorList", "sortKind")
		endif

		// This is an extra bonus- you can create your own function to be notified of certain events,
		// such as a change in the selection in the list.
	endif
	
end

Function Concatenatelist(ctrlname)

string ctrlname

if( CmpStr(ctrlName,"CloseWindow") == 0 ) 

dowindow /k waves
return 0

endif

if( CmpStr(ctrlName,"FinishSelection") == 0 ) 

string sFilelist=  WS_SelectedObjectsList("Waves",  "ExampleWaveSelectorList")
print sFilelist

dowindow /k waves

variable totalwaves= ItemsInList (sFilelist, ";") 
variable i
  
 string file
 string fileconcatenation
 
 for(i=0;i<totalwaves;i+=1)
if(i==0)

File= StringFromList(i, sFilelist , ";" )

fileconcatenation= file

else

File= StringFromList(i, sFilelist , ";" )


fileconcatenation=fileconcatenation+","+ file

endif

endfor

string Output

Prompt Output, "Image File:"

	DoPrompt "Output File Name",output	
	If (v_flag)
		return -1
	endif


string postexecute= "concatenate/o/np {"+fileconcatenation+"},"+" '"+Output+"' "

execute postexecute
endif
end

/////////////////////////////////////////////////////////////////////////////////////////////////

Function LoadMultipleDelimitedTextFiles() /// This Function loads txt files containing the timestamp for each image


open/d/r/mult=1/t="????" refnum as ""
string outputPaths = S_fileName
string/g Filename

if (strlen(outputPaths) == 0)
		Print "Cancelled"
	else
	
		Variable numFilesSelected = ItemsInList(outputPaths, "\r")
		Variable K
		
		for(K=0; K<numFilesSelected; K+=1)
			String path = StringFromList(K, outputPaths, "\r")
			Printf "%d: %s\r", K, path	
			Filename= path
		
		LoadWave/J/D/W/O/K=0 filename
			
	
		endfor
endif		
		
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function CorreccionBleachingImagen()

String  FirstImage
variable totsweeps=1, ImgSweep=200


	Prompt FirstImage, "First File Source Image:", popup Wavelist("Img*", ";", "")
	prompt totsweeps, "Sweeps per file:"
	prompt ImgSweep, " Images per sweep:"
	
	DoPrompt "List Files",FirstImage, totsweeps, ImgSweep
	
	If (v_flag)
		return -1
	endif
	
	
	wave wfirstimage=$firstimage
	
	imagetransform/o averageImage wfirstimage
	wave M_aveImage
	
	variable pixelswide=dimsize(M_aveImage,0)  /// here we determine the widht and height of each image in the file
	variable pixelsheight=dimsize(M_aveImage,1)

	make/o/n=(pixelswide,pixelsheight,totsweeps* ImgSweep) crudo
	crudo= wfirstimage
	
	
	ImageThreshold/i/M=(5)/Q M_AveImage // Determination of cellular flourescence limits using Iterative method. M_Imagethresh is the output
	wave M_ImageThresh
	
	Imagetransform invert M_ImageThresh
	wave M_inverted
	M_inverted/=255
	M_AveImage*=M_inverted
		
	String sImageNormalization="ImageNormalization_"
	Make/o/n=(pixelswide,pixelsheight) $sImageNormalization
	Wave  wImageNormalization=$sImageNormalization

	wImageNormalization =  M_aveImage
	WaveStats/Q wImageNormalization

	Variable min=V_min
	Variable delta=1.0/(V_max-V_min)
	Variable deltaM=delta*min
		
	Fastop wImageNormalization=(delta)*wImageNormalization-(deltaM)
		
//3-We generate a Mask Using the max and min values that will determine the area of each image that will be considered for analysis based on the threshold values determined
		
	String sROIMasksThreshold="ROIMasksThreshold_"   //Creation of the wave that will contain the threshold mask               
	Make/o/n=(pixelswide,pixelsheight) $sROIMasksThreshold
	Wave  wROIMasksThreshold=$sROIMasksThreshold
	Fastop wROIMasksThreshold=wImageNormalization
	
	make/n=2/o Thresholdwave={0.45,0.85} //Wave that contains threshold values
	Fastop wROIMasksThreshold=wImageNormalization
	imagethreshold/i/w=thresholdwave wImageNormalization
		
	wave M_ImageThresh

	imagetransform/r=M_ImageThresh averageimage crudo

	make/o/n=(totsweeps* ImgSweep) AVGWAve=0
	
	variable i
	for(i=0;i<(totsweeps* ImgSweep) ;i+=1)
	
	ImageStats/p=(i)/R=M_ImageThresh  crudo
	
	AVGWAVE[i]=V_avg
	
	endfor
	
	CurveFit/M=2/W=0 poly 5, AvGWAVE/D
	wave W_coef
		
	M_ImageThresh/=255
	
	make/o/n=(pixelswide,pixelsheight) operando=0
	operando=M_ImageThresh
	
	operando-=1	
	operando/=(-1)
	
	for(i=0;i<(totsweeps*ImgSweep);i+=1)
		
	operando*=(W_coef[0]+W_coef[1]*i+W_coef[2]*i^2+W_coef[3]*i^3+W_coef[4]*i^4)	
	
	crudo[][][i]-=operando[p][q]
	
	operando/=(W_coef[0]+W_coef[1]*i+W_coef[2]*i^2+W_coef[3]*i^3+W_coef[4]*i^4)	

	
	endfor
	
	
	end
	
Function CorreccionBleachingBYPIXEL()

String  FirstImage
variable totsweeps=1, ImgSweep=200


	Prompt FirstImage, "First File Source Image:", popup Wavelist("*", ";", "")
	prompt totsweeps, "Sweeps per file:"
	prompt ImgSweep, " Images per sweep:"
	
	DoPrompt "List Files",FirstImage, totsweeps, ImgSweep
	
	If (v_flag)
		return -1
	endif
	
	
	wave wfirstimage=$firstimage
	variable pixelswide=dimsize(wfirstimage,0)  /// here we determine the widht and height of each image in the file
	variable pixelsheight=dimsize(wfirstimage,1)

	make/o/n=(pixelswide,pixelsheight,totsweeps* ImgSweep) crudo
	crudo= wfirstimage
	
	variable i,j,k
	for(i=0;i<(pixelswide) ;i+=1)
	
		for(j=0;j<(pixelsheight);j+=1)
		
		imagetransform/beam={(i),(j)} getbeam crudo
		
		wave W_Beam
		
		duplicate/o w_beam, Nada
				
		Nada[10,totsweeps* ImgSweep-20]=nan
	
		CurveFit/q/M=2/W=0 line, Nada/D
		
			//CurveFit/q/M=2/W=0 poly 5, Nada/D

		wave W_coef
		
		
			
			W_Beam-=(W_coef[0]+W_coef[1]*x)//+W_coef[2]*x^2+W_coef[3]*x^3+W_coef[4]*x^4)	
		
		//W_Beam-=(W_coef[1]*x)	
		
		for(k=0;k<(totsweeps* ImgSweep);k+=1)
			crudo[i][j][k]=	W_Beam[k]
			
			
		endfor

		
		endfor
		

	endfor
	
	end
	
	
///////////////////////////////////////////////////////////////////////////////////

	Function WM3DImageSliderProc1(name, value, event)
	String name			// name of this slider control
	Variable value		// value of slider
	Variable event		// bit field: bit 0: value set; 1: mouse down, //   2: mouse up, 3: mouse moved

	String dfSav= GetDataFolder(1)
	String grfName= WinName(0, 1)
	SetDataFolder root:Packages:WM3DImageSlider:$(grfName)

	NVAR gLayer
	SVAR imageName

	ModifyImage  $imageName plane=(gLayer)	
	SetDataFolder dfSav

	// 08JAN03 Tell us if there is an active LineProfile
	SVAR/Z imageGraphName=root:Packages:WMImProcess:LineProfile:imageGraphName
	if(SVAR_EXISTS(imageGraphName))
		if(cmpstr(imageGraphName,grfName)==0)
			ModifyGraph/W=$imageGraphName offset(lineProfileY)={0,0}			// This will fire the S_TraceOffsetInfo dependency
		endif
	endif	
		
	SVAR/Z imageGraphName=root:Packages:WMImProcess:ImageThreshold:ImGrfName
	if(SVAR_EXISTS(imageGraphName))
		if(cmpstr(imageGraphName,grfName)==0)
			WMImageThreshUpdate()
		endif
	endif
	
	return 0				// other return values reserved
End

//*******************************************************************************************************
constant kImageSliderLMargin1= 80

Function WMAppend3DImageSlider1()
	String grfName= WinName(0, 1)
	DoWindow/F $grfName
	if( V_Flag==0 )
		return 0			// no top graph, exit
	endif


	String iName= WMTopImageGraph1()		// find one top image in the top graph window
	if( strlen(iName) == 0 )
		DoAlert 0,"No image plot found"
		return 0
	endif
	
	Wave w= $WMGetImageWave1(iName)	// get the wave associated with the top image.	
	if(DimSize(w,2)<=0)
		DoAlert 0,"Need a 3D image"
		return 0
	endif
	
	ControlInfo WM3DAxis
	if( V_Flag != 0 )
		return 0			// already installed, do nothing
	endif
	
	String dfSav= GetDataFolder(1)
	NewDataFolder/S/O root:Packages
	NewDataFolder/S/O WM3DImageSlider
	NewDataFolder/S/O $grfName
	
	// 09JUN10 Variable/G gLeftLim=0,gRightLim=DimSize(w,2)-1,gLayer=0
	Variable/G gLeftLim=0,gRightLim,gLayer=0
	if((DimSize(w,3)>0 && (dimSize(w,2)==3 || dimSize(w,2)==4)))		// 09JUN10; will also support stacks with alpha channel.
		gRightLim=DimSize(w,3)-1					//image is 4D with RGB as 3rd dim
	else
		gRightLim=DimSize(w,2)-1					//image is 3D grayscale
	endif
	
	String/G imageName=nameOfWave(w)
	ControlInfo kwControlBar
	Variable/G gOriginalHeight= V_Height		// we append below original controls (if any)
	ControlBar gOriginalHeight+30

	GetWindow kwTopWin,gsize
	
	Slider WM3DAxis,pos={V_left+10,gOriginalHeight+9},size={V_right-V_left-kImageSliderLMargin1,16},proc=WM3DImageSliderProc
	// uncomment the following line if you want do disable live updates when the slider moves.
	// Slider WM3DAxis live=0	
	Slider WM3DAxis,limits={0,gRightLim,1},value= 0,vert= 0,ticks=0,side=0,variable=gLayer	
	
	SetVariable WM3DVal,pos={V_right-kImageSliderLMargin1+15,gOriginalHeight+9},size={60,14}
	SetVariable WM3DVal,limits={0,INF,1},title=" ",proc=WM3DImageSliderSetVarProc
	
	String cmd
	sprintf cmd,"SetVariable WM3DVal,value=%s",GetDataFolder(1)+"gLayer"
	Execute cmd

	ModifyImage $imageName plane=0
	// 
	WaveStats/Q w
	ModifyImage $imageName ctab= {V_min,V_max,,0}	// missing ctb to leave it unchanced.
	
	SetDataFolder dfSav
End

//*******************************************************************************************************
Function WM3DImageSliderSetVarProc1(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		// comment the following line if you want to disable live updates.
		case 3: // Live update
			Variable dval = sva.dval
			WM3DImageSliderProc("",0,0)
			break
	endswitch

	return 0
End
//*******************************************************************************************************


//////////////////////////////////////////////////////////////////////////////////
Function OCS()

string topwave,twname

Twname=WinName(0,1,1)

if(stringmatch(TWname,""))
	topwave=""
else

	GetWindow $TWname, wavelist
	wave /t w_wavelist

	topwave = w_wavelist[0][0]
endif


Filter2($topWave)

string newname=topWave+"_fil"

Display/k=1
AppendImage $newName
DoUpDate
WMAppend3DImageSlider(); DoUpdate
SizeImage(300)

end

/////////////////////////////////////

Function Filter2(image)
	wave image
	Variable Filtering3D=0
	
	
	if ((wavedims(image) < 2) | (wavedims(image) > 3)) 
		String AbortStr=Nameofwave(image)+" is not an image/stack."
		Abort AbortStr
	endif
	
	duplicate /o/free image, f_image
	
	string method
	
	string methods = "Average;FindEdges;Gauss;Hybridmedian;Max;Median;Min;Point;PCA;Sharpen;Sharpenmore"
	variable eN = 3, ii, zDim
	
	zDim=DimSize(image,2)
	
	//prompt topwave, "Image", popup, WaveList("*",";","")
	prompt method, "Method",popup, methods
	prompt eN, "Filter Size/Number of Principal Components"
	prompt Filtering3D, "Filter in z-axis (0/1)?"
	
	doPrompt /help="ImageFilter" "Filter parameters for "+nameofwave(image), method,eN, Filtering3D
	
	if(v_flag)
		Abort
	endif
	
	if(wavedims(image) == 3 && Filtering3D >0)
	
		strswitch(method)
			case "average":
				imagefilter /n=(eN) /o avg3d f_image
			break
			
			case "Gauss":
				imagefilter /n=(eN) /o gauss3d f_image
			break
			
			case "Hybridmedian":
				imagefilter /o hybridmedian f_image
			break
			
			case "Max":
				imagefilter /n=(eN) /o max3d f_image
			break
			
			case "Median":
				imagefilter /n=(eN) /o median3d f_image
			break
			
			case "Min":
				imagefilter /n=(eN) /o min3d f_image
			break
			
			case "Point":
				imagefilter /n=(eN) /o point3d f_image
			break
			
			case "PCA":
				 Wave PCA_res=SmoothByPCA(f_image, eN)
				 Fastop f_image=PCA_res
				Killwaves/z PCA_res, m_r, m_c, wv2dx
			break
			
			case "FindEdges":
				Print "FindEdges is a 2D-only method. Running 2D..."
				ImageStackFilter(f_image, eN, method)
			break
			
			case "Sharpen":
				Print "Sharpen is a 2D-only method. Running 2D..."
				ImageStackFilter(f_image, eN, method)
			break
			
			case "Sharpenmore":
				Print "Sharpen is a 2D-only method. Running 2D..."
				ImageStackFilter(f_image, eN, method)
			break
			
		endswitch
		
	elseif(wavedims(image) == 3 && Filtering3D <=0)
	
	
	//2D stack filtering
	strswitch(method)			
			case "PCA":
				 Wave PCA_res=SmoothByPCA(f_image, eN)
				 MultiThread f_image=PCA_res
				 Killwaves/z PCA_res, m_r, m_c, wv2dx
			break
			
			case "Hybridmedian":
				Print "Hybridmedian is a 3D-only method. Running 3D..."
				imagefilter /o hybridmedian f_image
			break
			
			Default:
				ImageStackFilter(f_image, eN, method)
			break
			
		endswitch
		
		
		
		
	Elseif(wavedims(image) == 2)
	
		strswitch(method)
			case "average":
				imagefilter /n=(eN) /o avg f_image
			break
			
			case "Gauss":
				imagefilter /n=(eN) /o gauss f_image
			break
			
			case "Hybridmedian":
				imagefilter /o FindEdges f_image
			break
			
			case "Max":
				imagefilter /n=(eN) /o max f_image
			break
			
			case "Median":
				imagefilter /n=(eN) /o median f_image
			break
			
			case "Min":
				imagefilter /n=(eN) /o min f_image
			break
			
			case "Point":
				imagefilter /n=(eN) /o point f_image
			break
			
			case "PCA":
				Abort "PCA works only with stacks"
			break
			
		endswitch
	
	
	Else
		abort "This Wave doesn't seem to be an image"
	endif
	
	string newname=nameofwave(image)+"_fil"
	
	duplicate /o f_image, $(newname)
	wave w=$(newname)

return 1
end

//////////////////////////Smoothing by PCA//////////////////////////////////

Function/wave Make2Dx(wv)		//convert 3D to 2D
	Wave wv
	
	Variable xd, yd, zd, ii, arow, acol
	
	xd = dimsize(wv,0)
	yd = DimSize(wv,1)
	zd = DimSize(wv,2)
	
	Make /o/n=(zd,xd*yd) wv2Dx
	
	
	for(ii=0;ii<xd*yd;ii+=1)
	
		arow = mod(ii,xd)
		acol = floor(ii/xd)
		
		Matrixop/o/free Beams = Beam(wv,arow,acol)
	
		wv2dx[][ii] = Beams[p]
		
	endfor
	
	setscale/p x,DimOffSet(wv,2),DimDelta(wv,2),WaveUnits(wv,2) wv2dx
	
	return wv2dx
end

///////////////////////////////////////////

Function/wave Make3Dx(wv,xd,yd)		//reverse Make2Dx
	Wave wv
	Variable xd, yd
	
	Variable ii, zd, arow, acol, npts
	
	
	zd=dimsize(wv,0)
	npts = xd*yd
	
	if(DimSize(wv,1) !=  npts)
		Abort "Mismatch"
	endif	
	
	Make /o/n=(xd,yd,zd) wv3D = NaN
	
	for(ii=0;ii<yd;ii+=1)
	
		arow = mod(ii,yd)
		acol = trunc(ii/xd)
	
		wv3d[][ii][] = wv[r][p+ii*(xd)]
	
	
	endfor

	
	return wv3d		//unscaled
end

/////////////////////////////////////////

Function/wave SmoothByPCA(wv, PC)
	Wave wv
	variable PC 		//number of principal components to leave
	
	Variable xdim, ydim
	

	xdim = dimsize(wv,0)
	ydim = dimsize(wv,1)

	Wave wv2d = Make2Dx(wv)

	pca /q/scmt/srmt/leiv wv2d
	

	
	wave M_R, M_C
	
	Duplicate/o/free M_R MRMod
	
	MRMod = 0
	MRMod[][0,PC-1] = M_R
	
	MatrixOP/o/free smooth2D=MRMod x M_C
	
	Wave Smoothed = Make3Dx(smooth2D,xdim,ydim)
	
	CopyScaling(wv,smoothed)
	
	return smoothed


End


///////////////////////////////////////////////////////////////


Function ImageStackFilter(wv, n, method)
	Wave Wv
	Variable n 
	String method
	//methods: avg; FindEdges; gauss; max; median; min; point; sharpen; sharpenmore
	
	Variable numPlanes
	
	numPlanes=DimSize(wv,2)


	// Create a wave to hold data folder references returned by Worker.
	// /DF specifies the data type of the wave as "data folder reference".
	Make/O/Free/DF/N=(numPlanes) dfw

	
	MultiThread dfw= ImageStackFilter_Worker(wv,p, n, method)

	
	// At this point, dfw holds data folder references to numPlanes free
	// data folders created by Worker. Each free data folder holds the
	// extracted and filtered data for one plane of the source 3D wave.

	// Create an output wave named out3D by cloning the first filtered plane
	DFREF df= dfw[0]
	Duplicate/O/free df:M_ImagePlane, out3D

	// Concatenate the remaining filtered planes onto out3D
	Variable ii
	for(ii=1; ii<numPlanes; ii+=1)
		df= dfw[ii]			// Get a reference to the next free data folder
		Concatenate {df:M_ImagePlane}, out3D
	endfor
	
	Fastop wv = out3d		//overwrite wv 
	
	// dfw holds references to the free data folders. By killing dfw,
	// we kill the last reference to the free data folders which causes
	// them to be automatically deleted. Because there are no remaining
	// references to the various M_ImagePlane waves, they too are
	// automatically deleted.
//	KillWaves dfw
End


// Extracts a plane from the 3D input wave, filters it, and returns the
// filtered output as M_ImagePlane in a new free data folder
ThreadSafe Static Function/DF ImageStackFilter_Worker(w3DIn, plane, n, method)
	WAVE w3DIn
	Variable plane, n
	String method
	
	//methods correspond to methods in MatrixFilter

	
	DFREF dfSav= GetDataFolderDFR()

	// Create a free data folder to hold the extracted and filtered plane 
	DFREF dfFree= NewFreeDataFolder()
	SetDataFolder dfFree
	
	// Extract the plane from the input wave into M_ImagePlane.
	// M_ImagePlane is created in the current data folder
	// which is a free data folder.
	ImageTransform/P=(plane) getPlane, w3DIn
	Wave M_ImagePlane

	// Filter the plane
	StrSwitch(method)
		Case "Average":
		Case "avg":
			MatrixFilter/O/N=(n) Avg,M_ImagePlane
		break
		
		Case "FindEdges":
			MatrixFilter/O FindEdges,M_ImagePlane
		break
		
		Case "gauss":
			MatrixFilter/O/N=(n) gauss,M_ImagePlane
		break
		
		Case "max":
			MatrixFilter/O/N=(n) max,M_ImagePlane
		break
		
		Case "median":
			MatrixFilter/O/N=(n) median,M_ImagePlane
		break
		
		Case "NaNZapMedian":
			MatrixFilter/O/N=(n) NaNZapMedian,M_ImagePlane
		break
		
		Case "min":
			MatrixFilter/O/N=(n) min,M_ImagePlane
		break
		
		Case "point":
			MatrixFilter/O point,M_ImagePlane
		break
		
		Case "sharpen":
			MatrixFilter/O sharpen,M_ImagePlane
		break
		
		Case "sharpenmore":
			MatrixFilter/O sharpenmore,M_ImagePlane
		break		
		
		Default:
			MatrixFilter/O/N=(n) avg,M_ImagePlane
		break
		
	Endswitch
	
	
	SetDataFolder dfSav

	// Return a reference to the free data folder containing M_ImagePlane
	return dfFree
End

Function SizeImage(Size,[WindowName])
	Variable Size
	string WindowName
	
	String TWName
	Variable xRange, yRange
	
	If(ParamIsDefault(WindowName))
		TWName=WinName(0,1,1)
	Else
		TWName=WindowName
	Endif
	
	DoUpdate
	
	GetAxis /w=$TWName/q left
	if(v_flag)
		GetAxis /w=$TWName/q right
	endif
	
	yRange = abs(v_max-v_min)
	
	GetAxis /w=$TWName/q bottom
	if(v_flag)
		GetAxis /w=$TWName/q top		//picture?
	endif
	xRange = abs(v_max-v_min)
	
	
	If(xRange > yRange)
		 ModifyGraph /w=$TWName width=(Size), Height=(Size*yRange/xRange)
	Else
		ModifyGraph /w=$TWName Height=(Size), Width=(Size/yRange*xRange)
	Endif
	
	DoUpDate
	ModifyGraph/w=$TWName height=0, width=0		//unlock size

End


Function CopyScaling(source, destination)
wave source, destination

variable dimnums, dimnumd
string snote, dnote
snote = note(source)
dnote = note(destination)

if (cmpstr(snote,dnote) != 0)	//are wave notes different?
	note destination, snote
endif


dimnums = wavedims(source)
dimnumd = wavedims(destination)


setscale d -inf, inf, waveunits(source,-1), destination

setscale /P x, DimOffset(source, 0),  DimDelta(source, 0),WaveUnits(source, 0), destination

if ((dimnums > 0) && (dimnumd > 0))
	setscale /P y, DimOffset(source, 1),  DimDelta(source, 1),WaveUnits(source, 1), destination
	
endif

if  ((dimnums > 1) && (dimnumd > 1))
	setscale /P z, DimOffset(source, 2),  DimDelta(source, 2),WaveUnits(source, 2), destination
endif

if  ((dimnums > 2) && (dimnumd > 2))
	setscale /P t, DimOffset(source, 3),  DimDelta(source, 3),WaveUnits(source, 3), destination
endif

End