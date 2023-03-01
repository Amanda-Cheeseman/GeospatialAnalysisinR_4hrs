# ---- VECTOR OPERATIONS ----

#let's set our working directory first
setwd("D:/My Drive/Synced Desktop/SDSU/Workshops Taught/GeospatialAnalysisinR_4hrs_2023")

#and let's load all the libraries we need
library(terra)
library(ggplot2)
library(rnaturalearth)
library(tidyterra)


# ---- EXAMPLE: PROTECTED AREAS IN HONDURAS ----

#in this example, we will explore protected areas in Honduras and subset by name and size

#read in the shapefile with st_read
PAs <- vect("Example_Honduras/Honduras_Protected_Areas_2007.shp")

#inspect
PAs

#alternitively, show the top 6 rows of data
head(PAs)

#I wonder what the coordinate system is?
crs(PAs,describe=T)

#let's plot this SpatVector
ggplot() + 
  geom_spatvector(data = PAs, lwd = 1, color = "black", fill = "darkgreen") + 
  ggtitle("PAs in Honduras")

#alternatively
plot(PAs)
#however, this will produce a panel for each column in the attribute table

#plot specific data by subsetting using base R functions
plot(PAs[1])

#let's explore the different names of PAs in Honduras
#first, let's see what the column names are so we know which one to select
names(PAs)
#now we can inspect that column
PAs$NOMBRE

#let's say we want to extract only those PAs that are National Parks (Parque Nacional)
#to see unique values within a certain column, we can use "unique" argument
unique(PAs$CATEGORIA)

#now let's use bracketing to subset only those PAs that are national parks
NationalParks <- PAs[PAs$CATEGORIA == "Parque Nacional",]

#how many PAs are NPs?
nrow(NationalParks)

#what if there is a numerical condition? such as, what PAs are >2000 km2?
#for this we need to calculate geometry
#let's do area 
PAs$area_m2 <- expanse(PAs)

#these are really big numbers though. to make it km2, try
PAs$area_km2 <- expanse(PAs,unit="km")

#if we want to save this super-cool geometry, we can do
#we will overwrite this .csv if we already ran this line of code but want to run it again
write.csv(data.frame(PAs), "Honduras_PA_areas.csv",row.names=F) 

#now, the question is: how do we subset to only those PAs that are >500 km2?
#let's use subsetting with brackets again
BigPAs <- PAs[PAs$area_km2 > 500,]

#how many PAs are greater than 500 km2 in area?
nrow(BigPAs)

#now let's add an outline of honduras, shall we?
#fun little preview of using online data to get boundaries of countries (can do US states too!)
countries <- ne_download(scale = "large", type = 'countries', returnclass="sf" )
#if this line DOES NOT WORK, skip to L. 82, remove the #, and run that line

names(countries)

#let's grab honduras from this sf object
honduras <- countries[countries$NAME == "Honduras",]

#the line to run if ne_download does not work
#honduras <- vect("Example_Honduras/Honduras_Border.shp")

#and let's plot!
ggplot() + 
  #add protected areas, color by name
  geom_spatvector(data = BigPAs, aes(color = factor(NOMBRE)), lwd = 1.5) + 
  #add border of honduras
  geom_spatvector(data = honduras, fill=NA, lwd = 1) +
  #label Protected areas in legend
  labs(color = 'Name') +
  #add a title and subtitle
  ggtitle("Large PAs in Honduras", subtitle = "Subtitle option if you want it!")

#what if we are interested in selecting only those large PAs that intersect Honduras roads?
#read in the roads shapefile with vect
honduras_roads <- vect("Example_Honduras/Honduras_Roads_1999_CCAD.shp")

#first, let's use st_length() to see how long these roads are
honduras_roads$length <- perim(honduras_roads)
head(honduras_roads)

#let's see what happens if we try to intersect them
PAs_road_isect <- PAs[honduras_roads,]
#oh man! ERROR! coordinate systems aren't the same. we need to project the roads to the same coord system

honduras_roads_UTM <- project(honduras_roads, "EPSG:32616")
#alternatively, we could have used "crs = crs(PAs)" to import the CRS from "PAs"

#let's try that intersect again
PAs_road_isect <- PAs[honduras_roads_UTM,]

