# Dockerfile to run spatcon and grayspatcon scripts in RStudio server
# Built on rstudio-verse (Tyson Swetnam) which is built on rocker/verse
#
# Setup in the image:
# Rstudio and nginx servers running in cyverse-like environment
# The user is 'rstudio', password is 'rstudio1'
# Home directory is /home/rstudio
# Cyverse directories start at /home/rstudio/data-store
#	- when run on CyVerse the user's home and data-store directories appear in there
# 
# Additions
# start from the above, add things to make new image like vice-rstudio-verse-sc-gsc
# the run command is then
# docker run -it --rm -p 8787:80 -e REDIRECT_URL=http://localhost:8787 vice-rstudio-verse-sc_gsc:latest
# install several R libraries
# amend directory structure copy various files into the image
# use the same ENTRYPOINT as rstudio-verse
#
# Use the Swetnam image supporting RStudio and nginx servers on cyverse
FROM harbor.cyverse.org/vice/rstudio/verse:latest

# the default USER is rstudio, so use sudo for some things
# install R packages to support scripts (gdalUtilities, terra) and shiny apps (shinyFiles, shinyjs)
COPY install_packages.R /install_packages.R
RUN Rscript /install_packages.R
RUN sudo rm -f /install_packages.R

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