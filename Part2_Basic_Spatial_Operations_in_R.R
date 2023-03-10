#install.packages(c("terra"))
library(terra)
setwd("D:/My Drive/Synced Desktop/SDSU/Workshops Taught/GeospatialAnalysisinR_4hrs_2023/Geospatial_Analysis_in_R")#Change to your working directory path

###CAN WORK WITH SPATIAL DATA AS DATA FRAME 
##create unprojected spatial data 
  #NO PROJECTION - NOT GOOD
data<-data.frame(long=c(-76.13332,-76.86515,-76.851651), # c() concatenates values separated by commas 
                 lat=c(42.85632,42.65465,42.51311))
data#Inspect to see what data looks like

#plot spatial data
plot(data)
#note if "Error in plot.new() : figure margins too large" resize the plot window 
  #in the (default lower right window) to be larger


#########################################################################
##### SPATIAL DATA TYPES in terra

##Create projected spatial data from data.frame with terra
#define coordinate system using EPSG code
crdref <- "EPSG:4326"

#create SpatVector class object names pts from data
?vect# use the ? before a function to see which arguments are needed and their format!! 
pts <-  vect(data,geom = c("long", "lat"), crs = crdref)

#inspect pts
pts
plot(pts)

##Create an spatVector object with data
#Create attributes corresponding to the row from data 
  #(alternatively you would pull from your database/csv etc.)
  # here creating sites pond, river, and forest, and ID for each row in data
att<-data.frame(site=c("Pond","River","Forest"),ID=1:nrow(data))

#look at att
att

#use st_as_sf() function to add attributes to points
#how do we do this?
#really great for determining if sp or sf objects are required
sf.df<-cbind(pts,att)

#look at sf.df
sf.df

#write st.df to a shapefile using function write.sf() 
writeVector(sf.df,"myshapefile.shp",overwrite=T)

#read in myshapefile using the read.sf() function 
shp<-vect("myshapefile.shp")

#Inspect and check loaded simple features object created from the shapefile
shp#look shp
str(shp)#look at data

crs(shp)#look at coordinate reference system - note can be saved to object & applied to other datasets
#wow thats a lot -how about we try this
crs(shp,describe=T)
#much better!!

#lets plot it
plot(shp,col=as.factor(shp$site))#where 1 specifies the data column number to plot

##Convert the sf object to data frame
geo_data<-data.frame(shp)

#look at geo_data
geo_data

#aww no coordinates -what if we want them??
#get coordinates
coords<-data.frame(crds(shp))

#and combine/view
(geo_dat_coords<-cbind(geo_data,coords))

#####Raster 

# Create a matrix of values using the terra package

?rast #see what arguments are required to make a raster note :: calls package terra

#let's copy our crs from 'shp'
crs.shp<-crs(shp)

#let's inspect
crs.shp

#okay lets make our raster from scratch & give it 10 rows and 13 columns 
    #plotted in WGS84
r <- rast(nrows=10, ncols=13, crs=crs.shp)

#create 10 x 13 =130 values and assign values to raster
values(r)<- c(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,1,
        0,0,0,0,0,0,0,1,1,1,1,1,1,1,0,0,0,0,0,1,1,0,1,1,1,0,1,1,0,0,0,1,1,1,1,
        1,1,1,1,1,1,1,0,0,1,0,1,1,1,1,1,1,1,0,1,0,0,1,0,1,0,0,0,0,0,1,0,1,0,0,
        0,0,0,1,1,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

#inspect raster
r

#look at its crs
crs(r,describe=T)

#plot raster
plot(r,col=c("black","green"))

#save raster to file
writeRaster(r,"myraster.tif",overwrite=T)

#load raster from file
r2 <- rast("myraster.tif")

#plot raster to inspect
plot(r2,col=c("black","purple"))

