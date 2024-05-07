# Linux R script to run GraySpatCon in docker image
# Kurt Riitters December 2023
# **********
# Be sure to set working directory correctly, to run from the root of the gsc tree.
# eg R> setwd("~/grayspatcon") or Rstudio Session/Set Working Directory
# **********
# The parameter file differs from the GraySpatCon Guide in the following ways:
#   1. The "R" and "C" parameters are not required because this script will add them
#   from the input tif files. (There is no harm done by including them because the values
#   from the tif files are added to the end of the parameter file and will obviate existing values.)
#   
# V3 Jan 2024.
#   Add two loops to (a) process all .TIF/.tif files in directory /01_input, and
#     (b) for each tif file, use all parameter .par files in directory /01_input,
# V4 Jan 2024. Added logile output, checking input file type.
# V5 May 2024. Adaptation for CyVerse ONLY. Changed location of 01_input, 03_output, and 05_logfiles to CyVerse
# 	user's data-store directory: /home/jovyan/data-store/home/<username>/Input_Output/GraySpatCon/
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
if(!file.exists("02_code/grayspatcon_lin64")) {
  print("Please ensure the working directory is grayspatcon.")
  stop("Invalid working directory")
}
# V5: get the CyVerse user name and set directory names
CyVerseUser <- Sys.getenv("IPLANT_USER")
infile_path <- sprintf("/home/jovyan/data-store/home/%s/Input_Output/GraySpatCon/01_input", CyVerseUser)
outfile_path <- sprintf("/home/jovyan/data-store/home/%s/Input_Output/GraySpatCon/03_output", CyVerseUser)
logfile_path <- sprintf("/home/jovyan/data-store/home/%s/Input_Output/GraySpatCon/05_logfiles", CyVerseUser)
# V5: end of code block
# get a list of tif and TIF files in the input directory
# ?i makes it case insensitive, $ excludes .xml, .ovr etc, full names includes path
# V5 one line change
tif_files <- list.files(path = infile_path, pattern = '(?i)\\.tif$', full.names=TRUE)
#tif_files <- list.files(path = '01_input', pattern = '(?i)\\.tif$', full.names=TRUE)
# ensure at least one file
if(length(tif_files) == 0){
  print("No input tif (.tif or .TIF) files found in 01_input/. Are you in the correct working directory?")
  stop("exiting R script")
}
# get a list of parameters.txt files in the input directory
# V5 one line change
par_files <- list.files(path = infile_path, pattern = '(?i)\\.txt$', full.names=TRUE)
#par_files <- list.files(path = '01_input', pattern = '(?i)\\.txt$', full.names=TRUE)
# ensure at least one file
if(length(par_files) == 0){
  print("No input parameter (.txt) text files found in 01_input/. Are you in the correct working directory?")
  stop("exiting R script")
}
# define the logfile
basedir <- getwd()
now <- Sys.time()
now <-paste0(format(now, "%Y%m%d_%H%M%S")) # converts posixct to chars, no spaces or colons
# V5. One line change
logname <- sprintf("%s/%s.log", logfile_path, now)
#logname <- sprintf("%s/05_logfiles/%s.log", basedir, now)
# loop over tif files
for (i in 1:length(tif_files)) {
  # Convert the input from GeoTIFF to BSQ named "gscinput" (no extension)
  gscinput_tif <- tif_files[i]
  print(" ")
  print(" ")
  print(paste("Input tif: ", tif_files[i]))
  an.error.occured <- FALSE
  tryCatch( { R0 <- rast(gscinput_tif)},
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
  # gdal_translate also writes an envi-style header file (gscinput.hdr) that will be used later.
  gdal_translate(gscinput_tif, "gscinput", of="ENVI")
  # loop over parameter files
  for (j in 1:length(par_files)) {
    pars <- par_files[j]
    print(paste("Parameters: ", par_files[j]))
    if(file.exists("gscpars.txt")) {
      file.remove("gscpars.txt")
    }
      file.copy(pars, "gscpars.txt")
      # Get the R and C parameters and add to the gscpars.txt file
      Rpar <- nrow(R0)
      Cpar <- ncol(R0)
      fileConn <- file("gscpars.txt", "a") # open file connection for appending
      writeLines(sprintf("R %d", Rpar), fileConn)
      writeLines(sprintf("C %d", Cpar), fileConn)
      close(fileConn)
#### Process the parameter file file ####
      parfile <- read.table("gscpars.txt", sep = "")
      # the G, F, and M parameters are also used in post-processing
      onepar <- parfile %>% dplyr::filter((V1 == "G") | (V1 == "g"))
      if(length(onepar$V2) == 0) {
        print("No G parameter specified.")
        print("Skipping to next case.")
        next
      }
      else{ Gpar = onepar$V2}
      onepar <- parfile %>% dplyr::filter((V1 == "M") | (V1 == "m"))
      if(length(onepar$V2) == 0) {
        print("No M parameter specified.")
        print("Skipping to next case.")
        next
      }
      else{ Mpar = onepar$V2}
      onepar <- parfile %>% dplyr::filter((V1 == "F") | (V1 == "f"))
      if(length(onepar$V2) == 0) {
        print("No F parameter specified.")
        print("Skipping to next case.")
        next
      }
      else{ Fpar = onepar$V2}
      onepar <- parfile %>% dplyr::filter((V1 == "P") | (V1 == "p"))
      if(length(onepar$V2) == 0) {
        print("R warning: no P parameter specified. Setting to value 0. This MAY cause GraySpatCon exit.")
        Ppar = 0
      }
      else{ Ppar = onepar$V2}
      onepar <- parfile %>% dplyr::filter((V1 == "W") | (V1 == "w"))
      if(length(onepar$V2) == 0) {
        print("R warning: no W parameter specified. Setting to value 0. This MAY cause GraySpatCon exit.")
        Wpar = 0
      }
      else{ Wpar = onepar$V2}
      onepar <- parfile %>% dplyr::filter((V1 == "B") | (V1 == "b"))
      if(length(onepar$V2) == 0) {
        print("R warning: no B parameter specified. Setting to value 0. This MAY cause GraySpatCon exit.")
        Bpar = 0
      }
      else{ Bpar = onepar$V2}
      onepar <- parfile %>% dplyr::filter((V1 == "A") | (V1 == "a"))
      if(length(onepar$V2) == 0) {
        print("R warning: no A parameter specified. Setting to value 0. This MAY cause GraySpatCon exit.")
        Apar = 0
      }
      else{ Apar = onepar$V2}
      onepar <- parfile %>% dplyr::filter((V1 == "X") | (V1 == "x"))
      if(length(onepar$V2) == 0) {
        print("R warning: no X parameter specified. Setting to value 0. This MAY cause GraySpatCon exit.")
        Xpar = 0
      }
      else{ Xpar = onepar$V2}
      onepar <- parfile %>% dplyr::filter((V1 == "Y") | (V1 == "y"))
      if(length(onepar$V2) == 0) {
        print("R warning: no Y parameter specified. Setting to value 0. This MAY cause GraySpatCon exit.")
        Ypar = 0
      }
      else{ Ypar = onepar$V2}
      onepar <- parfile %>% dplyr::filter((V1 == "K") | (V1 == "k"))
      if(length(onepar$V2) == 0) {
        print("R warning: no K parameter specified. Setting to value 0. This MAY cause GraySpatCon exit.")
        Kpar = 0
      }
      else{ Kpar = onepar$V2}
#### end of parameter file processing ####
      # write input and parameter file names to logfile, preceded by two blank lines
      blankline = " "
      write(blankline, logname, append=TRUE)
      write(blankline, logname, append=TRUE)
      write(tif_files[i], logname, append=TRUE)
      write(par_files[j], logname, append=TRUE)
      # Execute GraySpatCon. GSC will write information/error messages in the logfile.
      cmd <-sprintf("02_code/grayspatcon_lin64 >> %s",logname)
      ret_val <- system(cmd)
      if(ret_val != 0L){
        print("Error executing GraySpatCon. Ensure the working directory is grayspatcon")
        print("Skipping to next case.")
        next
      }
      if(ret_val == 0L) {
#### Post-processing G=0 tif output file ####
          if(Gpar == 0) { # map output for window analysis
          # Convert output file to GeoTIFF: rename output file, copy/edit header file, create GeoTIFF using appropriate nodata values
          # Rename output file
          old <- c("gscoutput")
          new <- c("gscoutput.bsq")
          file.rename(old, new)
          
          # Copy and edit the input BSQ header file. This is an ENVI-style header.
          oldhdr <- readLines("gscinput.hdr")
          newhdr <- oldhdr 
          # There is no need to edit the header if the F=1 (byte output with missing=255)
          if(Fpar == 2){
            # Change the data type from 1 (byte) to 4 (float).
            newhdr <- gsub(pattern = "data type = 1", replace = "data type = 4", x = newhdr)
            # Change the missing data value from 255 to metric-dependent value
            if(Mpar == 44 || Mpar==45 || Mpar==50) {
              newhdr <- gsub(pattern = "data ignore value = 255", replace = "data ignore value = -9000000.0", x = newhdr)
            }
            else {
              newhdr <- gsub(pattern = "data ignore value = 255", replace = "data ignore value = -0.0100000", x = newhdr)
            }
          }
          writeLines(newhdr, "gscoutput.hdr")
          # Convert the disk file from BSQ to GeoTIFF, using metric-dependent nodata value
          # define new name for output tif, based on root of input filename
          in_name <- tif_files[i]
          # V5. two lines changed, only one line needed
          tif_name <- gsub(pattern = '01_input/', replace='03_output/', x=in_name)
          #out_name <- gsub(pattern = '01_input/', replace='', x=in_name)
          #tif_name <- paste0("03_output/", out_name)
          # append run parameters to filename
          newtif_name <- sprintf("%s_M%d_G%d_W%d_F%d_A%d_B%d_P%d_X%d_Y%d_K%d.tif", tif_name, Mpar, Gpar, Wpar, Fpar, Apar, Bpar, Ppar, Xpar, Ypar, Kpar)
          newtif_name <- gsub(pattern = ".tif_", replace = "_", x = newtif_name)
          newtif_name <- gsub(pattern = ".TIF_", replace = "_", x = newtif_name)
          # V5. direct write to data-store dumps core, try this change
          gdal_translate("gscoutput.bsq", "fubar", of="Gtiff", co=c("COMPRESS=LZW", "BIGTIFF=YES"))
          file.copy("fubar", newtif_name)
          # gdal_translate("gscoutput.bsq", newtif_name, of="Gtiff", co=c("COMPRESS=LZW", "BIGTIFF=YES"))
          # Clean up temporary output files on disk
          file.remove("gscoutput.bsq")
          file.remove("gscoutput.hdr")
          file.remove("gscpars.txt")
          #V5. 4 lines added
          file.remove("fubar")
          if(file.exists("fubar.xml")) {
            file.remove("fubar.xml")
          }
          # remove any other .xml files in output directory
          #V5. one line change
          xml_files <- list.files(outfile_path, pattern = '(?i)\\.xml$', full.names=TRUE)
          #xml_files <- list.files(path = '03_output', pattern = '(?i)\\.xml$', full.names=TRUE)
          if(length(xml_files) > 0){
            for (fu in 1:length(xml_files)) {
              file.remove(xml_files[fu])
            }
          }
        } # end of post-processing G=0 tif file
#### Post-processing G=1 text output file ####
        if(Gpar == 1) { # post-processing text output from global analysis
          # define new name for output txt, based on root of input filename
          in_name <- tif_files[i]
          #V5. change two lines to one line
          txt_name <- gsub(pattern = '01_input/', replace='03_output/', x=in_name)
          #out_name <- gsub(pattern = '01_input/', replace='', x=in_name)
          #txt_name <- paste0("03_output/", out_name)
          # append run parameters to filename
          newtxt_name <- sprintf("%s_M%d_G%d_W%d_F%d_A%d_B%d_P%d_X%d_Y%d_K%d.txt", txt_name, Mpar, Gpar, Wpar, Fpar, Apar, Bpar, Ppar, Xpar, Ypar, Kpar)
          newtxt_name <- gsub(pattern = ".tif_", replace = "_", x = newtxt_name)
          newtxt_name <- gsub(pattern = ".TIF_", replace = "_", x = newtxt_name)
          file.copy("gscoutput.txt", newtxt_name, overwrite = TRUE)
          # clean up temp files
          file.remove("gscoutput.txt")
          file.remove("gscpars.txt")
    #### End ####
        } # end of post processing G=1 text file
      } # end of processing gsc ret_val = 0L
    } # end of loop for all parameter files for one input tif
    file.remove("gscinput.hdr")
    file.remove("gscinput")
    # remove a file created by gdal_translate
    file.remove("gscinput.aux.xml")
    if(file.exists("gscpars.txt")) { # can occur if last run was not successful
      file.remove("gscpars.txt")
    }
} # end of loop over all files
# Log file:
print(logname)
# A GDAL message in the console above this line probably 
#   indicates a non-tif input image; that image was skipped.
# GSC run-time errors are recorded in the log file.
# *************** end of R script to run GraySpatCon **********************
#
