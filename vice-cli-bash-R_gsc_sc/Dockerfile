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
# --- grayspatcon
# force empty input, output, and logfiles directories to exist
WORKDIR /home/jovyan/grayspatcon/01_input
WORKDIR /home/jovyan/grayspatcon/03_output
WORKDIR /home/jovyan/grayspatcon/05_logfiles
# Copy code and documentation files (ADD copies the contents of a directory, not the directory itself)
ADD grayspatcon/02_code /home/jovyan/grayspatcon/02_code
ADD grayspatcon/04_documentation /home/jovyan/grayspatcon/04_documentation
# Copy any test files to jovyan input directory
ADD grayspatcon/01_input /home/jovyan/grayspatcon/01_input
#
# --- spatcon
# force empty input, output, and logfiles directories to exist
WORKDIR /home/jovyan/spatcon/01_input
WORKDIR /home/jovyan/spatcon/03_output
WORKDIR /home/jovyan/spatcon/05_logfiles
# Copy code and documentation files 
ADD spatcon/02_code /home/jovyan/spatcon/02_code
ADD spatcon/04_documentation /home/jovyan/spatcon/04_documentation
# Copy any test files to jovyan input directory
ADD spatcon/01_input /home/jovyan/spatcon/01_input
WORKDIR /home/jovyan
#


# ######### End of R install ############
# create ~/data-store for CSI driver fuse mount
#RUN mkdir /home/jovyan/data-store
RUN echo 'set-option -g status off' >> ~/.tmux.conf
# entry.sh starts terminal
#COPY entry.sh /bin
ENTRYPOINT ["bash", "/bin/entry.sh"]
# docker build -t fubar .
# docker run -it --rm -p 7681:7681 fubar
# point browser to 0.0.0.0:7681
# once started, cd into home/grayspatcon or /spatcon and run
#   Rscript '02_code/<name of R script>'