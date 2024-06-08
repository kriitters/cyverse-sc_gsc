# USFS CyVerse RStudio tutorial #1
# Kurt Riitters June 2024
#
# This script will work only in the CyVerse RStudio apps
#
# Part 1.	Retrieve the current user's CyVerse UserName
# Part 2. 	Construct paths to the current user's data store and analyses folder
# Part 3.	I/O with the current user's data store
# Part 4. 	I/O with the analyses folder	
# Part 5. 	Dead code for Zip / Unzip
# ###
library(dplyr)
#
# Part 1.Retrieve the current user's CyVerse UserName
# The UserName of the current user is available from their data store.
cmd <- sprintf("ls /data-store/iplant/home")
dirnames <- as.data.frame(system(cmd, intern=TRUE))
# This works only because there are two folders there
dirnames <- dirnames %>% filter(.[[1]] != "shared")
CyVerseName <- dirnames[1,1]
print("Your CyVerse UserName:")
CyVerseName

# Part 2. Construct paths to the current user's data store and analyses folder
# Construct paths to the current user's data store
out_path_ds_rstudio  <- sprintf("data-store/home/%s/", CyVerseName)
out_path_ds_linux    <- sprintf("/data-store/iplant/home/%s/", CyVerseName)
# Construct paths to the current user's analyses folder
out_path_an_rstudio  <- sprintf("data-store/data/output/")
out_path_an_linux    <- sprintf("/data-store/output/")
print("The paths to your data store:")
out_path_ds_rstudio
out_path_ds_linux
print("The paths to your analyses directory:")
out_path_an_rstudio
out_path_an_linux
#
# Part 3. I/O with the data store 
# Make two temporary files inside the container
setwd("~")
if(file.exists("File1.txt")) { file.remove("File1.txt") }
fileConn <- file("File1.txt", "a") 
writeLines(sprintf("This file was copied with the pathname out_path_ds_rstudio"), fileConn)
writeLines(sprintf("file.copy(<filename>, out_path_ds_rstudio, overwrite=TRUE)"), fileConn)
writeLines(sprintf(paste("The rstudio path is ", out_path_ds_rstudio)), fileConn)
close(fileConn)
if(file.exists("File2.txt")) { file.remove("File2.txt") }
fileConn <- file("File2.txt", "a") 
writeLines(sprintf("This file was copied with the pathname out_path_ds_linux"), fileConn)
writeLines(sprintf("file.copy(<filename>, out_path_ds_linux, overwrite=TRUE)"), fileConn)
writeLines(sprintf(paste("The linux path is ", out_path_ds_linux)), fileConn)
close(fileConn)
# Use file.copy() with two different paths to copy the two files to the data store
file.copy("File1.txt", out_path_ds_rstudio, overwrite=TRUE)  
file.copy("File2.txt", out_path_ds_linux, overwrite=TRUE)  
#
# Part 4. I/O with the analyses folder
# Make two temporary files inside the container
setwd("~")
if(file.exists("File3.txt")) { file.remove("File3.txt") }
fileConn <- file("File3.txt", "a") 
writeLines(sprintf("This file was copied with the pathname out_path_an_rstudio"), fileConn)
writeLines(sprintf("file.copy(<filename>, out_path_an_rstudio, overwrite=TRUE)"), fileConn)
writeLines(sprintf(paste("The rstudio path is ", out_path_an_rstudio)), fileConn)
close(fileConn)
if(file.exists("File4.txt")) { file.remove("File4.txt") }
fileConn <- file("File4.txt", "a") 
writeLines(sprintf("This file was copied with the pathname out_path_an_linux"), fileConn)
writeLines(sprintf("file.copy(<filename>, out_path_an_linux, overwrite=TRUE)"), fileConn)
writeLines(sprintf(paste("The linux path is ", out_path_an_linux)), fileConn)
close(fileConn)
# Use file.copy() with two different paths to copy the two files to the analyses folder
file.copy("File3.txt", out_path_an_rstudio, overwrite=TRUE)  
file.copy("File4.txt", out_path_an_linux, overwrite=TRUE)  

## Part 5. Zip / Unzip
## Zip a file inside the container and copy the zipfile to the data store
## Create or add to a temporary file
# fileConn <- file("FileInContainer.txt", "a") 
#writeLines(sprintf("This is a zip example."), fileConn)
#close(fileConn)
## Zip it
#zip(zipfile = "test.zip", files = "FileInContainer.txt")
## Construct the output file name and Use file.copy() to copy the file to the data store
#out_file <- sprintf("/data-store/iplant/home/%s/ZipFileInDataStore.zip", CyVerseName)
#file.copy("test.zip", out_file, overwrite=TRUE)  # replaces an existing file of same name
## Unzip a zipfile from the data store
##   Delete the original unzipped text file if it exists in the container
#if(file.exists("FileInContainer.txt")) { file.remove("FileInContainer.txt") }
## Copy zipfile from the data store and Unzip it inside the container
#file.copy(out_file, "test2.zip",overwrite=TRUE)
#unzip("test2.zip")
