#> DATASET: Localização dos estabelecimentos registrados no Cadastro Nacional de Estabelecimentos de Saúde. Sobre o CNES
#> Source: Cadastro Nacional de Estabelecimentos de Saúde - CNES



### Libraries (use any library as necessary)


library(RCurl)
#library(tidyverse)
library(stringr)
library(sf)
library(janitor)
library(dplyr)
library(readr)
library(parallel)
library(data.table)
library(xlsx)
library(magrittr)
library(devtools)
library(lwgeom)
library(stringi)
library(geobr)

####### Load Support functions to use in the preprocessing of the data

source("./prep_data/prep_functions.R")



# Root directory
root_dir <- "L:////# DIRUR #//ASMEQ//geobr//data-raw"
setwd(root_dir)



###### 0. Create folders to save the data -----------------

# Directory to keep raw zipped files
  dir.create("./health_facilities")


#### 1. Download original data sets from IBGE ftp -----------------



# Download and read into CSV at the same time
  ftp <- "http://i3geo.saude.gov.br/i3geo/ogc.php?service=WFS&version=1.0.0&request=GetFeature&typeName=cnes&outputFormat=CSV"
  cnes <- fread(ftp)
  head(cnes)

# create year_update column
  cnes$year_update <- as.Date(cnes$data_atualizacao) %>% format("%Y") %>% as.numeric()
  table(cnes$year_update)  

# find most common year of update
  ux <- unique(cnes$year_update)
  most_freq_year <- ux[which.max(tabulate(match(cnes$year_update, ux)))]


# Create dir to save data of that specific year
  dir.create(paste0("./health_facilities/",most_freq_year))
  
  
# Save original raw data
  fwrite(cnes, file = paste0("./health_facilities/",most_freq_year,"/cnes_rawdata_",most_freq_year,".csv"))


rm(list=setdiff(ls(), c("root_dir")))


#### 2. Create folders to save sf.rds files  -----------------

# create directory to save cleaned shape files in sf format
  dir.create("./health_facilities/shapes_in_sf_all_years_cleaned", showWarnings = FALSE)



  
  

#### 3. Save cleaned data sets in compact .rds format-----------------

# list all csv files
  all_csv <- list.files(path="./health_facilities", full.names = T, recursive = T, pattern = ".csv")
  
# read data
  cnes <- fread(all_csv)
  head(cnes)

# Create column with state codes
  setDT(cnes)[, code_state := substr(co_ibge, 1, 2) %>% as.numeric() ]
  
# Create column with state abbreviations
  cnes[ code_state== 11, abbrev_state :=	"RO" ]
  cnes[ code_state== 12, abbrev_state :=	"AC" ]
  cnes[ code_state== 13, abbrev_state :=	"AM" ]
  cnes[ code_state== 14, abbrev_state :=	"RR" ]
  cnes[ code_state== 15, abbrev_state :=	"PA" ]
  cnes[ code_state== 16, abbrev_state :=	"AP" ]
  cnes[ code_state== 17, abbrev_state :=	"TO" ]
  cnes[ code_state== 21, abbrev_state :=	"MA" ]
  cnes[ code_state== 22, abbrev_state :=	"PI" ]
  cnes[ code_state== 23, abbrev_state :=	"CE" ]
  cnes[ code_state== 24, abbrev_state :=	"RN" ]
  cnes[ code_state== 25, abbrev_state :=	"PB" ]
  cnes[ code_state== 26, abbrev_state :=	"PE" ]
  cnes[ code_state== 27, abbrev_state :=	"AL" ]
  cnes[ code_state== 28, abbrev_state :=	"SE" ]
  cnes[ code_state== 29, abbrev_state :=	"BA" ]
  cnes[ code_state== 31, abbrev_state :=	"MG" ]
  cnes[ code_state== 32, abbrev_state :=	"ES" ]
  cnes[ code_state== 33, abbrev_state :=	"RJ" ]
  cnes[ code_state== 35, abbrev_state :=	"SP" ]
  cnes[ code_state== 41, abbrev_state :=	"PR" ]
  cnes[ code_state== 42, abbrev_state :=	"SC" ]
  cnes[ code_state== 43, abbrev_state :=	"RS" ]
  cnes[ code_state== 50, abbrev_state :=	"MS" ]
  cnes[ code_state== 51, abbrev_state :=	"MT" ]
  cnes[ code_state== 52, abbrev_state :=	"GO" ]
  cnes[ code_state== 53, abbrev_state :=	"DF" ]
  head(cnes)
  
  
# Convert originl data frame into sf  
  cnes_sf <- st_as_sf(x = cnes, 
                          coords = c("long", "lat"),
                          crs = "+proj=longlat +datum=WGS84")
  

  head(cnes_sf)
  table(cnes_sf$origem_dado)
  
# create year_update column
  cnes_sf$year_update <- as.Date(cnes_sf$data_atualizacao) %>% format("%Y") %>% as.numeric()
  table(cnes_sf$year_update)  
  
# find most common year of update
  ux <- unique(cnes_sf$year_update)
  most_freq_year <- ux[which.max(tabulate(match(cnes_sf$year_update, ux)))]
  

# Create dir to save data of that specific year
  dir.create(paste0("./health_facilities/shapes_in_sf_all_years_cleaned/",most_freq_year))
  

    
  

  
### Change colnames
  head(cnes_sf)
  cnes_sf <- dplyr::select(cnes_sf, 
                            code_cnes = co_cnes, 
                            code_muni = co_ibge,
                            code_state= code_state,
                            abbrev_state= abbrev_state,
                            date_update = data_atualizacao,
                            year_update = year_update,
                            data_source = origem_dado,
                            geometry=geometry)
  
  head(cnes_sf)
  

# Change CRS to SIRGAS  Geodetic reference system "SIRGAS2000" , CRS(4674).  
  st_crs(cnes_sf)
  cnes_sf <- st_transform(cnes_sf, 4674)

  
  
  
  
  

  
# Save raw file in sf format
  write_rds(cnes_sf, paste0("./health_facilities/shapes_in_sf_all_years_cleaned/",most_freq_year,"/cnes_sf_",most_freq_year,".rds"), compress = "gz")
  sf::st_write(cnes_sf, dsn= paste0("./health_facilities/shapes_in_sf_all_years_cleaned/",most_freq_year,"/cnes_sf_",most_freq_year,".gpkg"))

  
  
  
  
  