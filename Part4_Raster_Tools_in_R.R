# ---- RASTER TOOLS IN R ----
#let's set our working directory first
setwd("D:/My Drive/Synced Desktop/SDSU/Workshops Taught/GeospatialAnalysisinR_4hrs_2023/")

#let's load all the libraries we need
library(ggplot2)
library(terra)
library(tidyterra)

# ---- EXAMPLE: HWANGE NATIONAL PARK, ZIMBABWE ----

#first, let's read in our shapefile of Hwange NP
Hwange <- vect("Example_Zimbabwe/Hwange_NP.shp") #read it in
#and do a simple plot
plot(Hwange)

#create random points
#let's create 1000 random points within the PA for vegetation sampling
Hwange_pts <- spatSample(Hwange, size=1000, method="random")

#what does this look like?
ggplot() +
  geom_spatvector(data = Hwange, color = "darkgreen", lwd=1.5) +
  geom_spatvector(data=Hwange_pts, color = "black", lwd=2)+
  ggtitle("1000 Random Points in Hwange NP")

#now let's bring in our waterholes and roads (again using package sf)
roads <- vect("Example_Zimbabwe/ZWE_roads.shp")
waterholes <- vect("Example_Zimbabwe/waterholes.shp")

#let's plot those vectors within Hwange
ggplot() +
  geom_spatvector(data = Hwange, color = "darkgreen", lwd=1.5) +
  geom_spatvector(data=roads, color = "black", lwd=1)+
  geom_spatvector(data=waterholes, color= "blue", lwd=3)+
  ggtitle("Roads and Waterholes in Hwange NP")

#checking the coordinate systems reveals our "roads" layer is WGS 1984. 
crs(roads,describe=T)

#How can we convert to WGS 1984 UTM Zone 35S?
roads_UTM <- project(roads, "EPSG:32735")

#now let's read in the elevation (it's an aster image)
elev <- rast("Example_Zimbabwe/aster_image_20160624.tif") 

#how can we get an overview of the imported raster?
elev

#get summaries

#this is great, but can we get more stats to examine the raster layer?
#how can we get, say, quartiles, min/max, mean, & median of the data?
summary(elev)
#WARNING MESSAGE IS OK

#if you want it to use ALL the values in the dataset, use:
summary(elev,
        size = nrow(elev)*ncol(elev))
#But NOTE this will take a while

#not much of a difference, eh? 

#here is a relatively fast, simple means of plotting a raster
plot(elev)

#what is the coordinate system? 
crs(elev,describe=T)
#it's WGS84

#let's add Hwange to the elevation tile (Hwange border needs to be converted to WGS84 first)
#normally I like projecting layers to the same projected coordinate system (esp when working with distances
#and/or areas), but in this instance I will convert the Hwange boundary to WGS because it is faster
#and we are just doing a quick visualization
Hwange_WGS <- project(Hwange, "EPSG:4326")

#let's see what it looks like now!
#we will plot with the Hwange boundary in WGS 84
plot(Hwange_WGS,add=T)

#ok, so there is a lot of extra raster that we don't want to work with
#let's crop it to make raster processing a bit faster
elev_crop <- crop(elev, Hwange_WGS)

#and check
plot(elev_crop)
plot(Hwange_WGS,add=T)

#what's the coordinate system of the elevation raster again?
crs(elev_crop,describe=T)
#it's WGS 84

#now that the raster is of smaller size, we can convert this to a projected coordinate system
#to match the vector data
#let's project using project
#we need to present our crs in a slightly different way than we're used to in package sf

#goes really fast! this resolution will match our resolution for percent veg cover
elev_crop_UTM <- project(elev_crop, res=250, "EPSG:32735")

#let's make sure it looks ok with our Hwange shapefile in UTM coordinates
plot(elev_crop_UTM)
plot(Hwange, border="black",col=NA, lwd=2,add=T)
#ok, we are good!

#we are going to write this raster to file so we can use it later
#set the GeoTIFF tag for NoDataValue to -9999, the National Ecological Observatory Network’s (NEON) standard NoDataValue
writeRaster(elev_crop_UTM, "Example_Zimbabwe/elev_Hwange.tif", filetype="GTiff", overwrite=T, NAflag=-9999)

