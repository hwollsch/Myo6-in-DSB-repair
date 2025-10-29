/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory Images", style = "directory") input
//#@ File (label = "Input directory ROIs", style = "directory") ROIinput
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", choices = {".ome.tf2", ".ome.tif"}, style="listBox") suffix
#@ String (label = "Acquisition stopped during FRAP", choices={"Yes", "No"}, style="radioButtonHorizontal") acqStopped
#@ Integer (label = "Frames before FRAP (used for normalization)", value = 1, min = 1, max = 20, persist = false) framesBefore
#@ Integer (label="FRAP before frame ", min=0, max=999, value=20) checkFrames
#@ Integer (label="Exclude line ROI width ", min=1, max=999, value=6) exW
#@ Integer (label="Include line ROI width", min=1, max=999, value=15) inW
#@ Integer (label="Line width for averaging ROI", min=1, max=999, value=6) lineW
#@ String (label = "Read time stamp from file", choices={"Yes", "No"}, style="radioButtonHorizontal") timestamp
#@ Double (label = "Frame interval in sec", value=5, persist=false, style="format:#.##") frameInterval

// See also Process_Folder.py for a version of this code
// in the Python scripting language.
prebleachFrames = framesBefore;
FrameList = newArray(1, 6, 8, 10, 15, 20, 40, 55);
ROItypes = newArray("line", "rectangle", "freehand", "oval", "composite", "polygon");
plength = 3; //pad length for file naming, e.g. ..._ROI<001>...

fileEndingforSaving = ".ome.tif";
maxFrames = checkFrames;
excludeWidth = exW;
includeWidth = inW;

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}

