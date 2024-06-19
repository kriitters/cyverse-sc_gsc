# R script to run GraySpatCon in auto-run mode on CyVerse on CyVerse
# Kurt Riitters June 2024 for use in CyVerse installation only
# **********
# Input files (tif images and parameter files) are read from the user-selected input directory
#   It is selected at runtime
# Output and log files are written to the data store directory "analyses", in a new sub-directory.
#   The sub-directory has a CyVerse-assigned name.
# grayspatcon will be executed for each combination of input tif and parameter files.
#   An output file name consists of the base name of the tif image, and the parameter values. 
# **********
# For usage please refer to the GraySpatCon Guide (pdf)
# The parameter file differs from the GraySpatCon Guide in the following ways:
#   1. The "R" and "C" parameters are not required because this script will add them
#   from the input tif files. (There is no harm done by including them because the values
#   from the tif files are added to the end of the parameter file and will obviate existing values.)
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
if(!file.exists("~/grayspatcon")) {
  stop("grayspatcon is not installed. Please check your installation")
}
setwd("~/grayspatcon")
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
  stop("No input tif (.tif or .TIF) files found in grayspatcon_input.")
}
# get a list of parameters.txt files in the input directory
par_files <- list.files(path = infile_path, pattern = '(?i)\\.txt$', full.names=TRUE)
# ensure at least one file
if(length(par_files) == 0){
  stop("No input parameter (.txt) text files found in grayspatcon_input.")
}
# define the logfiles
now <- Sys.time()  # This is UTC time
now <-paste0(format(now, "%m%d%Y_%Z%H%M%S")) 				# converts posixct to chars, no spaces or colons
extlogname <- sprintf("%s/GraySpatCon_%s.log", outfile_path, now) 	# external path and filename
logname <- sprintf("tmplog")							# temporary logfile in container; copied to external at the end
# loop over tif files
for (i in 1:length(tif_files)) {
  # Convert the input from GeoTIFF to BSQ named "gscinput" (no extension)
  gscinput_tif <- tif_files[i]
  print(" ")
  print(" ")
  print(paste("Input tif: ", tif_files[i]))
  write(gscinput_tif, logname, append=TRUE)
  an.error.occured <- FALSE
  tryCatch( { R0 <- rast(gscinput_tif)},
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
  # gdal_translate also writes an envi-style header file (gscinput.hdr) that will be used later.
  gdal_translate(gscinput_tif, "gscinput", of="ENVI")
  # loop over parameter files
  for (j in 1:length(par_files)) {
    pars <- par_files[j]
    print(paste("Parameters: ", par_files[j]))
    write(pars, logname, append=TRUE)
    if(file.exists("gscpars.txt")) {
      file.remove("gscpars.txt")
    }
    file.copy(pars, "tmp.txt", overwrite=TRUE)
    # Get the R and C parameters and add to the gscpars.txt file
    Rpar <- nrow(R0)
    Cpar <- ncol(R0)
    fileConn <- file("gscpars.txt", "a") # open file connection for appending
    writeLines(sprintf("R %d", Rpar), fileConn)
    writeLines(sprintf("C %d", Cpar), fileConn)
    # close(fileConn)
    #### Process the parameter file file ####
    parfile <- read.table("tmp.txt", sep = "")
    onepar <- parfile %>% dplyr::filter((V1 == "G") | (V1 == "g"))
    if(length(onepar$V2) == 0) {
      msgline = "No G parameter specified. Skipping to next image."
      write(msgline, logname, append=TRUE)
      print("No G parameter specified.")
      print("Skipping to next case.")
      next
    }
    else{ 
		Gpar = onepar$V2
		writeLines(sprintf("G %d", Gpar), fileConn)
	}
    onepar <- parfile %>% dplyr::filter((V1 == "M") | (V1 == "m"))
    if(length(onepar$V2) == 0) {
      msgline = "No M parameter specified. Skipping to next image."
      write(msgline, logname, append=TRUE)
      print("No M parameter specified.")
      print("Skipping to next case.")
      next
    }
    else{ 
		Mpar = onepar$V2
		writeLines(sprintf("M %d", Mpar), fileConn)
	}
    onepar <- parfile %>% dplyr::filter((V1 == "F") | (V1 == "f"))
    if(length(onepar$V2) == 0) {
      msgline = "No F parameter specified. Skipping to next image."
      write(msgline, logname, append=TRUE)
      print("No F parameter specified.")
      print("Skipping to next case.")
      next
    }
    else{ 
		Fpar = onepar$V2
		writeLines(sprintf("F %d", Fpar), fileConn)
	}
    onepar <- parfile %>% dplyr::filter((V1 == "P") | (V1 == "p"))
    if(length(onepar$V2) == 0) {
      msgline = "No P parameter specified. Setting to value 0. This MAY cause GraySpatCon exit."
      write(msgline, logname, append=TRUE)
      print("Warning: no P parameter specified. Setting to value 0. This MAY cause GraySpatCon exit.")
      Ppar = 0
    }
    else{ 
		Ppar = onepar$V2
		writeLines(sprintf("P %d", Ppar), fileConn)
	}
    onepar <- parfile %>% dplyr::filter((V1 == "W") | (V1 == "w"))
    if(length(onepar$V2) == 0) {
      msgline = "Warning: no W parameter specified. Setting to value 0. This MAY cause GraySpatCon exit."
      write(msgline, logname, append=TRUE)
      print("Warning: no W parameter specified. Setting to value 0. This MAY cause GraySpatCon exit.")
      Wpar = 0
    }
    else{ 
		Wpar = onepar$V2
		writeLines(sprintf("W %d", Wpar), fileConn)
	}
    onepar <- parfile %>% dplyr::filter((V1 == "B") | (V1 == "b"))
    if(length(onepar$V2) == 0) {
      msgline = "Warning: no B parameter specified. Setting to value 0. This MAY cause GraySpatCon exit."
      write(msgline, logname, append=TRUE)
      print("Warning: no B parameter specified. Setting to value 0. This MAY cause GraySpatCon exit.")
      Bpar = 0
    }
    else{ 
		Bpar = onepar$V2
		writeLines(sprintf("B %d", Bpar), fileConn)
	}
    onepar <- parfile %>% dplyr::filter((V1 == "A") | (V1 == "a"))
    if(length(onepar$V2) == 0) {
      msgline = "Warning: no A parameter specified. Setting to value 0. This MAY cause GraySpatCon exit."
      write(msgline, logname, append=TRUE)
      print("Warning: no A parameter specified. Setting to value 0. This MAY cause GraySpatCon exit.")
      Apar = 0
    }
    else{ 
		Apar = onepar$V2
		writeLines(sprintf("A %d", Apar), fileConn)
	}
    onepar <- parfile %>% dplyr::filter((V1 == "X") | (V1 == "x"))
    if(length(onepar$V2) == 0) {
      msgline = "Warning: no X parameter specified. Setting to value 0. This MAY cause GraySpatCon exit."
      write(msgline, logname, append=TRUE)
      print("Warning: no X parameter specified. Setting to value 0. This MAY cause GraySpatCon exit.")
      Xpar = 0
    }
    else{ 
		Xpar = onepar$V2
		writeLines(sprintf("X %d", Xpar), fileConn)
	}
    onepar <- parfile %>% dplyr::filter((V1 == "Y") | (V1 == "y"))
    if(length(onepar$V2) == 0) {
      msgline = "Warning: no Y parameter specified. Setting to value 0. This MAY cause GraySpatCon exit."
      write(msgline, logname, append=TRUE)
      print("Warning: no Y parameter specified. Setting to value 0. This MAY cause GraySpatCon exit.")
      Ypar = 0
    }
    else{ 
		Ypar = onepar$V2
		writeLines(sprintf("Y %d", Ypar), fileConn)
	}
    onepar <- parfile %>% dplyr::filter((V1 == "K") | (V1 == "k"))
    if(length(onepar$V2) == 0) {
      msgline = "Warning: no K parameter specified. Setting to value 0. This MAY cause GraySpatCon exit."
      write(msgline, logname, append=TRUE)
      print("Warning: no K parameter specified. Setting to value 0. This MAY cause GraySpatCon exit.")
      Kpar = 0
    }
    else{ 
		Kpar = onepar$V2
		writeLines(sprintf("K %d", Kpar), fileConn)
	}
	close(fileConn)
    #### end of parameter file processing ####
    runline = "Starting grayspatcon."
    write(runline, logname, append=TRUE)
    # Execute GraySpatCon. GSC will write information/error messages in the logfile.
    cmd <-sprintf("code/grayspatcon_lin64 >> %s",logname)
    ret_val <- system(cmd)
    if(ret_val != 0L){
      msgline = "Error executing GraySpatCon. Skipping to next case."
      write(msgline, logname, append=TRUE)
      blankline = " "
      write(blankline, logname, append=TRUE)
      write(blankline, logname, append=TRUE)
      print("Error executing GraySpatCon. Check logfile.")
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
        filename <- basename(in_name) # get rid of path
        filename <- tools::file_path_sans_ext(filename) # get rid of .tif extension
        tif_name <- sprintf("%s/%s", outfile_path, filename) 	# external path and filename w/o extension
        # append run parameters to filename
        newtif_name <- sprintf("%s_GraySpatCon_M%d_G%d_W%d_F%d_A%d_B%d_P%d_X%d_Y%d_K%d.tif", tif_name, Mpar, Gpar, Wpar, Fpar, Apar, Bpar, Ppar, Xpar, Ypar, Kpar)
        # write to data-store via file.copy()
        gdal_translate("gscoutput.bsq", "fubar", of="Gtiff", co=c("COMPRESS=LZW", "BIGTIFF=YES"))
        file.copy("fubar", newtif_name, overwrite = TRUE)
        # Clean up temporary output files
        file.remove("gscoutput.bsq")
        file.remove("gscoutput.hdr")
        file.remove("gscpars.txt")
		file.remove("tmp.txt")
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
      } # end of post-processing G=0 tif file
      #### Post-processing G=1 text output file ####
      if(Gpar == 1) { # post-processing text output from global analysis
        # define new name for output txt, based on root of input filename
        
        
        in_name <- tif_files[i]
        filename <- basename(in_name) # get rid of path
        filename <- tools::file_path_sans_ext(filename) # get rid of .tif extension
        txt_name <- sprintf("%s/%s", outfile_path, filename) 	# external path and filename w/o extension
        # append run parameters to filename
        newtxt_name <- sprintf("%s_GraySpatCon_M%d_G%d_W%d_F%d_A%d_B%d_P%d_X%d_Y%d_K%d.txt", txt_name, Mpar, Gpar, Wpar, Fpar, Apar, Bpar, Ppar, Xpar, Ypar, Kpar)
        file.copy("gscoutput.txt", newtxt_name, overwrite = TRUE)
        # clean up temp files
        file.remove("gscoutput.txt")
        file.remove("gscpars.txt")
		file.remove("tmp.txt")
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
file.copy(logname, extlogname, overwrite=TRUE)
if(file.exists(logname)) {
  file.remove(logname)
}
print(extlogname)
# A GDAL message in the console above this line probably 
#   indicates a non-tif input image; that image was skipped.
# GSC run-time errors are recorded in the log file.
# *************** end of R script to run GraySpatCon **********************
#