#let's read in percent vegetation now
percveg <- rast("Example_Zimbabwe/PercVegCover_2016.tif")
crs(percveg,describe=T)

plot(percveg)
#ok, this plot is weird bc we are seeing values >100, which represent various forms of NA

#let's set all values >100 to NA and plot it
percveg[percveg > 100] <- NA
plot(percveg)

#let's see what it looks like with Hwange NP
plot(Hwange, border="black",col=NA, lwd=2,add=T)

#let's crop it to Hwange NP & our elevation layer
veg_crop <- crop(percveg, elev_crop_UTM)

#let's see what it looks like now!
plot(veg_crop)
plot(Hwange, border="black",col=NA,lwd=2,add=T)

#let's try to make a raster stack of vegetation and elevation-
#we can do this using c()
stack <- c(veg_crop, elev_crop_UTM)
#ERROR ab different extents!

#let's check out the extents of each
ext(veg_crop)
ext(elev_crop_UTM)

#the extents are slightly different here, even though they are the same resolution
#this could be from pixels having a different lower left origin, for instance
#we will need to realign extents here through the resample tool
elev.match <- resample(elev_crop_UTM, veg_crop, method="bilinear")
stack <- c(veg_crop, elev.match)
#yay, it works now!

#let's move on to getting distances from roads and waterholes
#first, let's crop roads to hwange extent
roads_hwange <- crop(roads_UTM, Hwange)
#IGNORE WARNING
#let's plot the roads
plot(roads_hwange)

#for distance to linear features (roads), the distance function in terra
#first, we create empty raster of a certain resolution & extent such that we can *eventually* store our distances there
dist_road <-  rast(ext(veg_crop), res=250, crs="+init=epsg:32735")

#now we'll use Distance to calculate the distance between the given geometries
#here, it is taking the distance from each road to all the pixels in the extent
distroad_matrix <- distance((dist_road), (roads_hwange))

#we're done! let's plot the output
plot(distroad_matrix)
plot(roads_hwange, col="black",lwd=2,add=T)

#now let's calculate distance from points in package raster
#creating another empty raster
s <- rast(ext(veg_crop), res=250, crs="+init=epsg:32735")

#calculating distance from points (waterholes) using "distanceFromPoints" function
dist_waterhole <- distance(s, waterholes)

#plotting the output
plot(dist_waterhole)
plot(waterholes, col="black",lwd=2,add=T)

#let's write this to raster to we can use it later
writeRaster(dist_waterhole, "Dist_Waterhole_Hwange.tif", overwrite=T)

#now we are able to make a raster stack of all four rasters! 
stack <- c(veg_crop, elev.match, distroad_matrix, dist_waterhole )

#what does the stack look like?
stack

#names are ambiguous. let's assign names
names(stack) <- c("perc_veg", "elev", "dist_road", "dist_waterhole")
stack

#cool. now we will use the "extract" tool to extract values for each of our 1000 random points
#from each of our four raster layers
#then we extract values -- this step goes *so* super fast
#there are a number of arguments that one can make w this function; we are keeping it simple
#df=T just means we are returning the output as a data frame (otherwise will return a list)
#a note that this doesn't have to be used with just points; can be used with polygons (e.g. buffers) too - in that case,
#extract() will extract all of the pixels within those polygons
#you may want to add a "FUN = mean" or some other operation to summarize the pixel values for each polygon
#see:
#?extract
values <- extract(stack, Hwange_pts, df=T)

#let's write this to .csv!
write.csv(values, "extracted_raster_values.csv")

#how can we save a single raster layer?
#set the GeoTIFF tag for NoDataValue to -9999, the National Ecological Observatory Network’s (NEON) standard NoDataValue
writeRaster(stack$elev, "elevation.tif", filetype="GTiff", overwrite=T, NAflag=-9999)

#read it back in and check it
elev_import<- rast("elevation.tif")
elev_import
plot(elev_import)

#how can we save a raster stack?
writeRaster(stack, "raster_stack.tif", filetype="GTiff", overwrite=T, NAflag=-9999)

#THEN, in order to re-import the stack and use the individual raster layers, you can use
stack_import<- rast("raster_stack.tif")
stack_import
plot(stack_import)

#subset elevation
elev <- subset(stack_import,subset=2)
plot(elev)
