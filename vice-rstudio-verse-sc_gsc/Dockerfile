# Dockerfile to run spatcon and grayspatcon scripts in RStudio server
# Built on rstudio-verse (Tyson Swetnam) which is built on rocker/verse
# Hint: look at scripts in /rocker_scripts to see what's installed.
# Setup in the image:
# Rstudio running in cyverse-like environment
# The user is 'rstudio', password is 'rstudio1'
# Home directory is /home/rstudio
# Cyverse directories start at /home/rstudio/data-store
#	- when run on CyVerse the user's home and data-store directories appear in there
# 
# Additions
# start from the above, add things to make new image vice-rstudio-verse-sc-gsc
# the run command is then
# docker run -it --rm -p 8787:80 -e REDIRECT_URL=http://localhost:8787 vice-rstudio-verse-sc_gsc:latest
# update.packages, and install several R libraries
# amend directory structure copy various files into the image
# use the same ENTRYPOINT as rstudio-verse
#
# Added second Rscript to install FHM requested libraries for FIA, raster etc
# 
# Use the Swetnam image supporting RStudio and nginx servers on cyverse
FROM harbor.cyverse.org/vice/rstudio/verse:latest

# the default USER is rstudio, so use sudo for some things
# additional R install scripts include update.packages()
# install R packages to support SC and GSC scripts (gdalUtilities, terra, tidyr) 
COPY install_packages.R /install_packages.R
RUN sudo Rscript /install_packages.R
RUN sudo rm -f /install_packages.R
# install R packages to support FIA work (doParallel, sp, FIESTA, raster, rFIA) 
COPY install_packages_FIAsupport.R /install_packages_FIAsupport.R
RUN sudo Rscript /install_packages_FIAsupport.R
RUN sudo rm -f /install_packages_FIAsupport.R

# --- grayspatcon
# force empty input, output, and logfiles directories to exist
WORKDIR /home/rstudio/grayspatcon/01_input
WORKDIR /home/rstudio/grayspatcon/03_output
WORKDIR /home/rstudio/grayspatcon/05_logfiles
# Copy code and documentation files (ADD copies the contents of a directory, not the directory itself)
ADD grayspatcon/02_code /home/rstudio/grayspatcon/02_code
ADD grayspatcon/04_documentation /home/rstudio/grayspatcon/04_documentation
# Copy any test files to rstudio input directory
ADD grayspatcon/01_input /home/rstudio/grayspatcon/01_input
#
# --- spatcon
# force empty input, output, and logfiles directories to exist
WORKDIR /home/rstudio/spatcon/01_input
WORKDIR /home/rstudio/spatcon/03_output
WORKDIR /home/rstudio/spatcon/05_logfiles
# Copy code and documentation files 
ADD spatcon/02_code /home/rstudio/spatcon/02_code
ADD spatcon/04_documentation /home/rstudio/spatcon/04_documentation
# Copy any test files to rstudio input directory
ADD spatcon/01_input /home/rstudio/spatcon/01_input
#
# Same as base image:
ENTRYPOINT ["/usr/local/bin/run.sh"]
#docker run -it --rm -p 8787:80 -e REDIRECT_URL=http://localhost:8787 vice-rstudio-verse-gsc:latest