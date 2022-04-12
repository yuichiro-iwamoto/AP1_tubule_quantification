//This script is meant to be run after tube_analysis_imageJ_script. Requires the most updated JACoP colocalization plugin 
nefChannel = "C2-";
AP1Channel = "C1-";
directoryName = getDirectory("Choose a Directory");
colocDirectory = directoryName + "coloc_analysis";
File.makeDirectory(colocDirectory);

filelist = getFileList(directoryName);

//search for BS-Crop and segmented images of cells for colocalization analysis
BS_crop_image = "";
AP1_segment = "";

for (i = 0; i < filelist.length; i++) {
	is_BS_crop = filelist[i].contains("BS-Crop");
	is_AP1_segment = filelist[i].contains("Segment");
	if (is_BS_crop) {
		BS_crop_image = filelist[i];
	}
	if (is_AP1_segment) {
		AP1_segment = filelist[i];
	}
}

//print(BS_crop_image);
//print(AP1_segment);

//Run Autothreshold on Nef channel
open(directoryName + File.separator + BS_crop_image);

run("Split Channels");
selectWindow(nefChannel + BS_crop_image);
run("Auto Threshold", "method=Li ignore_black white");
setThreshold(125, 255);
run("Analyze Particles...", "size=0.10-Infinity circularity=0.00-1.00 show=Masks display");
selectWindow("Mask of " + nefChannel + BS_crop_image);
nefImage = "Nef_Th_" + BS_crop_image
rename(nefImage);


//Open AP1 channel
open(directoryName + File.separator + AP1_segment);
AP1Image = "AP1_Th_" + AP1_segment;
rename(AP1Image);

//Generate masks for tubes and spheroids
selectWindow(AP1Image);
setThreshold(125,255);
run("Analyze Particles...", "size=0.10-Infinity circularity=0.75-1.00 show=Masks display");
spheroidAP1 = "spheroid_" + AP1Image;
rename(spheroidAP1);
selectWindow(AP1Image);
run("Analyze Particles...", "size=0.10-Infinity circularity=0.00-0.75 show=Masks display");
tubeAP1 = "tube_" + AP1Image;
rename(tubeAP1);

//Colocalization Analysis of AP1 spheroids and Nef
run("JACoP ", "imga=[" + spheroidAP1 + "] imgb=[" + nefImage + "] thra=128 thrb=128 mm ccf=20");
selectWindow("Log");
saveAs("Text", colocDirectory + File.separator + "Spheroid_Manders_Result.txt");
selectWindow("Van Steensel's CCF between " + spheroidAP1 + " and " + nefImage);
saveAs("Tiff", colocDirectory + File.separator + "Spheroid_Van_Steensel_CCF");
print("\\Clear")

//Colocalization Analysis of AP1 tubules and Nef
run("JACoP ", "imga=[" + tubeAP1 + "] imgb=[" + nefImage + "] thra=128 thrb=128 mm ccf=20");
selectWindow("Log");
saveAs("Text", colocDirectory + File.separator + "Tube_Manders_Result.txt");
selectWindow("Van Steensel's CCF between " + tubeAP1 + " and " + nefImage);
saveAs("Tiff", colocDirectory + File.separator + "Tube_Van_Steensel_CCF");

//Saving Images
selectWindow(nefImage);
saveAs("Tiff", colocDirectory + File.separator + nefImage);
selectWindow(spheroidAP1);
saveAs("Tiff", colocDirectory + File.separator + spheroidAP1);
selectWindow(tubeAP1);
saveAs("Tiff", colocDirectory + File.separator + tubeAP1);

close("*");
