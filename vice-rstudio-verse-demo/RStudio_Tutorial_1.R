# USFS CyVerse RStudio tutorial #1
# Kurt Riitters June 2, 2024
#
# This script will work only in the CyVerse RStudio apps / Linux OS
#
# Part 1. I/O directly with the data store 
# Retrieve your CyVerse UserName
# Construct the path to your CyVerse data store
# Write a file to the data store:
#   -Make a temporary file inside the container
#   -Use file.copy() to copy the file to the data store
# Part 2. Zip / Unzip
# Zip a file inside the container and copy it to the data store
# Copy a zipfile from the data store and unzip it in the container

library(dplyr)
# Part 1
# The UserName is available from the directory name in the data store.
cmd <- sprintf("ls /data-store/iplant/home")
dirnames <- as.data.frame(system(cmd, intern=TRUE))
# This works only because there are two folders there
dirnames <- dirnames %>% filter(.[[1]] != "shared")
CyVerseName <- dirnames[1,1]
print("Your CyVerse UserName:")
CyVerseName

# Construct a path to the user's data store
out_path <- sprintf("/data-store/iplant/home/%s/", CyVerseName)
print("The path to your data store:")
out_path

# Make a temporary file inside the container
fileConn <- file("FileInContainer.txt", "a") 
writeLines(sprintf("This is an example."), fileConn)
close(fileConn)

# Construct the output file name and Use file.copy() to copy the file to the data store
out_file <- sprintf("/data-store/iplant/home/%s/FileInDataStore.txt", CyVerseName)
file.copy("FileInContainer.txt", out_file, overwrite=TRUE)  # replaces an existing file of same name

# Part 2. Zip / Unzip

# Zip a file inside the container and copy the zipfile to the data store
# Re-create or add to the temporary file
fileConn <- file("FileInContainer.txt", "a") 
writeLines(sprintf("This is another example."), fileConn)
close(fileConn)
# Zip it
zip(zipfile = "test.zip", files = "FileInContainer.txt")
# Construct the output file name and Use file.copy() to copy the file to the data store
out_file <- sprintf("/data-store/iplant/home/%s/ZipFileInDataStore.zip", CyVerseName)
file.copy("test.zip", out_file, overwrite=TRUE)  # replaces an existing file of same name

# Unzip a zipfile from the data store
#   Delete the original unzipped text file if it exists in the container
if(file.exists("FileInContainer.txt")) { file.remove("FileInContainer.txt") }
# Copy zipfile from the data store and Unzip it inside the container
file.copy(out_file, "test2.zip",overwrite=TRUE)
unzip("test2.zip")
