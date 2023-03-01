#install.packages(c("terra","ggplot2", "viridis","tidyterra","ggspatial","grDevices"))

#let's set our working directory first
setwd("D:/My Drive/Synced Desktop/SDSU/Workshops Taught/GeospatialAnalysisinR_4hrs_2023/")

#and let's load all the libraries we need
library(terra)
library(ggplot2)
library(viridis)
library(tidyterra)
library(ggspatial)#scale bars & north arrows


# ---- LET'S HAVE SOME FUN WITH MAPPING! ----
# ---- VECTOR ONLY ----

#we will return to our Zimbabwe data for the vector mapping
#first, let's read in our shapefile of Hwange NP (polygon)
HwangeNP <- vect("Example_Zimbabwe/Hwange_NP.shp")
#then our roads (line)
roads <- vect("Example_Zimbabwe/ZWE_roads.shp")
#then our waterholes (point) - we will need to extract only Hwange NP roads later
waterholes <- vect("Example_Zimbabwe/waterholes.shp")

#do the coordinate systems match? let's see
crs(HwangeNP,describe=T)
crs(roads,describe=T)
crs(waterholes,describe=T)

#roads do not match. let's project roads to WGS 1984 UTM Zone 35S to match the others
roads <- project(roads, "EPSG:32735")

#and now let's select the roads that intersect Hwange NP
roads_isect <- roads[HwangeNP,]

#and now let's plot what we have
#ggplot() - initializes a ggplot object
ggplot() +
  #geom_spatvector() - allows visualization of spatvector objects using tidyterra
  geom_spatvector(data = HwangeNP, color = "darkgreen", fill = "white", lwd=2) +
  geom_spatvector(data=roads_isect, color = "black", lwd=1)+
  geom_spatvector(data=waterholes, color= "blue", lwd=3)+
  #ggtitle() - provides title (and optional subtitle)
  ggtitle("Roads and Waterholes in Hwange NP", subtitle = "2020")+
  #coord_sf() - ensures all layers use common crs
  coord_sf()

#let's add a legend object, with "TYPE" of waterhole in the legend
#how can we see unique values of "waterhole type?
unique(waterholes$TYPE)

#we are making two small changes here
ggplot() +
  geom_spatvector(data = HwangeNP, color = "darkgreen", fill = "white", lwd=2) +
  geom_spatvector(data=waterholes, 
          #the "aes" argument tells ggplot to apply a different color to each value of waterhole TYPE
          aes(color=factor(TYPE)),
          lwd=3)+
  #"labs" in this case gives a title to the legend
  labs(color = 'Waterhole type')+
  ggtitle("Waterhole types in Hwange NP", subtitle = "2020")
  

#what if we don't like these colors? how can we change them?
#can see color options here: http://www.stat.columbia.edu/~tzheng/files/Rcolor.pdf
waterhole_colors <- c("purple", "orange", "deepskyblue3")

#now we basically need to tell ggplot to use these colors with "scale_color_manual"
ggplot() +
  geom_spatvector(data = HwangeNP, color = "darkgreen", fill = "white", lwd=2) +
  geom_spatvector(data=roads_isect, color = "black", lwd=1)+
  geom_spatvector(data=waterholes, aes(color=factor(TYPE)), lwd=3)+
  #give ggplot these colors
  scale_color_manual(values=waterhole_colors)+
  labs(color = 'Waterhole type')+
  ggtitle("Waterhole types in Hwange NP", subtitle = "2020")+
  coord_sf()

