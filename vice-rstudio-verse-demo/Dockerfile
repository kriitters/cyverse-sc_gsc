# Dockerfile to create an RStudio demonstration app for USFS
#   Includes grayspatcon to illustrate scripts and folder setups.
# Kurt Riitters. May 2024.
# Built on rstudio-verse (Tyson Swetnam) which is built on rocker/verse
# The user is 'rstudio', password is 'rstudio1'
# Home directory is /home/rstudio
# Cyverse data-store directories are symlinked in /home/rstudio/data-store,
#   and hard mounted at /data-store/iplant/home/<CyVerseName>/.
# 
# When running the container on a local machine, the run command is 
# docker run -it --rm -p 8787:80 -e REDIRECT_URL=http://localhost:8787 <image name>:latest
# Then point a browser to http://localhost:8787/
# #####
# Use the Swetnam image supporting RStudio server on cyverse
FROM harbor.cyverse.org/vice/rstudio/verse:latest
# the default USER is rstudio, so use sudo for some things
# additional R install scripts include update.packages()
# install R packages to support GSC scripts (gdalUtilities, terra, tidyr) 
COPY install_packages.R /install_packages.R
RUN sudo Rscript /install_packages.R
RUN sudo rm -f /install_packages.R
# Add demo script
ADD RStudio_Tutorial_1.R /home/rstudio/demo/RStudio_Tutorial_1.R
#
# Same as base image: Among other things this sets up the iRODS environment for dynamic links to data-store
ENTRYPOINT ["/usr/local/bin/run.sh"]
