#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Menu "Loaders"

	"Load ABF file", LoadABF()
	 "Load ABF 2.0 file",HT_ImportAbfFile()
	"Load WinWCP file", LoadWINWCP()	
	 "-"
	"Load Multiple Images", LoadMultipleImages()
	"Load Multiple Delimited Text Files", LoadMultipleDelimitedTextFiles()
		
End


Menu "Imaging"

	"Draw ROIs", ROIImgProc()  
	"Automated ROIs Analysis",  AutoROIImgProcV2()
	"Image Sequence Slider/2", WMAppend3DImageSlider();
	"Image Line Profiles/3", WMCreateImageLineProfileGraph();
	"Image Filtering", OCS();
	"Response Image", ImagenRespuestaWideField()
	SubMenu "Bleaching Correction"
	"PYXEL BY PYXEL",CorreccionBleachingBYPIXEL()
	"ROI DELIMITED", CorreccionBleachingImagenBYROI()
	end
	
	SubMenu "Aplicación Local"
	"Integrate Current trace", IntegrarCorriente()
	"Extraer Datos Imaging",ExtraerDatosImg()
	end
	
	SubMenu "Swept Field"
	"Swept Field Analysis", SweptFieldAnalysisFeeder()
	"Concatenate Planes", ConcatenadoPlanos()
	"Generate Response Image Stack", ImagenRespuesta()
	"Transform to 16 bit Images for Export",  NormalizeImages()
	"Generate Single Pulse Timing Data", SyncingSweepsSinglePulse() 
	"Concatenate Ephys Waves", concatenateephys()
	"Automated ROIs Analysis Single Pulse",  AutoImgProcSFSinglePulse() 
	end
end	


Menu "Utilities"
	"Trace Slider/1",SliderWAVES();	

	"Concatenate Files", ConcatenateFiles()	
	
	
	
	
	end
	
	SubMenu  "ICA"

			"Concatenate Sweeps", Concatenando()
			"Fast ICA" , simpleICA()
			"ROI vs Component correlation", correlatingcomponents()
			
	end

	
End
