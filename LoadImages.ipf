#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/////////////////////////////////////////////////////////////////////////////////////////////////////////

Function LoadMultipleImages()   ///// Load Images

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
			string header, s_info = "No header info available\r"
						
			ImageLoad /Q/O/C=-1/N=w_omeLoad filename
			
			wave w_omeLoad
			variable Nlayers=dimsize(w_omeLoad,2)
			//ImageLoad/T=tiff/S=0/C=(-1)/LR3D filename
			rename w_omeLoad,$S_filename
			
					
		header = s_info
		string sTimewave="Timewave_"+S_filename
	 
		
		make/o/n=(Nlayers) $sTimewave=0
		wave Timewave=$sTimewave 

		variable i
		variable v1=0

		for(i=0;i<Nlayers;i+=1)
		string xs=stringbykey("DeltaT", header[v1+1,inf], "=", " ")
		variable len= strlen(xs)	
			
		v1=strsearch(header, "DeltaT", v1+1)
		Timewave[i]= str2num(xs[1,len-1])		//remove ""
		
		endfor
				
			
		endfor
endif		
		
end