#we can change other aspects of the legend using theme()
ggplot() +
  geom_spatvector(data = HwangeNP, color = "darkgreen", fill = "white", lwd=2) +
  geom_spatvector(data=roads_isect, color = "black", lwd=1)+
  geom_spatvector(data=waterholes, aes(color=factor(TYPE)), lwd=3)+
  scale_color_manual(values=waterhole_colors)+
  labs(color = 'Waterhole type')+
  ggtitle("Waterhole Types in Hwange NP")+
  theme(plot.title = element_text(size=20), #this changes size of plot title
        legend.position="bottom", #changes legend position
        legend.title=element_text(size=16), #changes size of legend title
        legend.text = element_text(size = 16), #changes size of element text in legend
        text=element_text(family="sans"),
        legend.box.background = element_rect(linewidth = 1)) + #adds a legend box of width 1
  coord_sf()

#ok, so that's great for plotting a single shapefile
#what if we are interested in having multiple shapefiles listed in the legend?

#let's go back to our original map with the polygon, lines, and points
ggplot() +
  geom_spatvector(data = HwangeNP, color = "darkgreen", fill = "white", lwd=2) +
  geom_spatvector(data=roads_isect, color = "black", lwd=1)+
  geom_spatvector(data=waterholes, color= "blue", lwd=3)+
  ggtitle("Roads and Waterholes in Hwange NP", subtitle = "2020")+
  coord_sf()

#and let's say we want to have waterhole type AND roads in the legend
#each vector needs an aes & scale argument
ggplot() +
  geom_spatvector(data = HwangeNP, color = "darkgreen", fill = "white", lwd=2) +
  geom_spatvector(data=roads_isect, aes(fill = F_CODE_DES), lwd=1)+
  geom_spatvector(data=waterholes, aes(color=factor(TYPE)), lwd=3)+
  scale_color_manual(values = waterhole_colors, name = "Waterhole type") +
  scale_fill_manual(values = "black", name = "")+
  ggtitle("Roads and Waterholes in Hwange NP", subtitle = "2020")+
  coord_sf()

#note "fill" defines color with which a geom is filled & "color" defines outline
#most points only have a color and no fill


#Interested in changing the shape of points?
#see https://ggplot2.tidyverse.org/articles/ggplot2-specs.html for a lot of ggplot aesthetics

#### ---- INCLUDING RASTER DATA ----####

#let's return to plotting elevation in Hwange NP
#let's read in that cropped elevation file we already made

elev_df <- rast("Example_Zimbabwe/elev_Hwange.tif")

#and let's see it quickly using the plot function in raster
plot(elev_df)

#see what the data frame looks like
head(elev_df)   #IT IS OK THAT THERE ARE NAs

#man, we have NA values. where are they? 
ggplot() +
  geom_spatraster(data = elev_df) +
  #we can use "na.value = "color"" to show where those pixels are if ther are any
  #brief aside on Viridis - package with nice color templates
  #color blind Friendly
  #see:https://cran.r-project.org/web/packages/viridis/vignettes/intro-to-viridis.html
  scale_fill_viridis_c(na.value = "red",option="D") 

#ok, they are some border cells -let's go back to mapping

#change legend title
#change text of legend labels
#remove x and y axis labels

ggplot() +
  geom_spatraster(data = elev_df) +
  #let's change legend name
    scale_fill_viridis_c(option="H",name = "Elevation (m)") +
  theme(
        #remove x and y axis titles    
        axis.title = element_blank(),
        #move legend theme to bottom
        legend.position = "bottom",
        #adjust size of legend name and labels
        legend.title=element_text(size=12),
        legend.text = element_text(size = 10), 
        legend.box.background = element_rect(linewidth = 1))

#now let's place the elevation raster in a map with Hwange NP and waterholes
#order matters!
#layers that should be on the bottom go first
#notice that the fill for Hwange is now "NA" so we can see underlying elevation
ggplot() +
  geom_spatraster(data = elev_df) +
  #add Hwange
  geom_spatvector(data = HwangeNP, color = "black", fill = NA, lwd=2) +
  #add waterholes
  geom_spatvector(data=waterholes, aes(color=factor(TYPE)), lwd=3)+
  scale_fill_viridis_c(option='H',name = "Elevation (m)")+
  scale_color_manual(values = waterhole_colors, name = "Waterhole type") +
  #Adding in coord_sf() to display coordinates in decimal degrees
  coord_sf()


