#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include <FilterDialog> menus=0
#include <All IP Procedures>
#include <Image Saver>
#include <Ternary Diagram>
#include <Pole and Zero Filter Design> menus=0
#include <Scatter Plot Matrix 2>


//  simpleICA(inX,reqComponents,w_init)
//  Parameters:
// 	inX is a 2D wave where columns contain a finite mix of independent components.
// 	reqComponents is the number of independent components that you want to extract.
//		This number must be less than or equal to the number of columns of inX.
//	w_init is a 2D wave of dimensions (reqComponents x reqComponents) and contains 
//  		an estimate of the mixing matrix.  You can simply pass $"" for this parameter
//		so the algorithm will use an equivalent size matrix filled with enoise().
//
//	The results of the function are the waves ICARes and WunMixing.  ICARes is a 2D 
//	wave in which each column contains an independent component.  WunMixing is a 2D
// 	wave that can be used to multiply the (re)conditioned input in order to obtain the unmixed 
//	components.
//
//	The code below implements the "deflation" approach for fastICA.  It is based on the 
//	fastICA algorithm: Hyvärinen,A (1999). Fast and Robust Fixed-Point Algorithms 
//	for Independent Component Analysis. IEEE Transactions on Neural Networks, 10(3),626-634.
// 	
//	 See testing example below the main function.

Function simpleICA()

string sinX
Variable reqComponents
string sw_int

	Prompt sinX, "Mixed Wave:", popup Wavelist("*", ";", "dims:2")
	Prompt sw_int, "Estimated mixing matrix:"
		prompt reqcomponents, "Required Components:"

	DoPrompt "Initial Parameters",sinx,sw_int, reqcomponents

	If (v_flag)
		return -1
	endif

	wave inx=$sinx  
	
	wave w_int = $sw_int
	
	
	// The following 3 variables can be converted into function arguments.
	Variable maxNumIterations=1000
	Variable tolerance=1e-8
	Variable alpha=1
 
	Variable i,ii
	Variable iteration 
	Variable nRows=DimSize(inX,0)
	Variable nCols=DimSize(inX,1)
 
	// check the number of requested components:
	if(reqComponents>min(dimSize(inX,0),dimSize(inX,1)))
		doAlert 0,"Bad requested number of components"
		return 0
	endif
 
	// Never mess up the original data
	Duplicate/O/Free inX,xx					
 
	// Initialize the w matrix if it is not provided.	
	if(WaveExists(w_int)==0)
		Make/O/N=(reqComponents,reqComponents) w_init=enoise(1)
	endif
 
	// condition and transpose the input:
	MatrixOP/O xx=(NormalizeCols(subtractMean(xx,1)))^t
 
	// Just like PCA:
	MatrixOP/O/Free V=(xx x (xx^t))/nRows
	MatrixSVD V
	// M_VT is not used here.
	Wave M_U,W_W,M_VT									
	W_W=1.0/sqrt(w_w)
	MatrixOP/O/Free D=diagonal(W_W)
	MatrixOP/O/FREE K=D x (M_U^t)			
	KillWaves/z W_W,M_U,M_VT			 
 
	Duplicate/Free/R=[0,reqComponents-1][] k,kk
	Duplicate/O/FREE kk,k									
 
	// X1 could be output as PCA result.	
	MatrixOP/O/FREE X1=K x xx								
	// create and initialize working W; this is not an output!
	Make/O/Free/N=(reqComponents,reqComponents) W=0						
 
	for(i=1;i<=reqComponents;i+=1)										
		MatrixOP/O/FREE lcw=row(w_init,i-1)
               // decorrelating 							
		if(i>1)													
			Duplicate/O/Free lcw,tt									
			tt=0												
			for(ii=0;ii<i;ii+=1)
				MatrixOP/O/Free r_ii=row(W,ii)				// row ii of matrix W		
				MatrixOP/O/FREE ru=sum(lcw*r_ii)			// dot product		
				Variable ks=ru[0]
				MatrixOP/O/Free tt=tt+ks*r_ii							
			endfor
			MatrixOP/O/FREE lcw=lcw-tt								
		endif
		MatrixOP/O/Free lcw=normalize(lcw)						
		// iterate till convergence:	
		for(iteration=1;iteration<maxNumIterations;iteration+=1)				
			MatrixOP/O/Free wxProduct=lcw x x1						
			// should be supported by matrixop :(
			Duplicate/O/Free wxProduct,gwx
			gwx=tanh(alpha*wxProduct)									
			Duplicate/Free/R=[reqComponents,nRows] gwx,gwxf				 
			Make/O/Free/N=(reqComponents,nRows) gwxf
			// repeat the values from the first row on.
			gwxf=gwx[q]										
			Duplicate/O/FREE gwxf,gwx
			MatrixOP/O/Free x1gwxProd=x1*gwx							 
			Duplicate/O/FREE wxProduct,gwx2									 
			gwx2=alpha*(1-(tanh(alpha*wxProduct))^2)
			Variable theMean=mean(gwx2)
			MatrixOP/O/Free    wPlus=(sumRows(x1gwxProd)/numCols(x1gwxProd))^t-theMean*lcw	
			// reduce components						 
			Redimension/N=(1,reqComponents) wPlus				
			// starting from the second component;
			if(i>1)												
				Duplicate/O/FREE wPlus,tt									 
				tt=0												 
				for(ii=0;ii<i;ii+=1)					                  
					MatrixOP/O/Free r_ii=row(W,ii)				 
					MatrixOP/O/FREE ru=wPlus.(r_ii^t)							 
					ks=ru[0]
					MatrixOP/O tt=tt+ks*r_ii							 
				endfor										            
				wPlus=wPlus-tt							       			 
			endif
			MatrixOP/O/FREE wPlus=normalize(wPlus)							 
			MatrixOP/O/Free limV=abs(mag(sum(wPlus*lcw))-1)		
			printf "Iteration %d, diff=%g\r",iteration,limV[0]
			lcw=wPlus
			if(limV[0]<tolerance)
				break
			endif
		endfor
		// store the computed row in final W.
        	W[i-1][]=lcw[q]													
	endfor			// loop over components
 
	//  Calculate the un-mixing matrix
	MatrixOP/O WunMixing=W x K					
	// 	Un-mix; 					
	MatrixOP/O ICARes=(WunMixing x xx)^t								
