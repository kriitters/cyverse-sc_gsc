# Dockerfile to run spatcon and grayspatcon scripts in R command line
# Built on vice-cli-bash (Tyson Swetnam) 
#
# Setup in the image:
# The user is 'jovyan',
# Home directory is /home/jovyan
# Cyverse directories start at /home/jovyan/data-store
#	- when run on CyVerse the user's home and data-store directories appear in there
# 
# Additions
# install r-base-core, r-base-dev, several R libraries to support C programs
# amend directory structure copy various files into the image
# use the same ENTRYPOINT as vice-cli-bash
#
FROM harbor.cyverse.org/vice/cli/bash:latest
# default user is "jovyan", home dir /home/jovyan, sudo priv

# ########### Update / upgrade ###########
RUN sudo apt-get update \
	# && sudo apt-get upgrade -y  \
    && sudo apt-get install apt-utils dialog -y \
	&& sudo apt-get autoremove -y \
    && sudo apt-get clean all
# Things needed for R
RUN sudo apt-get install r-base-core r-base-dev -y 
RUN sudo apt-get install gdal-bin libgdal-dev libudunits2-0 libudunits2-dev -y
COPY install_packages.R /install_packages.R
RUN sudo Rscript /install_packages.R
RUN sudo rm -f /install_packages.R
# Create directory structure with example data, code, docs etc
# --- Install grayspatcon
COPY GraySpatCon_CyVerse_autorun.R /home/jovyan/GraySpatCon_CyVerse_autorun.R
# Copy code and documentation files (ADD copies the contents of a directory, not the directory itself)
ADD grayspatcon/code /home/jovyan/grayspatcon/code
ADD grayspatcon/documentation /home/jovyan/grayspatcon/documentation
# Copy test files (tif imagse and parameter files)
ADD grayspatcon/grayspatcon_input /home/jovyan/grayspatcon/grayspatcon_input
RUN sudo chown -R jovyan /home/jovyan/grayspatcon*
#
# --- Install spatcon
COPY SpatCon_CyVerse_autorun.R /home/jovyan/SpatCon_CyVerse_autorun.R
# Copy code and documentation files (ADD copies the contents of a directory, not the directory itself)
ADD spatcon/code /home/jovyan/spatcon/code
ADD spatcon/documentation /home/jovyan/spatcon/documentation
# Copy test files (tif imagse and parameter files)
ADD spatcon/spatcon_input /home/jovyan/spatcon/spatcon_input
RUN sudo chown -R jovyan /home/jovyan/spatcon*
#

# ######### End of R install ############
# create ~/data-store for CSI driver fuse mount
#RUN mkdir /home/jovyan/data-store
RUN echo 'set-option -g status off' >> ~/.tmux.conf
# entry.sh starts terminal
#COPY entry.sh /bin

#ENTRYPOINT ["bash", "/bin/entry.sh"]

# docker build -t fubar .
# docker run -it --rm -p 7681:7681 fubar
# point browser to 0.0.0.0:7681
# once started, cd into home/grayspatcon or /spatcon and run
#   Rscript '02_code/<name of R script>'
# test autorun of grayspatcon
COPY entry2.sh /bin/entry2.sh
RUN sudo chmod +x /bin/entry2.sh
ENTRYPOINT ["bash", "/bin/entry2.sh"]
