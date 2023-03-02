# GeospatialAnalysisinR Workshop Getting Started
Hi all,

Workshop materials prepared for the South Dakota Chapter of The Wildlife Society Annual Friday, 
April 28, 2023 from 12:30-4:30 CT. Led by Amanda Cheeseman and Ellen Aikens. Material also prepared by Lisanne Petracca.



There are a few small tasks (~15-20 minutes total) you NEED to complete the workshop. 
This is to ensure that: 
(1) you have R and RStudio installed & updated to the latest version (R 4.2.2). 
(2) Ensure all required R packages are installed and loaded and 
(3) you are successfully able to import a shapefile and raster.

To Begin:
1.	Ensure that you have R and RStudio installed and updated to 4.2.2 on your computer. 
	You can do this manually or by running the following code in the base R program (not from RStudio) to update:
	# installing/loading the package:
	if(!require(installr)) {
 	install.packages("installr"); 
  	require(installr)
	} #load / install+load installr
	# Update R:
	updateR()
	#Note: you may wish to copy and update packages with the new R version- there will be a pop up for this

2.	Create a folder on your computer for the workshop called "Geospatial_Analysis_in_R" 
3.	Place the contents of the below folder directly in the folder you just created.
	This contains all workshop material and the preworkshop steps you will need below! 
	https://sdsu.box.com/s/0vh4tvty4f6g2uv49p3nv1x7uom9czha 
4.	Open RStudio, go to File-->Open File, and navigate to the directory you just created, the folder 
	called “PreWorkshop Steps”, and the R code called "PreWorkshop_Steps." Open it in R Studio. 
5.	Change the directory in line 3 to where the Geospatial_Analysis_in_R folder is on your computer. Be mindful that R wants 
	single forward slashes in the directory name rather than single backslashes. 
6.	Run the code by selecting all the text and running it (ctrl+enter). It is important that the 
	lines are run in order. The code will install & load all libraries needed for the workshop, 
	as well as import two different kinds of geospatial data. 
	
	Take note of the comments in the script (e.g., you will likely have to hit yes to install 
	packages that need compilation and may have to accept a restart of R at another point). 
	Note: please run all the code even if you have some packages installed so they update to the latest version
7.	Open the following scripts in R and change the working directories (this line reads setwd(Insert file pathway here) to your file pathway where you have stored all the workshop materials and save the script
	•	Part2_Basic_Spatial_Operations_in_R.R - Line 3
	•	Part3_Vector_Tools_in_R.R - Line 4
	•	Part4_Raster_Tools_in_R.R - Line 3
	•	Part5_Cartography_in_R.R -Line 4
	•	Part6_Online_Sources_and_Automating_in_R.R - Line 4

If this works without error messages, success! You should be set to get started!