End
 
 
/////////////////////////////////////////////////////////////////////////


Function correlatingcomponents()

String sFuenteComponentes, sFuenteROI

//variable file,totplanes,images,deleteimages

	Prompt sFuenteComponentes, "Componentes ICA:", popup Wavelist("*", ";", "DIMS:2")
	Prompt sFuenteROI, "Concatenated Sweeps", popup Wavelist("*", ";", "DIMs:2")
	//prompt file, "File Number:"
	//prompt totplanes, "Total planes:"
	//Prompt Images, "Images per plane:"
	//Prompt deleteimages, "Delete # Images:"
	
	
	DoPrompt "Select waves",sFuenteComponentes,sFuenteROI//,file,totplanes,Images,deleteimages

	If (v_flag)
		return -1
	endif
	
wave wFuenteComp=$sFuenteComponentes
wave wFuenteROI=$sFuenteROI


variable TotalColComp= DimSize(wFuentecomp,1 ) 
variable TotalColROI= DimSize(WFuenteROi,1 )
variable i 

For(i=0;i<TotalColComp;i+=1)

	String OutputComp=sFuenteComponentes+"_col_"+num2str(i)

	imagetransform/g=(i) getcol wFuenteComp

	wave w_extractedcol

	duplicate/o W_ExtractedCol, $OutputComp
	killwaves W_extractedcol

endfor

For(i=0;i<TotalColROI;i+=1)

	String OutputROI=sFuenteROI+"_col_"+num2str(i)

	imagetransform/g=(i) getcol wFuenteROI

	wave w_extractedcol

	duplicate/o W_ExtractedCol, $OutputROI
	killwaves W_extractedcol

endfor

variable j

make/o/n=(totalcolcomp,totalcolROI) Correl_Comp_vs_ROI

wave  Correl_Comp_vs_ROI
 
for(i=0;i<totalcolcomp;i+=1)

string swaveA=sFuenteComponentes+"_col_"+num2str(i)
wave waveA=$swaveA

	for(j=0;j<totalcolroi;j+=1)


	string swaveb= sFuenteROI+"_col_"+num2str(j)
	wave waveb=$swaveb

	Correl_Comp_vs_ROI [i][j]= StatsCorrelation(waveA, waveB )

endfor 
endfor
end


////////////////////////////////////////////////////////////////////////////////////////

Function Concatenando()

//Concatenate Stacks of sweeps to perform ICA or Correlation of ICA components against each ROI.

String sFuenteROI

	Prompt sFuenteROI, "Stack Sweeps", popup Wavelist("Stackswe*", ";", "")
	
	
	DoPrompt "Select waves",sFuenteROI

	If (v_flag)
		return -1
	endif

wave wFuenteROI=$sFuenteROI

imagetransform/p=0 getplane wFuenteROI

wave M_imageplane

duplicate/o M_imageplane, Concatenado

wave concatenado

variable Totalsweeps= DimSize(wFuenteROI,2 ) 
variable i

for(i=1;i<totalsweeps;i+=1)

	imagetransform/p=(i) getplane wfuenteROI

	concatenate/np=0 {M_imageplane},concatenado
	
endfor

end
