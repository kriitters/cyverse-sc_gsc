FROM ubuntu:23.10
USER root
RUN  apt-get update \
    &&  apt-get install apt-utils dialog -y \
	&&  apt-get autoremove -y \
    &&  apt-get clean all
# gettext-base is needed for command envsubst in entry.sh
RUN apt-get update && \
	apt-get install gettext-base  -y && \
	apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# getting locales error
RUN apt-get update && apt-get install locales && locale-gen en_US.UTF-8
# 
ENV TZ America/Phoenix
ENV LANG=C.UTF-8 
ENV LC_ALL "en_US.UTF-8"
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone
# Add sudo to user ubuntu; this is needed to run a chown on a dynamic volume mount in entry.sh
RUN apt-get update && \
    apt-get install -y sudo && \
    echo "ubuntu ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
   apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# dependencies for R packages gdalUtilities, terra
RUN apt-get update && \
	apt-get install gdal-bin libgdal-dev libudunits2-0 libudunits2-dev -y && \
	apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# fix problem of not finding R packages, change repo
#RUN sed -i "s/\/jp\./\/us\./g" /etc/apt/sources.list
# Install R. This is installing R 4.3.1 Beagle Scouts
RUN apt update && \
    apt-get install r-base-core r-base-dev -y && \
	apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# copy script and install R packages - gdalUtilities, terra, tidyr
COPY install_packages.R /bin/install_packages.R
RUN Rscript /bin/install_packages.R
RUN rm -f /bin/install_packages.R
#
USER ubuntu
WORKDIR /home/ubuntu
ENTRYPOINT ["bash"]
