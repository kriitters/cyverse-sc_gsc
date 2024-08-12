# Using rver 
#   Following https://rocker-project.org/images/versioned/r-ver.html
#   but using 4.1.1 https://github.com/rocker-org/rocker/issues/505
FROM rocker/r-ver:4.1.1
USER root
ENV TZ=America/Phoenix
ENV LANG=C.UTF-8 
ENV LC_ALL=en_US.UTF-8
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone
# Set up R
RUN echo 'options(repos = c(CRAN = "https://cloud.r-project.org"))' >>"${R_HOME}/etc/Rprofile.site"
#RUN echo 'options(repos = c(P3M = "https://packagemanager.posit.co/cran/__linux__/jammy/latest", CRAN = "https://cloud.r-project.org"))' >>"${R_HOME}/etc/Rprofile.site"
RUN apt update \
	&& apt upgrade -y \
# gettext-base is needed for command envsubst in entry.sh
# gdal-bin, libgdal, libudunits, libudunits2-dev for R packages gdalUtilities, terra
    && apt install apt-utils dialog gettext-base gdal-bin libgdal-dev libudunits2-0 libudunits2-dev sudo -y  \
	&& apt autoremove -y \
    && apt clean all 
# copy script and install R packages - devtools, gdalUtilities, terra, tidyr
#   devtools needed to install some FIA packages
COPY install_packages.R /bin/install_packages.R
RUN Rscript /bin/install_packages.R
RUN rm -f /bin/install_packages.R
# end of R setup
# Set up user ruser
RUN useradd ruser
# Add sudo to user ruser; this is needed to run a chown on a dynamic volume mount in entry.sh
RUN echo "ruser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers 
# switch to ruser, prepare for CyVerse, and install SpatCon and GraySpatCon  
USER ruser
WORKDIR /home/ruser/data-store/
RUN export PATH=/usr/local/bin:/usr/local/lib/R:$PATH
COPY entry.sh /home/ruser/entry.sh
# add directory for iRODS iCommands to user profile as JSON, see entry.sh and https://github.com/cyverse-vice/cli/blob/main/bash/
RUN mkdir /home/ruser/.irods 
# --- Install grayspatcon
COPY GraySpatCon_CyVerse_autorun.R /home/ruser/GraySpatCon_CyVerse_autorun.R
ADD grayspatcon/code /home/ruser/grayspatcon/code
ADD grayspatcon/documentation /home/ruser/grayspatcon/documentation
# Copy test files (tif images and parameter files)
ADD grayspatcon/grayspatcon_input /home/ruser/grayspatcon/grayspatcon_input
RUN sudo chown -R ruser /home/ruser/grayspatcon*
# --- Install spatcon
COPY SpatCon_CyVerse_autorun.R /home/ruser/SpatCon_CyVerse_autorun.R
ADD spatcon/code /home/ruser/spatcon/code
ADD spatcon/documentation /home/ruser/spatcon/documentation
# Copy test files (tif images and parameter files)
ADD spatcon/spatcon_input /home/ruser/spatcon/spatcon_input
RUN sudo chown -R ruser /home/ruser/spatcon*
# end of SC and GSC install
# for running in CyVerse app
ENTRYPOINT ["bash", "/home/ruser/entry.sh"]
# or use this for debugging locally
#ENTRYPOINT ["bash"]
