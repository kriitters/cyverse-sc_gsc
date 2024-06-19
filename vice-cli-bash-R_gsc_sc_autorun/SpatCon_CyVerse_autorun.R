# R script to run SpatCon in auto-run mode on CyVerse
# Kurt Riitters June 2024 for use in CyVerse installation only
# **********
# Input files (tif images and parameter files) are read from the user-selected input directory
#   It is selected at runtime
# Output and log files are written to the data store directory "analyses", in a new sub-directory.
#   The sub-directory has a CyVerse-assigned name.
# spatcon will be executed for each combination of input tif and parameter files.
#   An output file name consists of the base name of the tif image, and the parameter values. 
# **********
# For usage please refer to the SpatCon Guide (pdf)
# The parameter file differs from the SpatCon Guide in the following ways:
#  1. All eight parameters MUST appear in the parameter file, even if they are not relevant for a given analysis.
#  2. Each of the input images can have a different recode table. The name of the input file must be
#        like <image>.rec where <image> is the basename of the .tif file.
#  3. The missing value on the input tif image MUST be 255.
# **********
# DISCLAIMER:
# The author(s), their employer(s), the archive host(s), nor any part of the United States federal government
# can assure the reliability or suitability of this software for a particular purpose. The act of distribution 
# shall not constitute any such warranty, and no responsibility is assumed for a user's application of this 
# software or related materials.
library(terra)
library(gdalUtilities)
library(tidyr)
library(dplyr)

# Check for proper installation
if(!file.exists("~/spatcon")) {
  stop("spatcon is not installed. Please check your installation")
}
setwd("~/spatcon")
# In auto-run mode the input data are in a user-selected directory in /data-store/input/
cmd <-sprintf("ls /data-store/input")
dirnames <- as.data.frame(system(cmd, intern=TRUE))
user_inputdir <-dirnames[1,1]
infile_path <- sprintf("/data-store/input/%s", user_inputdir)

