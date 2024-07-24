# This follows the example from vice cli https://github.com/cyverse-vice/cli/blob/main/bash/
#   to get a bash shell / terminal running on CyVerse.
# Purpose is to test R deployment via CyVerse executable (non-interactive)
FROM rexec1_2
USER ubuntu
# add directory for iRODS iCommands to user profile as JSON, see entry.sh
RUN mkdir /home/ubuntu/.irods 
#
# Create directory structure with example data, code, docs etc
# --- Install grayspatcon
COPY GraySpatCon_CyVerse_autorun.R /home/ubuntu/GraySpatCon_CyVerse_autorun.R
# Copy code and documentation files (ADD copies the contents of a directory, not the directory itself)
ADD grayspatcon/code /home/ubuntu/grayspatcon/code
ADD grayspatcon/documentation /home/ubuntu/grayspatcon/documentation
# Copy test files (tif imagse and parameter files)
ADD grayspatcon/grayspatcon_input /home/ubuntu/grayspatcon/grayspatcon_input
RUN sudo chown -R ubuntu /home/ubuntu/grayspatcon*
#
# --- Install spatcon
COPY SpatCon_CyVerse_autorun.R /home/ubuntu/SpatCon_CyVerse_autorun.R
# Copy code and documentation files (ADD copies the contents of a directory, not the directory itself)
ADD spatcon/code /home/ubuntu/spatcon/code
ADD spatcon/documentation /home/ubuntu/spatcon/documentation
# Copy test files (tif imagse and parameter files)
ADD spatcon/spatcon_input /home/ubuntu/spatcon/spatcon_input
RUN sudo chown -R ubuntu /home/ubuntu/spatcon*
#
# testing
COPY testscript.R /home/ubuntu/testscript.R
#
WORKDIR /home/ubuntu/data-store/
COPY entry.sh /home/ubuntu/entry.sh
# add temporary output directory in container
RUN mkdir /home/ubuntu/output
ENTRYPOINT ["bash", "/home/ubuntu/entry.sh"]
