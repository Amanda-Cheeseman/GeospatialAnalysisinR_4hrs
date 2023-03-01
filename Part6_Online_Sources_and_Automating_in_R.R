###PART 6  - ONLINE DATA SOURCES AND AUTOMATING

#set your working directory
setwd("D:/My Drive/Synced Desktop/SDSU/Workshops Taught/GeospatialAnalysisinR_4hrs_2023")

#install.packages(c("terra","tidyterra","ggplot2", "viridis","ggspatial","rnaturalearth","rnaturalearthdata"))

library(terra)
library(tidyterra)
library(ggplot2)
library(viridis)
library(ggspatial)
library(rnaturalearth)
library(rgbif)


################################################################
################################################################
##Downloading shapefiles from URL

#here we are going to grab elevation and New York Sate boundaries 
  #we are going to do this using loops to practice

#get URLS from internet for zip files
files<-("http://gis.ny.gov/gisdata/fileserver/?DSID=927&file=NYS_Civil_Boundaries.shp.zip")

#get directory to save files
dir<-paste(getwd(),"/ny",sep="")
dir

#this might take a few minutes to run
download.file(files,dir) #download file from internet

#unzip  file
unzip(dir) #unzip the folder corresponding to wd + particular root 

#read in NY boundary shapefile & elevation raster
NY<-vect("Counties_Shoreline.shp")
#Plot NY shapefile and view
plot(NY)

#read in from file
#NY<-vect("Example_NY/Counties_Shoreline.shp")#this one is nested in another folder
###########################################################
######################GBIF Exercise ###Map species

#establish search criteria - searching for family Canidae
  #many search criteria available check out the rgbif guide
key <- name_backbone(name = 'Canidae', rank='family')$usageKey

#run search and download 2000 records with coordinates -->
###Download takes a moment so skip to line 124 if uploading csv

Canidae<-occ_search(taxonKey=key,limit=2000,hasCoordinate = TRUE)#this takes a bit of time

#inspect Canidae -returns output summary
Canidae

#inspect slots in Canidae - we want data
names(Canidae)

#save data as csv in working directory
write.csv(Canidae$data,"Canidae_occ.csv")

#data is in tibble which is a modified data frame- lets change it to data frame to be consistent and store it in candat
can<-data.frame(Canidae$data)

#can<-read.csv("Example_Canidae/Canidae_occ.csv") #OR JUST READ IN CSV

#look at data
summary(can)
names(can)
str(can)
#gbif data has too many columns, we want:
  #lat=decimalLatitude
  #long=decimalLongitude
  #species=species

#convert data frame to simple feature
candat<-vect(can, geom = c("decimalLongitude" ,"decimalLatitude"), crs = ("EPSG:4326"))

#lets look at the data colored by species
plot(candat,col=as.factor(candat$species),pch=16)

#Well that is not a great looking map, lets make better ones using ggplot 

#load global country boundaries shapefile
world <- ne_countries(scale = "medium", returnclass = "sf")

#Or read in directly (L91) and run line 92
#world<-sf::st_read("Example_Canidae/world.shp")
#world$name<-world$CNTRY_NAME

##plot the world
ggplot(data = world)+
  #plot continents
  geom_spatvector(color = "black", fill = "antiquewhite", lwd=0.5) +
  #add scale
  annotation_scale(
    pad_x = unit(0, "cm"),
    pad_y = unit(0.05, "cm"))+
  #add North arrow
  annotation_north_arrow(
    style = north_arrow_fancy_orienteering,
    height=unit(1.5, "cm"),
    width=unit(1.5, "cm"),
    pad_x = unit(0.25, "cm"),
    pad_y = unit(1.7, "cm"))+
  #add grid lines
  theme(panel.grid.major = element_line(color = gray(.5), 
        linetype = 'dashed', linewidth = 0.5),
        panel.background = element_rect(fill = 'aliceblue'))+               
  #add title and axis labels
  ggtitle("Map of the World")+
  xlab("Longitude") +
  ylab("Latitude")+
  #define plotting bounds
  scale_x_continuous(limits = c(-150,150), breaks=(seq(-180,180,50)))+
  scale_y_continuous(limits = c(-65,75), breaks=(seq(-180,180,50)))+
  #ensures everything in matching CRS
  coord_sf()