#let's see what we get
#while the new projection was necessary for the intersection, ggplot2 does not require vector data to be in the 
#same projection; ggplot automatically converts all objects to the same CRS before plotting
ggplot() + 
  #plot Honduras boundary in dark grey
  geom_spatvector(data = honduras, fill=NA, color="darkgrey",lwd=1)+
  #plot protected area roads in dark green
  geom_spatvector(data = PAs_road_isect, color= "darkgreen",lwd = 1.5) +
  #plot Honduras roads 
  geom_spatvector(data = honduras_roads_UTM, lwd = 1) +
  ggtitle("PAs that intersect roads in Honduras", subtitle = "Subtitle option if you want it!")



# ---- EXAMPLE: CAMERA TRAP LOCATIONS IN HONDURAS ---- ####


#In this example, we will create buffers of 500 m around a series of camera traps in 
#Honduras, and then clip those buffers to Honduras land area
#we may want buffers of 500-m if we are looking to calculate percent canopy cover within that radius

#let's import the csv of camera trap locations like any other .csv
camlocs <- read.csv("Example_Honduras/Camera_Coordinates_JeannetteKawas.csv")

#let's see what's in this table
head(camlocs)

#we know from our field staff that the coordinate system is WGS 1984 UTM Zone 16N
#this corresponds to EPSG number 32616 on spatialreference.org

#let's transfer to an sf object and assign a coordinate system
camlocs_sv <- vect(camlocs, geom = 
                         c("x", "y"), crs = "EPSG:32616")

#let's make sure the coordinate system is right
crs(camlocs_sv,describe=T)

#let's plot the locations to see where they are
ggplot() +
  geom_spatvector(data = camlocs_sv) +
  ggtitle("Map of Camera Trap Locations")

#now let's save this to a .shp if we want to use it in ArcMap 
writeVector(camlocs_sv,
         "camera_locations.shp",overwrite=T) 

#then let's create a buffer of 500 m around the camera trap locations
cam_500m_buffer <- buffer(camlocs_sv, width = 500)

#did it work? let's see by making a map
#ensure that you plot buffers first so that the points can go over them
ggplot() +
  geom_spatvector(data=cam_500m_buffer, fill="red", color = "black")+
  geom_spatvector(data = camlocs_sv) +
  ggtitle("Map of Camera Trap Locations")

#creating a convex hull polygon around the camera trap locations
cam_convexhull <- convHull(camlocs_sv)

#let's plot!
ggplot() +
  geom_spatvector(data=cam_convexhull, fill="white", color = "blue", lwd=2)+
  geom_spatvector(data=cam_500m_buffer, fill="red", color = "black")+
  geom_spatvector(data = camlocs_sv) +
  ggtitle("Map of Camera Trap Locations")

#pop quiz: how would we then get area of that convex hull polygon?
(area <- expanse(cam_convexhull))

#ok so let's see how this looks when we want to display this polygon over the border of Honduras
#let's read in a more detailed version of Honduras boundary
honduras_detailed <- vect("Example_Honduras/Honduras_Border.shp")

#let's plot where the camera traps are within the country
ggplot() +
  geom_spatvector(data = honduras_detailed) +
  geom_spatvector(data=cam_convexhull, fill="white", color = "blue", lwd=2)+
  geom_spatvector(data=cam_500m_buffer, fill="red", color = "black")+
  geom_spatvector(data = camlocs_sv) +
  ggtitle("Map of Camera Trap Locations")

#i am not happy with this map extent. how can we change it?

#let's get the extent of that convex hull polygon first,
xmin<-xmin(cam_convexhull)
xmax<-xmax(cam_convexhull)
ymin<-ymin(cam_convexhull)
ymax<-ymax(cam_convexhull)

#and then supply this extent to the coord_sf argument in ggplot to reduce the extent
ggplot() +
  geom_spatvector(data = honduras_detailed) +
  geom_spatvector(data=cam_convexhull, fill=NA, color = "blue", lwd=2)+
  geom_spatvector(data=cam_500m_buffer, fill="red", color = "black")+
  geom_spatvector(data = camlocs_sv) +
  #plot with scale in meters and bounded to the extent of cam_convexhull
  coord_sf(datum=32616, xlim=c(xmin, xmax), ylim=c(ymin, ymax))+
  ggtitle("Map of Camera Trap Locations")

