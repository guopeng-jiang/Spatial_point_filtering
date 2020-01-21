# join data

#### load packages

library(readr)
library(sp)
library(rgdal)
library(rgeos)
library(foreach) 
library(doParallel)

######## set directory ###########

wd <- "E:\\user_name\\input_folder" #--- input yield data file folder
setwd(wd)

boundary_dir = paste0(wd, "/boundary") #---boundary file folder

output_dir = paste0(wd, "/output_data") #--- output data folder

#############################
##### read spatial data #####
#############################

# read boundary file
bound = readOGR(boundary_dir, as.character(gsub(".shp","",list.files(boundary_dir, pattern = "\\.shp$"))))
proj4string(bound) <- CRS("+init=epsg:4326") 
bound_utm <- spTransform(bound, CRS("+init=epsg:2193")) 

# read yield file
yield_list <- lapply(list.files(wd, pattern = "\\.shp$"), function(shp_list) {
  layer_name <- as.character(gsub(".shp","",shp_list))
  shp_spdf <-readOGR(dsn = wd, stringsAsFactors = FALSE, verbose = TRUE, 
                     useC = TRUE, dropNULLGeometries = TRUE, addCommentsToPolygons = TRUE,
                     layer = layer_name, require_geomType = NULL,
                     p4s = NULL, encoding = 'ESRI Shapefile')
})

for (i in seq(yield_list)) {
  proj4string(yield_list[[i]]) <- CRS("+init=epsg:4326") 
  yield_list[[i]] <- spTransform(yield_list[[i]], CRS("+init=epsg:2193")) 
  yield_list[[i]] <- yield_list[[i]][bound_utm,]
}  


#################################
##### filter spatial points #####
#################################

#--Global Filter Algorithm--Sudduth et al. 2003
GlobalFilter <- function(x, na.rm = TRUE, ...) {
  qnt <- quantile(x, probs=c(.25, .75), na.rm = na.rm, ...)
  H <- 1.5 * IQR(x, na.rm = na.rm) # whisker length 1.5 by default
  y <- x
  y[x < (qnt[1] - H)] <- NA
  y[x > (qnt[2] + H)] <- NA
  y
}   

YieldData1st <- yield_list

for (i in seq(YieldData1st)) {
  
  YieldData1st[[i]]$yield <- GlobalFilter(YieldData1st[[i]]$`Yld_Mass_D`) 
  
  # Select yield variable `Yld_Mass_D`, otherwise rename the variable as `Yld_Mass_D`!
  
  YieldData1st[[i]] <- subset(YieldData1st[[i]], !is.na(YieldData1st[[i]]$yield))

}

#--Local Filter Algorithm--Spekken 2013 

YieldData2nd <- YieldData1st

CV <- function(mean, sd) {(sd / mean) * 100} 
distThreshold <- 5 # Distance threshold 
CVThreshold <- 20 # CV threshold 

LocalCV <- list()
Num.CV <- list()

# Parallel processing to reduce processing time
cores=detectCores() #setup parallel backend to use many processors
clust_cores <- makeCluster(cores[1]-1)
registerDoParallel(clust_cores) #To see if the connections are active, use showConnections()

YieldData3rd = foreach(i = seq(YieldData2nd), .combine=list, .multicombine=TRUE) %dopar% {
  LocalCV[[i]] = sapply(X = 1:length(YieldData2nd[[i]]), 
                        FUN = function(pt) {
                          d = spDistsN1(YieldData2nd[[i]], YieldData2nd[[i]][pt,])
                          ret = CV(mean = mean(YieldData2nd[[i]][d < distThreshold, ]$yield), 
                                   sd = sd(YieldData2nd[[i]][d < distThreshold, ]$yield))
                          return(ret)
                        }) # calculate CV in the local neighbour 
  
  YieldData2nd[[i]]$CV <- LocalCV[[i]]
  YieldData2nd[[i]] <- subset(YieldData2nd[[i]], !is.na(YieldData2nd[[i]]$CV)) 
  
  Num.CV[[i]] = sapply(X = 1:length(YieldData2nd[[i]]), 
                       FUN = function(pt) {
                         d = spDistsN1(YieldData2nd[[i]], YieldData2nd[[i]][pt,])
                         ret = length(YieldData2nd[[i]][d<distThreshold & YieldData2nd[[i]]$CV>CVThreshold,]$CV) == length(YieldData2nd[[i]][d<distThreshold,]$CV)
                         return(ret)
                         # If the total number of CVs over 25% equals to the total number of CVs within a search radius then return TRUE or 1
                       }
  ) 
  
  YieldData2nd[[i]]$NumCV <- Num.CV[[i]]  # Add num CV as attribute data
  YieldData2nd[[i]] <- subset(YieldData2nd[[i]], YieldData2nd[[i]]$NumCV == FALSE) # subset the filtered data
}

stopCluster(clust_cores) 

############################################
##### Save & extract processed data ########
############################################

for (i in seq(YieldData3rd)) {
  
  YieldData3rd[[i]] <- spTransform(YieldData3rd[[i]], CRS("+init=epsg:4326")) # reproject into wgs84
  
  # writeOGR(YieldData3rd[[i]], output_dir, as.character(gsub(".shp","", list.files(wd, pattern = "\\.shp$")[i])), driver="ESRI Shapefile") 

    # save the processed files to the folder using writeOGR function

    for (i in seq(YieldData3rd))

      assign(as.character(gsub(".shp","", list.files(wd, pattern = "\\.shp$")[i])), YieldData3rd[[i]])
  # Extract each element in list into its own object
  } 



