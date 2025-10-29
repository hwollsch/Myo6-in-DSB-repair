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
roiManager("Measure");
waitForUser("Please copy data from the result table for RPA intensity");


//count RPA foci
selectWindow("C2-"+image);
run("Duplicate...", "title=foci");
run("Threshold...");
waitForUser("Please select appropriate threshold for RPA foci");
run("Find Maxima...", "prominence=10 light output=[Single Points]");
run("Clear Results");
roiManager("deselect");
roiManager("Measure");
waitForUser("Please copy data from the result table for number of RPA foci");


run("Close All");
print("finish analyzing "+image);