#oh no! the convex hull polygon includes the ocean! how can we crop to the honduras_detailed boundary?

#first, let's check the honduras_detailed polygon to see what coordinate system is is using
crs(honduras_detailed,describe=T)

#ok, it is NAD 1927 UTM Zone 16N; this is very close to WGS 1984 UTM Zone 16N but isn't exact
#let's transform the boundary to the same projection as the convex hull polygon
honduras_detailed_UTM <- project(honduras_detailed, "EPSG:32616")

#let's check to make sure the new polygon is in the correct projection
crs(honduras_detailed_UTM,describe=T)

#yay! it worked! now we can proceed with cropping using st_intersection
cam_convexhull_land <- crop(cam_convexhull, honduras_detailed_UTM)

#quick plot to see if cropping worked
plot(cam_convexhull_land)

#better plot
ggplot() +
  geom_spatvector(data = honduras_detailed_UTM) +
  geom_spatvector(data=cam_convexhull_land, fill=NA, color = "blue", lwd=2)+
  geom_spatvector(data=cam_500m_buffer, fill="red", color = "black")+
  geom_spatvector(data = camlocs_sv) +
  coord_sf(datum=32616, xlim=c(xmin, xmax), ylim=c(ymin, ymax))+
  ggtitle("Map of Camera Trap Locations")

#how can we get the area (in square meters) of this new polygon?
(expanse(cam_convexhull_land,unit="km"))



####---- SAMPLING TOOLS ----####


#let's select the PA in honduras_detailed called "Pico Bonito - Zona Nucleo"
PAs$NOMBRE

#first we will select the PA by name from the greater multipolygon object
PicoBonito <- PAs[PAs$NOMBRE == "Pico Bonito-Zona Nucleo",]

#let's create 100 random points within the PA for vegetation sampling
random_points <- spatSample(PicoBonito, size=100,method="random")

#what does this look like?
ggplot() +
  geom_spatvector(data = PicoBonito, color = "darkgreen", lwd=1.5) +
  geom_spatvector(data=random_points, color = "black", lwd=2)+
  ggtitle("100 Random Points in Pico Bonito NP")

#then we will create a 16 km2 grid (4 km x 4 km) over the PA
#first we need to create a template and add values
template <- rast(PicoBonito, resolution = c(4000,4000))
values(template) <- 1:ncell(template)

#then transform the raster template to polygons
pico_16km2_grid<-as.polygons(template)

#let's check it out -looks good!
plot(pico_16km2_grid)

#let's clip this grid to the boundary of Pico Bonito if we aren't interested in the area outside
pico_16km2_grid_isect <- crop(pico_16km2_grid, PicoBonito)

#how can we see what this looks like?
ggplot() +
  geom_spatvector(data=pico_16km2_grid_isect, fill=NA, color = "black", lwd=2)+
  geom_spatvector(data = PicoBonito, color = "darkgreen", fill=NA, lwd=1.5) +
  #use expression and paste to creat superscripts, subscripts etc.
  labs(title=expression(paste("16 km" ^{2}," Grid in Pico Bonito NP")))

#What if we want to put in two camera traps at random locations within each grid?
#we need to explicitly tell spatSample to sample within each of the 53 cells within the grid

#let's see how many grids we have; yep, there are 53
pico_16km2_grid_isect    

#let's try again, supplying a vector such that it knows to sample 2 points
#in each of the 53 polygons 
random_points <- spatSample(pico_16km2_grid_isect, size=rep(2,53), method="random")

ggplot() +
  geom_spatvector(data=pico_16km2_grid_isect, fill=NA, color = "darkblue", lwd=2)+
  geom_spatvector(data = PicoBonito, color = "darkgreen", fill=NA, lwd=1.5) +
  geom_spatvector(data=random_points, color = "purple", lwd=2)+
  ggtitle("Two Random Pts Per Grid Cell in Pico Bonito NP")

#let's add the coordinates and save these points to a .csv
#get coordinates using crds
coords_rp<-crds(random_points)

#add to random_points and inspect
(random_points<-cbind(random_points,data.frame(coords_rp)))

#write it to a .csv
writeVector(random_points, "RandomPoints_PicoBonito.csv",filetype="csv",overwrite=T)

#check it!
head(read.csv("RandomPoints_PicoBonito.csv"))

