//This macro is used for quantifying intensity and number of gammaH2AX and 53BP1 foci intensity within the nuclear masks
//Measure nuclear gammaH2AX intensity
image = getTitle();
roiManager("reset");
run("Clear Results");
run("Split Channels");
selectWindow("C1-"+image);
waitForUser("Please adjust brightness and contrast");
run("Median...", "radius=10");
setAutoThreshold("Mean dark");
run("Convert to Mask");
run("Watershed");
run("Analyze Particles...", "size=100-Infinity display exclude clear add");
selectWindow("C2-"+image);
run("Set Measurements...", "area integrated redirect=None decimal=3");
run("Clear Results");
roiManager("deselect");
waitForUser("Please copy data from the result table for gammaH2AX intensity");

//count 53BP1 foci
selectWindow("C2-"+image);
run("Duplicate...", "title=foci");
run("Threshold...");
waitForUser("Please select appropriate threshold for 53BP1 foci");
run("Find Maxima...", "prominence=10 output=[Single Points]");
run("Clear Results");
roiManager("deselect");
roiManager("Measure");
waitForUser("Please copy data from the result table for number of 53BP1 foci");

//measure 53BP1 foci intensity
selectWindow("foci");
run("Analyze Particles...", "size=0-Infinity display exclude clear add");
run("Set Measurements...", "area integrated redirect=None decimal=3");
selectWindow("C2-"+image);
roiManager("deselect");
roiManager("Measure");
waitForUser("Please copy data from the result table for number of 53BP1 foci");
run("Close All");
print("finish analyzing "+image);
