#pragma rtGlobals=1		// Use modern global access method.
//

Function LoadWINWCP()


// LOADING FILE PARAMETERS FROM HEADER 


String VER
variable VVER

string VERPROG
variable vVERPROG

string CTIME

string RTIMESECS
	 
string RTIME
 
string NBH
variable VNBH

string ADCMAX
variable VADCMAX

string NC
variable VNC

string NBA
variable VNBA

string NBD
variable VNBD

string AD
variable VAD

string NR
variable VNR

string DT
variable VDT

string NZ
variable VNZ

string YO0
 variable VYO0
string YU0
variable VYU0
string YN0
variable VYN0
string YG0
variable VYG0
string YZ0
variable VYZ0
string YR0
variable VYR0

	string YO1
	variable VYO1
	string YU1
	variable VYU1
	string YN1
	variable VYN1
	string YG1
	variable VYG1
	string YZ1
	variable VYZ1
	string YR1
	variable VYR1
 
	 string YO2
	variable VYO2
	string YU2
	variable VYU2
	string YN2
	variable VYN2
	string YG2
	variable VYG2
	string YZ2
	variable VYZ2
	string YR2
	variable VYR2
	
	string YO3
	variable VYO3
	string YU3
	variable VYU3
	string YN3
	variable VYN3
	string YG3
	variable VYG3
	string YZ3
	variable VYZ3
	string YR3
	variable VYR3
	
	
string TXPERC
variable VTXPERC
string PKPAVG
variable VPKPAVG
string NSVCHAN
variable  VNSVCHAN
string NSVALIGN
variable VNSVALIGN
string NSVTYPR
variable VNSVTYPR
string NSVS2P
variable VNSVS2P
string NSVCUR0
variable VNSVCUR0

string ascii

variable refnum
string/g CurrentPath

open/d/r/mult=1/t="????" refnum as ""
string outputPaths = S_fileName
	
	if (strlen(outputPaths) == 0)
		Print "Cancelled"
	else
	
		Variable numFilesSelected = ItemsInList(outputPaths, "\r")
		Variable K
		
		for(K=0; K<numFilesSelected; K+=1)
			String path = StringFromList(K, outputPaths, "\r")
			Printf "%d: %s\r", K, path	
			CurrentPath= path
		
	
