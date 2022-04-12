//This script is for segmenting and analyzing tubular AP1 structures in Z-stack images.
//Open the Airyscan processed Z-stack image of the AP1 tubule and follow the directions.
//Can be multi-channel image, but complete crop step on the channel you want to analyze. 

mfSize = 15;
//phansalkarSize = 15;

imageName = getTitle();
directory = getDirectory("image");
analysisdirectory = directory + imageName + "_analysis";
File.makeDirectory(analysisdirectory);
run("8-bit");

//selecting region + slice to analyze. can be different per cell 
if (roiManager("count") != 0) {
	roiManager("deselect");
	roiManager("delete");
}

setTool("polygon");

waitForUser("Draw an ROI around each region of the cell you want to analyze. Make sure to save the ROI at the z-position you want to analyze. Multiple ROI's are possible");

//Crop images to show only selected area. Output area as print statements
roiNum = roiManager("count");
roiManager("save", analysisdirectory + "/" + "cropped_area" + ".zip");
for (i = 0; i < roiNum; i++) {
	roiManager("select", i);
	getStatistics(area);
	//print("area of cell " + i + " is " + area);
	print(area);
}

for (i = 0; i < roiNum; i++) {
	cellDirectory = analysisdirectory + "/" + "cell_" + (i);
	File.makeDirectory(cellDirectory);
	selectWindow(imageName);
	roiManager("select", i);
	Roi.getPosition(channel, slice, frame);
	run("Duplicate...", "duplicate slices=" + slice); 
	roiManager("add");
	cropName = getTitle();
	run("Create Mask");
	maskName = "Mask-" + imageName + "-" + i;
	selectWindow("Mask");
	rename(maskName);
	run("Invert");
	imageCalculator("Subtract create stack", cropName, maskName);
	cropName = "Crop-" + imageName + "-" + i;
	rename(cropName);
	run("Duplicate...", "duplicate");
	MF_cropName = "MF-" + cropName + "-" + i;
	rename(MF_cropName);
	run("Median...", "radius=" + mfSize + " stack");
	imageCalculator("Subtract create stack", cropName, MF_cropName);
	bs_cropName = "BS-" + cropName + "-" + i;
	rename(bs_cropName);
	selectWindow(bs_cropName);
	//getStatistics(area, mean, min, max);
	//subtract 1/8 value of highest intensity pixel. This is to reduce false positive tube detections from airyscan noise.
	//run("Subtract...", "value=" + round(max/8));	
	run("Duplicate...", "duplicate");
	segment_cropName = "Segment" + cropName + "-" + i;
	rename(segment_cropName);
	selectWindow(segment_cropName);
	Stack.setChannel(channel);
	run("Auto Threshold", "method=Otsu ignore_black white");
	if (is("hyperstack")) {
		run("Split Channels");
		selectWindow("C" + channel + "-" + segment_cropName);
		close(segment_cropName);
		rename(segment_cropName);
	}
	roiManager("select", roiManager("count") - 1);
	setThreshold(10, 255);
	run("Analyze Particles...", "size=0.10-Infinity show=Masks display exclude add slice");
	close(segment_cropName);
	rename(segment_cropName);
	run("Duplicate...", "duplicate");
	run("Skeletonize (2D/3D)");
	skeleton_cropName = "Skeleton" + cropName + "-" + i;
	rename(skeleton_cropName);
	saveAs("tiff",cellDirectory + "/" + skeleton_cropName);
	run("Analyze Skeleton (2D/3D)", "prune=none");
	selectWindow("Results");
	saveAs("Results", cellDirectory + "/" + "skeleton_analysis_" + cropName + ".csv");
	selectWindow(cropName);
	saveAs("tiff",cellDirectory + "/" + cropName);
	selectWindow(bs_cropName);
	saveAs("tiff", cellDirectory + "/" + bs_cropName);
	selectWindow(segment_cropName);
	saveAs("tiff", cellDirectory + "/" + segment_cropName);
	selectWindow(imageName);
	close("\\Others");
}
//Designate area to analyze in each cell. Option to create 
//makeRectangle(0,0,40,40);