#Okay lets make it look a bit nicer by adding lat and long lines
#and making the elevation colors a bit less intense
#and giving gg plot a nicer looking theme to work off of
ggplot() +
  geom_spatraster(data = elev_df) +
  geom_spatvector(data = HwangeNP, color = "black", fill = NA, lwd=2) +
  geom_spatvector(data=waterholes, aes(color=factor(TYPE)), lwd=3)+
  #lets make the background a bit less bright by changing the alpha values
    scale_fill_viridis_c(option='H',name = "Elevation (m)",alpha=0.7)+
  scale_color_manual(values = waterhole_colors, name = "Waterhole type") +
  #ggplot has a number of standard themes - I like theme_bw as a template
  #see https://ggplot2.tidyverse.org/reference/ggtheme.html for full list of themes
  theme_bw()+
  #add grid lines for lat and long 
  theme(
        #lets add grid lines!!
        panel.grid.major =
        element_line(color = gray(.5), 
        linetype = 'dashed', linewidth = 0.5))+
  coord_sf()

#And the last thing wee need is a north arrow and a scale bar to make our map official 
ggplot() +
  geom_spatraster(data = elev_df) +
  geom_spatvector(data = HwangeNP, color = "black", fill = NA, lwd=2) +
  geom_spatvector(data=waterholes, aes(color=factor(TYPE)), lwd=3)+
  scale_fill_viridis_c(option='H',name = "Elevation (m)",alpha=0.7)+
  scale_color_manual(values = waterhole_colors, name = "Waterhole type") +
  #Let's add the scale bar
  annotation_scale(
    height=unit(.5,"cm"),
    pad_x = unit(1, "cm"),
    pad_y = unit(0.7, "cm"))+
  #Let's add the North arrow - adjust height and padding per screen
  annotation_north_arrow(
    height=unit(1.5, "cm"),
    width=unit(1.25, "cm"),
    pad_x = unit(9.5, "cm"),
    pad_y = unit(8, "cm"))+
  theme_bw()+
  theme(
    panel.grid.major =
      element_line(color = gray(.5), 
                   linetype = 'dashed', linewidth = 0.5))+
  coord_sf()

#what if we want it more earth toned
#And the last thing wee need is a north arrow and a scale bar to make our map official 
ggplot() +
  geom_spatraster(data = elev_df) +
  geom_spatvector(data = HwangeNP, color = "black", fill = NA, lwd=2) +
  geom_spatvector(data=waterholes, aes(colour=factor(TYPE)),pch=16,lwd=3)+
#change the symbol colors a bit
  scale_color_manual(values = c("Grey10","Grey40","#2c666e"), name = "Waterhole type") +
  #add a nicer elevation legend
  guides(fill = guide_legend(title = "Elevation (m)", title.position = "top"))+
  #scale by manual color bar created above
  scale_fill_gradient2(
    low = "#6AA85B",
    mid = "#D9CC9A",
    high = "#a47770",
    midpoint=(
    #using some coding to just extract the meand from the elev_df summary object
      as.numeric(gsub("Mean   :", "",data.frame(summary(elev_df))[4,3]))
    ))+
  annotation_scale(
    height=unit(.5,"cm"),
    pad_x = unit(1, "cm"),
    pad_y = unit(0.7, "cm"))+
  annotation_north_arrow(
    height=unit(1.5, "cm"),
    width=unit(1.25, "cm"),
    pad_x = unit(9.5, "cm"),
    pad_y = unit(8, "cm"))+
  theme_bw()+
  theme(
        panel.grid.major =
          element_line(color = gray(.5), 
                       linetype = 'dashed', linewidth = 0.5))+
  coord_sf()
#wowzers! that is one excellent-looking map