open/r/t="????" refnum as CurrentPath
	fstatus refnum
	
	fReadline/T=(num2char(13)) refnum, ver
		sscanf VER, "VER=%f ", vver
		
		
	fReadline/n=11/T=(num2char(13)) refnum, verprog
	sscanf VERprog, "\nVERPROG=V%f ", vverprog
	
	if(vverprog==5)
		
		fReadline/T=(num2char(13)) refnum, ctime
		fReadline/T=(num2char(13)) refnum, ctime
	else
		fReadline/T=(num2char(13)) refnum, ctime

	endif
	
	
	fReadline/T=(num2char(13)) refnum, rtimesecs
	
	fReadline/T=(num2char(13))refnum,rtime
	
	fReadline/T=(num2char(13)) refnum,nbh
		sscanf NBH,"\nNBH=%f", VNBH

	fReadline/T=(num2char(13)) refnum, adcmax
		sscanf ADCMAX,"\nADCMAX=%f", VADCMAX

	fReadline/T=(num2char(13)) refnum,nc
		sscanf NC,"\nNC=%f", VNC

	fReadline/T=(num2char(13)) refnum, nba
		sscanf NBA,"\nNBA=%f", VNBA

	fReadline/T=(num2char(13)) refnum,nbd
		sscanf NBD,"\nNBD=%f", VNBD

	fReadline/T=(num2char(13)) refnum, ad
		sscanf AD,"\nAD=%f", VAD

	fReadline/T=(num2char(13)) refnum, nr
		sscanf NR,"\nNR=%f", VNR
		
	fReadline/T=(num2char(13)) refnum,dt
		sscanf DT,"\nDT=%f", VDT

	fReadline/T=(num2char(13)) refnum, nz
		sscanf NZ,"\nNZ=%f", VNZ

	fReadline/T=(num2char(13)) refnum, yo0
		sscanf yo0,"\nYO0=%f", Vyo0

	fReadline/T=(num2char(13))refnum, yu0
		sscanf yu0,"\nYU0=%f", vyu0

	fReadline/T=(num2char(13))refnum, yn0
		sscanf yn0,"\nYN0=%f", Vyn0

	fReadline/T=(num2char(13)) refnum,yg0
		sscanf YG0,"\nYG0=%f", VYG0

	fReadline/T=(num2char(13)) refnum, yz0
		sscanf YZ0,"\nYZ0=%f", VYZ0

	fReadline/T=(num2char(13)) refnum,yr0
		sscanf YR0,"\nYR0=%f", VYR0
		
	
	switch(VNC)	// numeric switch
	case 2:		// execute if case matches expression
	
	fReadline/T=(num2char(13)) refnum, yo1
		sscanf yo1,"\nYO1=%f", Vyo1

	fReadline/T=(num2char(13))refnum, yu1
		sscanf yu1,"\nYU1=%f", vyu1

	fReadline/T=(num2char(13))refnum, yn1
		sscanf yn1,"\nYN1=%f", Vyn1

	fReadline/T=(num2char(13)) refnum,yg1
		sscanf YG1,"\nYG1=%f", VYG1

	fReadline/T=(num2char(13)) refnum, yz1
		sscanf YZ1,"\nYZ1=%f", VYZ1

	fReadline/T=(num2char(13)) refnum,yr1
		sscanf YR1,"\nYR1=%f", VYR1

		break						// exit from switch
	
	case 3:		// execute if case matches expression
	
	fReadline/T=(num2char(13)) refnum, yo1
		sscanf yo1,"\nYO1=%f", Vyo1

	fReadline/T=(num2char(13))refnum, yu1
		sscanf yu1,"\nYU1=%f", vyu1

	fReadline/T=(num2char(13))refnum, yn1
		sscanf yn1,"\nYN1=%f", Vyn1

	fReadline/T=(num2char(13)) refnum,yg1
		sscanf YG1,"\nYG1=%f", VYG1

	fReadline/T=(num2char(13)) refnum, yz1
		sscanf YZ1,"\nYZ1=%f", VYZ1

	fReadline/T=(num2char(13)) refnum,yr1
		sscanf YR1,"\nYR1=%f", VYR1
	
	fReadline/T=(num2char(13)) refnum, yo2
		sscanf yo2,"\nYO2=%f", Vyo2

	fReadline/T=(num2char(13))refnum, yu2
		sscanf yu2,"\nYU2=%f", vyu2

	fReadline/T=(num2char(13))refnum, yn2
		sscanf yn2,"\nYN2=%f", Vyn2

	fReadline/T=(num2char(13)) refnum,yg2
		sscanf YG2,"\nYG2=%f", VYG2

	fReadline/T=(num2char(13)) refnum, yz2
		sscanf YZ2,"\nYZ2=%f", VYZ2

	fReadline/T=(num2char(13)) refnum,yr2
		sscanf YR2,"\nYR2=%f", VYR2
		break
		
	case 4:		// execute if case matches expression
	fReadline/T=(num2char(13)) refnum, yo1
		sscanf yo1,"\nYO1=%f", Vyo1

	fReadline/T=(num2char(13))refnum, yu1
		sscanf yu1,"\nYU1=%f", vyu1

	fReadline/T=(num2char(13))refnum, yn1
		sscanf yn1,"\nYN1=%f", Vyn1

	fReadline/T=(num2char(13)) refnum,yg1
		sscanf YG1,"\nYG1=%f", VYG1

	fReadline/T=(num2char(13)) refnum, yz1
		sscanf YZ1,"\nYZ1=%f", VYZ1

	fReadline/T=(num2char(13)) refnum,yr1
		sscanf YR1,"\nYR1=%f", VYR1
	
	fReadline/T=(num2char(13)) refnum, yo2
		sscanf yo2,"\nYO2=%f", Vyo2

	fReadline/T=(num2char(13))refnum, yu2
		sscanf yu2,"\nYU2=%f", vyu2

	fReadline/T=(num2char(13))refnum, yn2
		sscanf yn2,"\nYN2=%f", Vyn2

	fReadline/T=(num2char(13)) refnum,yg2
		sscanf YG2,"\nYG2=%f", VYG2

	fReadline/T=(num2char(13)) refnum, yz2
		sscanf YZ2,"\nYZ2=%f", VYZ2

	fReadline/T=(num2char(13)) refnum,yr2
		sscanf YR2,"\nYR2=%f", VYR2
	
			fReadline/T=(num2char(13)) refnum, yo3
		sscanf yo3,"\nYO3=%f", Vyo3

	fReadline/T=(num2char(13))refnum, yu3
		sscanf yu3,"\nYU3=%f", vyu3

	fReadline/T=(num2char(13))refnum, yn3
		sscanf yn3,"\nYN3=%f", Vyn3

	fReadline/T=(num2char(13)) refnum,yg3
		sscanf YG3,"\nYG3=%f", VYG3

	fReadline/T=(num2char(13)) refnum, yz3
		sscanf YZ3,"\nYZ3=%f", VYZ3

	fReadline/T=(num2char(13)) refnum,yr3
		sscanf YR3,"\nYR3=%f", VYR3	
	
		break

	
	endswitch
	
		
		
	fReadline/T=(num2char(13)) refnum, txperc
		sscanf TXPERC,"\nTXPERC=%f", VTXPERC

	fReadline/T=(num2char(13)) refnum, pkpavg
		sscanf PKPAVG,"\nPKPAVG=%f", VPKPAVG

	fReadline/T=(num2char(13)) refnum, nsvchan
		sscanf NSVCHAN,"\nNSVCHAN=%f", VNSVCHAN

	fReadline/T=(num2char(13)) refnum, nsvalign
		sscanf NSVALIGN,"\nNSVALIGN=%f", VNSVALIGN

	fReadline/T=(num2char(13)) refnum, nsvtypr
		sscanf NSVTYPR,"\nNSVTYPR=%f", VNSVTYPR

	fReadline/T=(num2char(13)) refnum, nsvs2p
		sscanf NSVS2P,"\nNSVS2P=%f", VNSVS2P

	fReadline/T=(num2char(13)) refnum, nsvcur0
			sscanf NSVCUR0,"\nNSVCUR0=%f", VNSVCUR0

	fReadline/T=(num2char(10)) refnum, ascii