#plot Canidae Richness
ggplot(data = world)+
              geom_spatvector(color = "black", fill = "antiquewhite", lwd=0.5) +
              #convert points to binned hexagons
              stat_summary_hex(
                    data=can,aes(
                      x=decimalLongitude,
                      y=decimalLatitude,
                      z=speciesKey),
                    fun=function(z){length(unique(z))},
                    binwidth=c(4,4))+
              #color by viridis color scale G
              scale_fill_viridis("Richness",option='G',begin=0.25,end=.85,alpha=0.9)+
              annotation_scale(
                    pad_x = unit(0, "cm"),
                    pad_y = unit(0.05, "cm"))+
              annotation_north_arrow(
                  style = north_arrow_fancy_orienteering,
                  height=unit(1.5, "cm"),width=unit(1.5, "cm"),
                  pad_x = unit(0.25, "cm"),
                  pad_y = unit(1.7, "cm"))+
              theme(panel.grid.major = element_line(color = gray(.5), 
                  linetype = 'dashed', linewidth = 0.5),
                  panel.background = element_rect(fill = 'aliceblue'))+               
              ggtitle("Canidae species richness")+
              xlab("Longitude") +
              ylab("Latitude")+
              scale_x_continuous(limits = c(-150,150), breaks=(seq(-180,180,50)))+
              scale_y_continuous(limits = c(-65,75), breaks=(seq(-180,180,50)))+
              coord_sf()
##warning ok just plotting at smaller scale than data
  
#########For US only and add labels

#make labels
world_points <- centroids(world,inside=T)

#crud what is a MULTIPOLYGON? this is a sf object called MULTIPOLYGON - 
#lets make 'world' a spatvector object and try again
world.sv<-vect(world)
  
#what is we want to add labels based on country name?
world_points <- centroids(world.sv,inside=T)
  
#get coordinates
world_points$x<-crds(world_points)[,1]
world_points$y<-crds(world_points)[,2]
  

ggplot(data = world.sv)+
    geom_spatvector(color = "black", fill = "antiquewhite", lwd=0.5) +
    stat_summary_hex(data=can,aes(x=decimalLongitude,y=decimalLatitude,z=speciesKey),
      fun=function(z){length(unique(z))},
      binwidth=c(2,2))+
    scale_fill_viridis("Richness",option='G',begin=0.25,end=.85,alpha=0.75)+
    annotation_scale(
      pad_x = unit(0, "cm"),
      pad_y = unit(0.05, "cm"))+
    annotation_north_arrow(
      style = north_arrow_fancy_orienteering,
      height=unit(1.5, "cm"),width=unit(1.5, "cm"),
      pad_x = unit(0.25, "cm"),
      pad_y = unit(1.7, "cm"))+
    theme(panel.grid.major =
        element_line(color = gray(.5), 
        linetype = 'dashed', linewidth = 0.5),
      panel.background = element_rect(fill = 'aliceblue'))+
    #add text for labels
    geom_text(data= world_points,aes(x=x,y=y, label=name), 
      color = "gray20", size=4,
      fontface = "italic", check_overlap = TRUE) +
    ggtitle("Canidae species richness")+
    xlab("Longitude") +
    ylab("Latitude")+
    # Change limits
    scale_x_continuous(limits = c(-130,-55), breaks=(seq(-180,180,25)))+
    scale_y_continuous(limits = c(20,50), breaks=(seq(-180,180,10)))+
    coord_sf()
  ##warning ok just plotting at smaller scale than data