function processFile(input, output, file) {
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
		
	print("Processing: " + input + File.separator + file);
	
	close("*");
	roiManager("reset");
	run("Clear Results");
	run("Bio-Formats Macro Extensions");
	
	LineWidth = lineW;
	PixelShiftX = 0;
	PixelShiftY = 0;

	RoiBorders = 50;
	fullpath = input + File.separator + file; //File.openDialog("Select a file");
	outputfile = replace(file, suffix, "");
	
	
	
    run("Bio-Formats", "open=[" + fullpath + "] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");
	
	//findStripeFrames
	changeFrames = changeProfile(maxFrames);
	changeFrames[0] = 0; //fixed first change Frame to 1;
	run("Slice Remover", "first=" + changeFrames[0] + 2 + " last=" + changeFrames[1] + 1 + " increment=1");
	ImageName = getTitle();
	//break;

	if (File.exists(input + File.separator + outputfile + ".roi")) {
		roiFileName = outputfile + ".roi";
		roiPath = input + File.separator +roiFileName;
		open(roiPath);
		roiManager("Add");
	}	else{
		roiFileName = outputfile + ".zip";
		roiPath = input + File.separator +roiFileName;
		open(roiPath);
	}
	  
	NoOfROIs = roiManager("count");
	print("There are " + NoOfROIs + " ROIs");
	for (i = 0; i < NoOfROIs; i++) {
		outputfileROI = outputfile + "_ROI" + IJ.pad(i+1, plength);
		CurrentNoOfROIs = roiManager("count");
		CurrentNoOfROIs = CurrentNoOfROIs - 1; //starts counting at zero 
		selectImage(ImageName);
		roiManager("Select", i);
		Roi.getCoordinates(xpoints, ypoints);
		Array.print(xpoints);
		x1 = parseFloat(xpoints[0]);
		y1 = parseFloat(ypoints[0]); 
		x2 = parseFloat(xpoints[1]);
		y2 = parseFloat(ypoints[1]);
		print("X1 = " + x1, "Y1 = " + y1);
		print("X2 = " + x2, "Y2 = " + y2);
		

		if (x1 <= x2) {
			xrect = x1 - RoiBorders;
			width = x2 - x1 + 2*RoiBorders;
		}
		else{
			xrect = x2 - RoiBorders;
			width = x1 - x2 + 2*RoiBorders;
		}
		if (y1 <= y2) {
			yrect = y1 - RoiBorders;
			height = y2 - y1 + 2*RoiBorders;
		}
		else{
			yrect = y2 - RoiBorders;
			height = y1 - y2 + 2*RoiBorders;
		}
		makeRectangle(xrect, yrect, width, height);
		roiManager("add");
		rectangleROI = CurrentNoOfROIs + 1;
		selectImage(ImageName);
		//break;
		ImageNameROI = "Image_ROI" + IJ.pad(i+1, plength);
		roiManager("Select", rectangleROI);
		run("Duplicate...", "title=Image_ROI" + IJ.pad(i+1, plength) + " duplicate");
		
		//generate ROIs for intensity readout
		//Line ROI
		makeLine(x1-xrect, y1-yrect, x2-xrect, y2-yrect);
		roiManager("add");
		lineROI = CurrentNoOfROIs + 2;
		
		//Rectangle/line ROI with width specified by user in LineWidth variable
		makeRotatedRectangle(x1-xrect, y1-yrect, x2-xrect, y2-yrect, LineWidth);
		roiManager("add");
		lineLineWidthROI = CurrentNoOfROIs + 3;
		
		
		//Background ROI exclude Intensity along line include intensity around/outside line
		makeRotatedRectangle(x1-xrect, y1-yrect, x2-xrect, y2-yrect, excludeWidth);
		roiManager("add");
		excludeROI = CurrentNoOfROIs + 4;
		makeRotatedRectangle(x1-xrect, y1-yrect, x2-xrect, y2-yrect, includeWidth);
		roiManager("add");
		includeROI = CurrentNoOfROIs + 5;
		roiManager("Select", newArray(excludeROI,includeROI));
		roiManager("XOR");
		roiManager("Add");
		backgroundROI = CurrentNoOfROIs + 6;
		

		roiManager("Select", lineROI);
		Roi.setStrokeWidth(1);
		IntensityTraceOriginal = tProfile();
		roiManager("Select", lineLineWidthROI);
		IntensityTraceOriginalLW = tProfile();
		roiManager("Select", backgroundROI)
		backgroundTrace = tProfile();
		
		selectImage(ImageName);
		roiManager("Select", rectangleROI);
		ImageNameROIDC = "DriftCorrectedImage_ROI" + IJ.pad(i+1, plength);
		run("Duplicate...", "title=DriftCorrectedImage_ROI" + IJ.pad(i+1, plength) + " duplicate");
		setSlice(1);
		run("StackReg ", "transformation=[Rigid Body]");
		roiManager("Select", lineROI);
		Roi.setStrokeWidth(1);
		IntensityTraceDriftCorrected = tProfile();
		roiManager("Select", lineLineWidthROI);
		Roi.setStrokeWidth(LineWidth);
		IntensityTraceDriftCorrectedLW = tProfile();
		roiManager("Select", backgroundROI)
		backgroundTraceDriftCorrected = tProfile();	
	
		//calculate background corrected traces (subtract bsckground ROI)
		bgCorrectedIntensityTraceOriginal = newArray(IntensityTraceOriginal.length);
		bgCorrectedTraceDC = newArray(IntensityTraceOriginal.length);
		bgCorrectedTraceOriginalLW = newArray(IntensityTraceOriginal.length);
		bgCorrectedTraceDCLW = newArray(IntensityTraceOriginal.length);;
		
		for (k = 0; k < IntensityTraceOriginal.length; k++) {
			bgCorrectedIntensityTraceOriginal[k] = IntensityTraceOriginal[k] - backgroundTrace[k];
			bgCorrectedTraceDC[k] = IntensityTraceDriftCorrected[k] - backgroundTraceDriftCorrected[k];
			bgCorrectedTraceOriginalLW[k] = IntensityTraceOriginalLW[k] - backgroundTrace[k];
			bgCorrectedTraceDCLW[k] = IntensityTraceDriftCorrectedLW[k] - backgroundTraceDriftCorrected[k];
		}	
	
		//calulate normalized traces (normalized to prebleach frames)
		normIntensityTraceOriginal = normTrace(IntensityTraceOriginal, prebleachFrames);
		normIntensityTraceDC = normTrace(IntensityTraceDriftCorrected, prebleachFrames);
		normIntensityTraceOriginalLW = normTrace(IntensityTraceOriginalLW, prebleachFrames);
		normIntensityTraceDCLW = normTrace(IntensityTraceDriftCorrectedLW, prebleachFrames);
		if (timestamp == "Yes") {
			timepoints = readTArray(fullpath);
		}
		else{
			timepoints = makeTArray(nSlices, frameInterval, changeFrames);	
		}
		
		Table.create("TraceOutput");
		Table.setColumn("Time in seceonds", timepoints);
		Table.setColumn("normOriginal", normIntensityTraceOriginal);
		Table.setColumn("normDriftCorrected", normIntensityTraceDC);
		Table.setColumn("normOriginalAveraged" + LineWidth, normIntensityTraceOriginalLW);
		Table.setColumn("normDriftCorrectedAveraged" + LineWidth, normIntensityTraceDCLW);
		Table.setColumn("Original", IntensityTraceOriginal);
		Table.setColumn("OriginalDriftCorrected", IntensityTraceDriftCorrected);
		Table.setColumn("OriginalAveraged" + LineWidth, IntensityTraceOriginalLW);
		Table.setColumn("OriginalDriftCorrectedAveraged" + LineWidth, IntensityTraceDriftCorrectedLW);
		Table.setColumn("bgCorrected", bgCorrectedIntensityTraceOriginal);
		Table.setColumn("bg+dcCorrected", bgCorrectedTraceDC);
		Table.setColumn("bgCorrectedAveraged" + LineWidth, bgCorrectedTraceOriginalLW);
		Table.setColumn("bg+dcCorrectedAveraged" + LineWidth, bgCorrectedTraceDCLW);
		Table.setColumn("backgroundOnly", backgroundTrace);
		Table.setColumn("backgroundDCOnly", backgroundTraceDriftCorrected);
		

		print("Saving to: " + output);
		saveAs("results", output + File.separator + outputfileROI + ".csv");
		ResultsName = getInfo("window.title");
		selectWindow(ResultsName);
		run("Close");
		
	if(!File.isDirectory(output + File.separator + outputfile)){
		File.makeDirectory(output + File.separator + outputfile);
	}
	selectImage(ImageName);
	getDimensions(width, height, channels, noSlices, noFrames);
	if( noSlices > noFrames){
		print("You have more z-positions than frames. Maybe dimensions are assigned wrongly - swapping slices and frames!" )
		noFrames = noSlices;
	}

	for (n = 0; n < FrameList.length; n++) {
		if(FrameList[n] <= noFrames){
			selectImage(ImageNameROI);
			setSlice(FrameList[n]);
			run("Duplicate...", "ignore use");
			savename1 = output + File.separator + outputfile + File.separator + outputfileROI + "_Frame_" + FrameList[n] + fileEndingforSaving;
			savename2 = output + File.separator + outputfile + File.separator + outputfileROI + "_Frame_" + FrameList[n] + ".jpg";
			run("OME-TIFF...", "save=[" + savename1 + "] export compression=Uncompressed");
			saveAs("JPG", savename2);
			close();
		}
		else{
			if( FrameList[n-1] == noFrames){
				break;
				print("Broke :(");
			}
			else{
			selectImage(ImageNameROI);
			setSlice(noFrames);
			run("Duplicate...", "ignore use");
			savename1 = output + File.separator + outputfile + File.separator + outputfileROI + "_Frame_" + noFrames + fileEndingforSaving;
			savename2 = output + File.separator + outputfile + File.separator + outputfileROI + "_Frame_" + noFrames + ".jpg";
			run("OME-TIFF...", "save=[" + savename1 + "] export compression=Uncompressed");
			saveAs("JPG", savename2);
			close();
			break;
			}
		}
	}			
	selectImage(ImageNameROI);
	savename1 = output + File.separator + outputfile + File.separator + outputfileROI + fileEndingforSaving;
	run("OME-TIFF...", "save=[" + savename1 + "] export compression=Uncompressed");
	////run("OME-TIFF...", "save=X:/cf01-microscopy/Marton/Virender/output2.ome.tf2 export compression=Uncompressed");
	selectImage(ImageNameROIDC);
	savename2 = output + File.separator + outputfile + File.separator + outputfileROI + "_DC." + fileEndingforSaving;
	run("OME-TIFF...", "save=[" + savename2 + "] export compression=Uncompressed");
	}
	//break;
Ext.close();
close("*");
}