close refnum



string ExecuteLoading="GBLoadWave/O/B/Q/N=WCPFullWave/T={16,4}/W=1/S=("+num2str(VNBH)+") (CurrentPath)"
Execute ExecuteLoading

string ExecuteLoading1="GBLoadWave/B/q/N=AnalysisBlock/T={2,2}/S=1036/W=1/u=5 (CurrentPath)"
Execute ExecuteLoading1

Wave AnalysisBlock0
VAD=AnalysisBlock0[3]

Wave WCPFullWave0  //wave that contains all the data loaded
/////////////////////////////////////////////////////////////////////17abr2018
///////////////////////////////////////////////////////////////////////Introducimos doble formato de nombre de WinWCP files, el de Marce y el mio


	variable  File
	string sFile 
	string Skip

Variable CheckStart = str2num(S_filename[0])
	if(numtype(CheckStart) == 0)
	String UserName = "MM"
	String CellN = "A"
	Prompt UserName, "Identificar iniciales"
	Prompt CellN, "Identificar celula (A, B, etc)"
	DoPrompt "WCP Loading", UserName, CellN
	If(V_flag)
		return -1
	endif
	
	Variable Xprime = str2num(S_filename[2])

	//12may16 agregado:
	//cambia el nombre de CurrentFileName a la vieja nomenclatura: "JG16XYYA"
	if(Xprime == 0)					//para meses (X) entre 1 y 9
		string/g CurrentFilename="MM"+S_filename[0,1]+S_Filename[3,5]+CellN
	elseif(Xprime == 1)				//para meses (X) entre 10 y 12
		Variable X = str2num(S_Filename[3])
		switch(X)
		case 0:
			string/g CurrentFilename= UserName+S_filename[0,1]+"O"+S_Filename[4,5]+CellN
			break
		case 1:
			string/g CurrentFilename= UserName+S_filename[0,1]+"N"+S_Filename[4,5]+CellN
			break
		case 2:
			string/g CurrentFilename= UserName+S_filename[0,1]+"D"+S_Filename[4,5]+CellN
			break
		endswitch
	
	endif

	Skip= s_filename[0,5]+"_%f"
	sscanf S_filename, Skip ,file
	sprintf sFile,"%04d",file

