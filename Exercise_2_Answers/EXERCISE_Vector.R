#for this exercise, we will
#(1) select "La Tigra-nucleo" from the Honduras PAs shapefile
#(2) determine area of that PA in km2
#(3) create a 1 km x 1 km grid over the PA
#(4) clip that grid to the PA boundary
#(5) create 2 random points in each of those grid cells
#(6) plot it!


setwd("D:/My Drive/Synced Desktop/SDSU/Workshops Taught/GeospatialAnalysisinR_4hrs_2023/")

library(terra)
library(ggplot2)
library(tidyterra)

#read in PAs
PAs <- vect("Example_Honduras/Honduras_Protected_Areas_2007.shp")

#select "La Tigra-nucleo" in Honduras
Tigra <- PAs[PAs$NOMBRE=="La Tigra-nucleo",]

#determine area 
area_m2 <- expanse(Tigra)
#convert to km2 & print value
(area_km2 <- expanse(Tigra,"km"))

#then we will create a 1 km2 grid (1 km x 1 km) over the PA
template <- rast(Tigra, resolution = c(1000,1000))

values(template) <- 1:ncell(template)

#then transform the raster template to polygons
tigra_1km2_grid<-as.polygons(template)

#crop it to Tigra not just layer
tigra_1km2_grid_isect<-crop(tigra_1km2_grid, Tigra)

#determine number of grids (there are 105) 
nrow(tigra_1km2_grid_isect)

#create stratified random points
random_points <- spatSample (tigra_1km2_grid_isect, size=rep(1,105), "random")

#plot!
ggplot() +
  geom_spatvector(data=tigra_1km2_grid_isect, fill=NA, color = "black", size=2)+
  geom_spatvector(data=random_points, color = "blue", size=2)+
  labs(title="Desired Output")


