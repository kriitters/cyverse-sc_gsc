# Linux R script to run SpatCon in docker image
# Kurt Riitters February 2024
# **********
# Be sure to set working directory correctly, to run from the root of the sc tree.
# eg R> setwd("~/spatcon") or Rstudio Session/Set Working Directory
# **********
# The parameter file differs from the SpatCon Guide in the following ways:
#  1. All eight parameters MUST appear in the parameter file, even if they are not relevant for a given analysis.
#  2. Each of the input images can have a different recode table. The name of the input file must be
#        like <image>.rec where <image> is the basename of the .tif file.
#  3. The missing value on the input tif image MUST be 255.
#
#
# V1. February 2024
#   Adapted from GraySpatCon R script
#   
# DISCLAIMER:
# The author(s), their employer(s), the archive host(s), nor any part of the United States federal government
# can assure the reliability or suitability of this software for a particular purpose. The act of distribution 
# shall not constitute any such warranty, and no responsibility is assumed for a user's application of this 
# software or related materials.
library(terra)
library(gdalUtilities)
library(tidyr)

# Ensure correct location in folder structure
if(!file.exists("02_code/spatcon_lin64")) {
  print("Please ensure the working directory is spatcon.")
  stop("Invalid working directory")
}
# get a list of tif and TIF files in the input directory
# ?i makes it case insensitive, $ excludes .xml, .ovr etc, full names includes path
tif_files <- list.files(path = '01_input', pattern = '(?i)\\.tif$', full.names=TRUE)
# ensure at least one file
if(length(tif_files) == 0){
  print("No input tif (.tif or .TIF) files found in 01_input/. Are you in the correct working directory?")
  stop("exiting R script")
}
# get a list of parameters.txt files in the input directory
par_files <- list.files(path = '01_input', pattern = '(?i)\\.txt$', full.names=TRUE)
# ensure at least one file
if(length(par_files) == 0){
  print("No input parameter (.txt) text files found in 01_input/. Are you in the correct working directory?")
  stop("exiting R script")
}
# define the logfile
basedir <- getwd()
now <- Sys.time()
now <-paste0(format(now, "%Y%m%d_%H%M%S")) # converts posixct to chars, no spaces or colons
logname <- sprintf("%s/05_logfiles/%s.log", basedir, now)
# loop over tif files
for (i in 1:length(tif_files)) {
  # Convert the input from GeoTIFF to BSQ named "scinput" (no extension)
  scinput_tif <- tif_files[i]
  print(" ")
  print(" ")
  print(paste("Input tif: ", tif_files[i]))
  an.error.occured <- FALSE
  tryCatch( { R0 <- rast(scinput_tif)},
            error = function(e) { an.error.occured <<- TRUE }
  )
  if(an.error.occured == TRUE) {
    print("This is not a valid tif image.")
    print("Skipping to next image.")
    print("GDAL will issue a warning message when the script completes.")
    next
  }
  # basic check of input file
  data_type <- datatype(R0)
  if(data_type != "INT1U") {
    print("This is not an 8-bit tif.")
    print("Skipping to next image.")
    next
  }
  # gdal_translate also writes an envi-style header file (scinput.hdr) that will be used later.
  gdal_translate(scinput_tif, "scinput", of="ENVI")
  # write scsize.txt
  if(file.exists("scsize.txt")) {
      file.remove("scsize.txt")
  }
  nrows <- nrow(R0)
  ncols <- ncol(R0)
  fileConn <- file("scsize.txt", "a") # open file connection for appending
  writeLines(sprintf("nrows %d", nrows), fileConn)
  writeLines(sprintf("ncols %d", ncols), fileConn)
  close(fileConn)
  # loop over parameter files
  for (j in 1:length(par_files)) {
    pars <- par_files[j]
    print(paste("Parameters: ", par_files[j]))
    if(file.exists("scpars.txt")) {
      file.remove("scpars.txt")
    }
      file.copy(pars, "scpars.txt")
      #### Process the parameter file ###
      parfile <- read.table("scpars.txt", sep = "")
      onepar <- parfile %>% dplyr::filter((V1 == "R") | (V1 == "r"))
      if(length(onepar$V2) == 0) {
        print("No R parameter specified.")
        print("Skipping to next case.")
        next
      }
      else{ Rpar = onepar$V2}
      onepar <- parfile %>% dplyr::filter((V1 == "W") | (V1 == "w"))
      if(length(onepar$V2) == 0) {
        print("No W parameter specified.")
        print("Skipping to next case.")
        next
      }
      else{ Wpar = onepar$V2}
      onepar <- parfile %>% dplyr::filter((V1 == "A") | (V1 == "a"))
      if(length(onepar$V2) == 0) {
        print("Warning: no A parameter specified. Setting to value 0. This MAY cause SpatCon exit.")
        Apar = 0
      }
      else{ Apar = onepar$V2}
      onepar <- parfile %>% dplyr::filter((V1 == "B") | (V1 == "b"))
      if(length(onepar$V2) == 0) {
        print("Warning: no B parameter specified. Setting to value 0. This MAY cause SpatCon exit.")
        Bpar = 0
      }
      else{ Bpar = onepar$V2}
      onepar <- parfile %>% dplyr::filter((V1 == "H") | (V1 == "h"))
      if(length(onepar$V2) == 0) {
        print("Warning: no H parameter specified. Setting to value 0. This MAY cause SpatCon exit.")
        Hpar = 0
      }
      else{ Hpar = onepar$V2}
      onepar <- parfile %>% dplyr::filter((V1 == "F") | (V1 == "f"))
      if(length(onepar$V2) == 0) {
        print("Warning: no F parameter specified. Setting to value 0. This MAY cause SpatCon exit.")
        Fpar = 0
      }
      else{ Fpar = onepar$V2}
      onepar <- parfile %>% dplyr::filter((V1 == "Z") | (V1 == "z"))
      if(length(onepar$V2) == 0) {
        print("Warning: no Z parameter specified. Setting to value 0. This MAY cause SpatCon exit.")
        Zpar = 0
      }
      else{ Zpar = onepar$V2}
      onepar <- parfile %>% dplyr::filter((V1 == "M") | (V1 == "m"))
      if(length(onepar$V2) == 0) {
        print("Warning: no M parameter specified. Setting to value 0. This MAY cause SpatCon exit.")
        Mpar = 0
      }
      else{ Mpar = onepar$V2}
      # check for parameter consistency
      if( (Hpar == 2) & ((Rpar == 21) | (Rpar == 82) | (Rpar == 83))) {
        print("Invalid combination of H and R parameter values.")
        print("Skipping to next case")
        next
      }
      if( (Fpar == 1) & ((Rpar == 1) | (Rpar == 6) | (Rpar == 7) | (Rpar == 10))) {
        print("Invalid combination of F and R parameter values.")
        print("Skipping to next case")
        next
      }
      if( ( (Rpar == 75) | (Rpar == 76) | (Rpar == 77) | (Rpar == 78) | (Rpar == 81) | (Rpar == 82) | (Rpar == 83))){
        if(Apar == Mpar) {
          print("First target code (A parameter) cannot equal missing code (M parameter)")
          print("Skipping to next case")
          next
        }
      }
      if( ( (Rpar == 76) | (Rpar == 78) | (Rpar == 82) | (Rpar == 83))){
        if(Bpar == Mpar) {
          print("Second target code (B parameter) cannot equal missing code (M parameter)")
          print("Skipping to next case")
          next
        }
      }
#### end of parameter file processing ####
	  # handle the recode file
	  if(Zpar == 1) {
		  if(file.exists("screcode.txt")) {
      		file.remove("screcode.txt")
   		}
		  basename <- scinput_tif
		  basename <- gsub(pattern = ".tif", replace = "", x = basename)
      basename <- gsub(pattern = ".TIF", replace = "", x = basename)
      recname  <- sprintf("%s.rec", basename)
      if(!file.exists(recname)) {
        print("Re-code requested but no recode file supplied.")
        print("Skipping to next case")
        next
      } 
      else {file.copy(recname, "screcode.txt")}
		 } 
      # write input and parameter file names to logfile, preceded by blank lines
      blankline = " "
      write(blankline, logname, append=TRUE)
      write(blankline, logname, append=TRUE)
      write(tif_files[i], logname, append=TRUE)
      write(par_files[j], logname, append=TRUE)
      if(Zpar == 1) {
        write(recname, logname, append=TRUE)
      }
      # Execute SpatCon. SC will write information/error messages in the logfile.
      cmd <-sprintf("02_code/spatcon_lin64 >> %s",logname)
      ret_val <- system(cmd)
      if(ret_val != 0L){
        print("Error executing SpatCon. Ensure the working directory is spatcon")
        print("Skipping to next case.")
        next
      }
      if(ret_val == 0L) {
#### Post-processing tif output file ####
          # Convert output file to GeoTIFF: rename output file, copy/edit header file, create GeoTIFF using appropriate nodata values
          # Rename output file
          old <- c("scoutput")
          new <- c("scoutput.bsq")
          file.rename(old, new)
          
          # Copy and edit the input BSQ header file. This is an ENVI-style header.
          oldhdr <- readLines("scinput.hdr")
          newhdr <- oldhdr 
          # There is no need to edit the header if the F=0 (byte output with missing=0)
          if(Fpar == 1){
            # Change the data type from 1 (byte) to 4 (float).
            newhdr <- gsub(pattern = "data type = 1", replace = "data type = 4", x = newhdr)
            # Change the missing data value from 255 to -0.01
            newhdr <- gsub(pattern = "data ignore value = 255", replace = "data ignore value = -0.0100000", x = newhdr)
          }
          writeLines(newhdr, "scoutput.hdr")
          # Convert the disk file from BSQ to GeoTIFF, using metric-dependent nodata value
          # define new name for output tif, based on root of input filename
          in_name <- tif_files[i]
          out_name <- gsub(pattern = '01_input/', replace='', x=in_name)
          tif_name <- paste0("03_output/", out_name)
          # append run parameters to filename
          newtif_name <- sprintf("%s_R%d_W%d_A%d_B%d_H%d_F%d_Z%d_M%d.tif", tif_name, Rpar, Wpar, Apar, Bpar, Hpar, Fpar, Zpar, Mpar)
          newtif_name <- gsub(pattern = ".tif_", replace = "_", x = newtif_name)
          newtif_name <- gsub(pattern = ".TIF_", replace = "_", x = newtif_name)
          gdal_translate("scoutput.bsq", newtif_name, of="Gtiff", co=c("COMPRESS=LZW", "BIGTIFF=YES"))
          # Clean up temporary output files on disk
          file.remove("scoutput.bsq")
          file.remove("scoutput.hdr")
          file.remove("scpars.txt")
          # remove any other .xml files in output directory
          xml_files <- list.files(path = '03_output', pattern = '(?i)\\.xml$', full.names=TRUE)
          if(length(xml_files) > 0){
            for (fu in 1:length(xml_files)) {
              file.remove(xml_files[fu])
            }
          }
         # end of post-processing tif file
      } # end of processing sc ret_val = 0L
      if(file.exists("screcode.txt")) {
        file.remove("screcode.txt")
      }
    } # end of loop for all parameter files for one input tif
    file.remove("scinput.hdr")
    file.remove("scinput")
    file.remove("scsize.txt")
    # remove a file created by gdal_translate
    file.remove("scinput.aux.xml")
    if(file.exists("scpars.txt")) { # can occur if last run was not successful
      file.remove("scpars.txt")
    }
} # end of loop over all files
# Log file:
print(logname)
# A GDAL message in the console above this line probably 
#   indicates a non-tif input image; that image was skipped.
# SC run-time errors are recorded in the log file.
# *************** end of R script to run SpatCon **********************
#