else
	String/g CurrentFilename = s_filename[0,7]
	
	Skip= Currentfilename+"_001.%f"
	sscanf S_filename, Skip ,file
	sprintf sFile,"%04d",file

	
endif

		
Variable SweepN	
Variable Channel
Variable VChannelGain

For(Channel=0;Channel<VNC;Channel+=2) /////ACA deberia ser Channel+=1 si se desea cargar archivos de Voltaje
	
	For(sweepn=0;sweepn<VNR;sweepn+=1)
	
		switch(Channel)	// numeric switch
			case 0:	
			String SweepName=CurrentFilename+"_"+sFile+"_"+num2str(SweepN+1)+"_1"
			VChannelGain = VYG0
			break
			
			case 1:
			SweepName=CurrentFilename+"_"+sFile+"_"+num2str(SweepN+1)+"_V1"
			VChannelGain = VYG1
			break
			
			case 2:
			SweepName=CurrentFilename+"_"+sFile+"_"+num2str(SweepN+1)+"_2"
			VChannelGain = VYG2
			break
			
			case 3:
			SweepName=CurrentFilename+"_"+sFile+"_"+num2str(SweepN+1)+"_V2"
			VChannelGain = VYG3
			break
			
		endswitch 
		
		Make/N=(512*VNBD/(2*VNC))/o $Sweepname
		Wave wSweepName=$Sweepname

		Multithread WSweepName[] = WCPFullWave0[p*VNC+Channel+((VNBD*512/2)+VNBA*512/2)*SweepN+VNBA*512/2]*(VAD/(VADCMAX*VChannelGain))
   	
   		SetScale/P x 0,VDT, "s", wSweepname
		
		Nvar SampleInterval
		SampleInterval= VDT *1e6
		
		note/k WSweepName, ReplaceStringByKey("Path", note(WSweepName), outputpaths, "=", ";")
		note/k WSweepName, ReplaceStringByKey("RecordingTime", note(WSweepName), RTIME[7,inf], "=", ";")
	   	note/k WSweepName, ReplaceStringByKey("NumberOfChannels", note(WSweepName), num2str(VNC), "=", ";")
		note/k WSweepName, ReplaceStringByKey("SampleInterv", note(WSweepName), num2str(VDT), "=", ";")
		note/k WSweepName, ReplaceStringByKey("NumberOfRecords", note(WSweepName), num2str(VNR), "=", ";")
		note/k WSweepName, ReplaceStringByKey("NumberOfSamplesPerChannel", note(WSweepName), num2str(VNBD * 512/VNC/2), "=", ";")
		
	Endfor //cierra ciclo sweeps
	
Endfor //cierra ciclo sobre chanal
endfor
endif

killwaves WCPFullWave0, AnalysisBlock0

end
