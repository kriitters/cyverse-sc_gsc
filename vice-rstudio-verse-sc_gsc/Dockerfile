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
# update.packages (none currently), and install several R libraries
# amend directory structure copy various files into the image
# use the same ENTRYPOINT as rstudio-verse
#
# Rscript installs R packages needed to run SC/GSC
# 
# Use the Swetnam image supporting RStudio and nginx servers on cyverse
FROM harbor.cyverse.org/vice/rstudio/verse:latest

# the default USER is rstudio, so use sudo for some things
# install R packages to support SC and GSC scripts (gdalUtilities, terra, tidyr) 
COPY install_packages.R /install_packages.R
RUN sudo Rscript /install_packages.R
RUN sudo rm -f /install_packages.R

# --- Install grayspatcon
COPY GraySpatCon_CyVerse.R /home/rstudio/GraySpatCon_CyVerse.R
# Copy code and documentation files (ADD copies the contents of a directory, not the directory itself)
ADD grayspatcon/code /home/rstudio/grayspatcon/code
ADD grayspatcon/documentation /home/rstudio/grayspatcon/documentation
# Copy test files (tif imagse and parameter files)
ADD grayspatcon/grayspatcon_input /home/rstudio/grayspatcon/grayspatcon_input
RUN sudo chown -R rstudio /home/rstudio/grayspatcon*
#
# --- Install spatcon
COPY SpatCon_CyVerse.R /home/rstudio/SpatCon_CyVerse.R
# Copy code and documentation files (ADD copies the contents of a directory, not the directory itself)
ADD spatcon/code /home/rstudio/spatcon/code
ADD spatcon/documentation /home/rstudio/spatcon/documentation
# Copy test files (tif imagse and parameter files)
ADD spatcon/spatcon_input /home/rstudio/spatcon/spatcon_input
RUN sudo chown -R rstudio /home/rstudio/spatcon*
#
# Same as base image:
ENTRYPOINT ["/usr/local/bin/run.sh"]
#docker run -it --rm -p 8787:80 -e REDIRECT_URL=http://localhost:8787 harbor.cyverse.org/usfs/kriitters/rstudio_scgsc:latest
#docker run -it --rm -p 8787:80 -e REDIRECT_URL=http://localhost:8787 vice-rstudio-verse-gsc:latest