# Set the output directory to the user's home/Analyses/xxx symlink. 
outfile_path <- sprintf("/data-store/output")
# get a list of tif and TIF files in the input directory
# ?i makes it case insensitive, $ excludes .xml, .ovr etc, full names includes path
tif_files <- list.files(path = infile_path, pattern = '(?i)\\.tif$', full.names=TRUE)
# ensure at least one file
if(length(tif_files) == 0){
  stop("No input tif (.tif or .TIF) files found in spatcon_input.")
}
# get a list of parameters.txt files in the input directory
par_files <- list.files(path = infile_path, pattern = '(?i)\\.txt$', full.names=TRUE)
# ensure at least one file
if(length(par_files) == 0){
  stop("No input parameter (.txt) text files found in spatcon_input.")
}
# define the logfiles
now <- Sys.time()  # This is UTC time
now <-paste0(format(now, "%m%d%Y_%Z%H%M%S")) 				# converts posixct to chars, no spaces or colons
extlogname <- sprintf("%s/SpatCon_%s.log", outfile_path, now) 	# external path and filename
logname <- sprintf("tmplog")							# temporary logfile in container; copied to external at the end
# loop over tif files
for (i in 1:length(tif_files)) {
  # Convert the input from GeoTIFF to BSQ named "gscinput" (no extension)
  scinput_tif <- tif_files[i]
  print(" ")
  print(" ")
  print(paste("Input tif: ", tif_files[i]))
  write(scinput_tif, logname, append=TRUE)
  an.error.occured <- FALSE
  tryCatch( { R0 <- rast(scinput_tif)},
            error = function(e) { an.error.occured <<- TRUE }
  )
  if(an.error.occured == TRUE) {
    msgline = "This is not a valid tif image. Skipping to next image."
    write(msgline, logname, append=TRUE)
    print("This is not a valid tif image.")
    print("Skipping to next image.")
    print("GDAL will issue a warning message when the script completes.")
    next
  }
  # basic check of input file
  data_type <- datatype(R0)
  if(data_type != "INT1U") {
    msgline = "This is not an 8-bit tif image. Skipping to next image."
    write(msgline, logname, append=TRUE)
    print("This is not an 8-bit tif.")
    print("Skipping to next image.")
    next
  }
  print(paste("Output file path: ", outfile_path))
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
    write(pars, logname, append=TRUE)
    if(file.exists("scpars.txt")) {
      file.remove("scpars.txt")
    }
    file.copy(pars, "scpars.txt")
    #### Process the parameter file ###
    parfile <- read.table("scpars.txt", sep = "")
    onepar <- parfile %>% dplyr::filter((V1 == "R") | (V1 == "r"))
    if(length(onepar$V2) == 0) {
      msgline = "No R parameter specified. Skipping to next image."
      write(msgline, logname, append=TRUE)
      print("No R parameter specified.")
      print("Skipping to next case.")
      next
    }
    else{ Rpar = onepar$V2}
    onepar <- parfile %>% dplyr::filter((V1 == "W") | (V1 == "w"))
    if(length(onepar$V2) == 0) {
      msgline = "No W parameter specified. Skipping to next image."
      write(msgline, logname, append=TRUE)
      print("No W parameter specified.")
      print("Skipping to next case.")
      next
    }
    else{ Wpar = onepar$V2}
    onepar <- parfile %>% dplyr::filter((V1 == "A") | (V1 == "a"))
    if(length(onepar$V2) == 0) {
      msgline = "Warning: no A parameter specified. Setting to value 0. This MAY cause SpatCon exit."
      write(msgline, logname, append=TRUE)
      print("Warning: no A parameter specified. Setting to value 0. This MAY cause SpatCon exit.")
      Apar = 0
    }
    else{ Apar = onepar$V2}
    onepar <- parfile %>% dplyr::filter((V1 == "B") | (V1 == "b"))
    if(length(onepar$V2) == 0) {
      msgline = "Warning: no B parameter specified. Setting to value 0. This MAY cause SpatCon exit."
      write(msgline, logname, append=TRUE)
      print("Warning: no B parameter specified. Setting to value 0. This MAY cause SpatCon exit.")
      Bpar = 0
    }
    else{ Bpar = onepar$V2}
    onepar <- parfile %>% dplyr::filter((V1 == "H") | (V1 == "h"))
    if(length(onepar$V2) == 0) {
      msgline = "Warning: no H parameter specified. Setting to value 0. This MAY cause SpatCon exit."
      write(msgline, logname, append=TRUE)
      print("Warning: no H parameter specified. Setting to value 0. This MAY cause SpatCon exit.")
      Hpar = 0
    }
    else{ Hpar = onepar$V2}
    onepar <- parfile %>% dplyr::filter((V1 == "F") | (V1 == "f"))
    if(length(onepar$V2) == 0) {
      msgline = "Warning: no F parameter specified. Setting to value 0. This MAY cause SpatCon exit."
      write(msgline, logname, append=TRUE)
      print("Warning: no F parameter specified. Setting to value 0. This MAY cause SpatCon exit.")
      Fpar = 0
    }
    else{ Fpar = onepar$V2}
    onepar <- parfile %>% dplyr::filter((V1 == "Z") | (V1 == "z"))
    if(length(onepar$V2) == 0) {
      msgline = "Warning: no Z parameter specified. Setting to value 0. This MAY cause SpatCon exit."
      write(msgline, logname, append=TRUE)
      print("Warning: no Z parameter specified. Setting to value 0. This MAY cause SpatCon exit.")
      Zpar = 0
    }
    else{ Zpar = onepar$V2}
    onepar <- parfile %>% dplyr::filter((V1 == "M") | (V1 == "m"))
    if(length(onepar$V2) == 0) {
      msgline = "Warning: no M parameter specified. Setting to value 0. This MAY cause SpatCon exit."
      write(msgline, logname, append=TRUE)
      print("Warning: no M parameter specified. Setting to value 0. This MAY cause SpatCon exit.")
      Mpar = 0
    }
    else{ Mpar = onepar$V2}
    # check for parameter consistency
    if( (Hpar == 2) & ((Rpar == 21) | (Rpar == 82) | (Rpar == 83))) {
      msgline = "Invalid combination of H and R parameter values. Skipping to next case."
      write(msgline, logname, append=TRUE)
      print("Invalid combination of H and R parameter values.")
      print("Skipping to next case")
      next
    }
    if( (Fpar == 1) & ((Rpar == 1) | (Rpar == 6) | (Rpar == 7) | (Rpar == 10))) {
      msgline = "Invalid combination of F and R parameter values. Skipping to next case."
      write(msgline, logname, append=TRUE)
      print("Invalid combination of F and R parameter values.")
      print("Skipping to next case")
      next
    }
    if( ( (Rpar == 75) | (Rpar == 76) | (Rpar == 77) | (Rpar == 78) | (Rpar == 81) | (Rpar == 82) | (Rpar == 83))){
      if(Apar == Mpar) {
        msgline = "First target code (A parameter) cannot equal missing code (M parameter). Skipping to next case."
        write(msgline, logname, append=TRUE)
        print("First target code (A parameter) cannot equal missing code (M parameter)")
        print("Skipping to next case")
        next
      }
    }
    if( ( (Rpar == 76) | (Rpar == 78) | (Rpar == 82) | (Rpar == 83))){
      if(Bpar == Mpar) {
        msgline = "Second target code (B parameter) cannot equal missing code (M parameter). Skipping to next case."
        write(msgline, logname, append=TRUE)
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
        msgline = "Re-code requested but no recode file supplied. Skipping to next case."
        write(msgline, logname, append=TRUE)
        print("Re-code requested but no recode file supplied.")
        print("Skipping to next case")
        next
      } 
      else {file.copy(recname, "screcode.txt")}
    } 
    # write input and parameter file names to logfile, preceded by blank lines
    blankline = " "
    write(blankline, logname, append=TRUE)
    write(tif_files[i], logname, append=TRUE)
    write(par_files[j], logname, append=TRUE)
    if(Zpar == 1) {
      write(recname, logname, append=TRUE)
    }
    # Execute SpatCon. SC will write information/error messages in the logfile.
    runline = "Starting spatcon."
    write(runline, logname, append=TRUE)
    cmd <-sprintf("code/spatcon_lin64 >> %s",logname)
    ret_val <- system(cmd)
    if(ret_val != 0L){
      msgline = "Error executing SpatCon. Skipping to next case."
      write(msgline, logname, append=TRUE)
      blankline = " "
      write(blankline, logname, append=TRUE)
      write(blankline, logname, append=TRUE)
      print("Error executing SpatCon. Check logfile.")
      print("Skipping to next case.")
      next
    }
    if(ret_val == 0L) {
      # Post-processing tif output file 
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
      filename <- basename(in_name) # get rid of path
      filename <- tools::file_path_sans_ext(filename) # get rid of .tif extension
      tif_name <- sprintf("%s/%s", outfile_path, filename) 	# external path and filename w/o extension
      # append run parameters to filename
      newtif_name <- sprintf("%s_SpatCon_R%d_W%d_A%d_B%d_H%d_F%d_Z%d_M%d.tif", tif_name, Rpar, Wpar, Apar, Bpar, Hpar, Fpar, Zpar, Mpar)
      # write to data-store via file.copy()
      gdal_translate("scoutput.bsq", "fubar", of="Gtiff", co=c("COMPRESS=LZW", "BIGTIFF=YES"))
      file.copy("fubar", newtif_name, overwrite = TRUE)
      # Clean up temporary output files on disk
      file.remove("scoutput.bsq")
      file.remove("scoutput.hdr")
      file.remove("scpars.txt")
      file.remove("fubar")
      if(file.exists("fubar.xml")) {
        file.remove("fubar.xml")
      }
      if(file.exists("fubar.aux.xml")) {
        file.remove("fubar.aux.xml")
      }	  
      # remove any other .xml files in output directory
      xml_files <- list.files(outfile_path, pattern = '(?i)\\.xml$', full.names=TRUE)
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
  if(file.exists("scinput.aux.xml")) { 
    file.remove("scinput.aux.xml")
  }
  if(file.exists("scpars.txt")) { # can occur if last run was not successful
    file.remove("scpars.txt")
  }
} # end of loop over all files
# Log file:
file.copy(logname, extlogname, overwrite=TRUE)
if(file.exists(logname)) {
  file.remove(logname)
}
print(extlogname)
# A GDAL message in the console above this line probably 
#   indicates a non-tif input image; that image was skipped.
# SC run-time errors are recorded in the log file.
# *************** end of R script to run SpatCon **********************
#