function tProfile(){
	if (nSlices==1) exit("This macro requires a stack");
      //n = getSliceNumber();
      means = newArray(nSlices);
      for (i=1; i<=nSlices; i++) {
          setSlice(i);
          getStatistics(area, mean);
          means[i-1] = mean;
      }
      return means;
}

function readTArray(file){
	
	TArray = newArray();
	Ext.setId(file);
	Ext.getImageCount(imageCount);
	TArray = newArray(imageCount);
	
	for (no = 0; no < imageCount; no++) {
		Ext.getPlaneTimingDeltaT(TArray[no], no);	
	}
	
	Ext.close();
	return TArray;
}

function makeTArray(imageCount, frameInterval,changeFrames){
	TArray = newArray(imageCount);
	nn = 0;
	for (i=1; i<=imageCount; i++){
		TArray[i-1] = nn;
		if(i<changeFrames[0]+1){
		nn = nn+frameInterval;
		} else if (i==changeFrames[0]+1){
			nn = nn+(changeFrames[1]+1)*frameInterval;
		}
		else{
			nn = nn+frameInterval;
			}
	}
	return TArray;
}

function normTrace(inputArray, prebleachFrames){
	
	prebleach = Array.slice(inputArray, 0, prebleachFrames);
	Array.getStatistics(prebleach, prebleach_min, prebleach_max, prebleach_mean, prebleach_stdDev);
	outputArray =newArray(inputArray.length);
	
	for (i=0; i<outputArray.length; i++) {
		outputArray[i] = inputArray[i]/prebleach_mean;
	}
	return outputArray;
}

function changeProfile(lastFrame){
	if (nSlices==1) exit("This macro requires a stack");
     
    means = newArray(lastFrame-1);
    for (i=1; i<=lastFrame; i++) {
          setSlice(i);
          getStatistics(area1, mean1);
          setSlice(i+1);
          getStatistics(area2, mean2);
          meanDiff = Math.abs(mean2-mean1);
          means[i-1] = meanDiff;
      }
      rankArray = Array.rankPositions(means);
      maxChanges = Array.slice(rankArray,rankArray.length-2,rankArray.length);
      Array.sort(maxChanges);
      return maxChanges;
}