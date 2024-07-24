#!/bin/bash
# The ENTRYPOINT shell for an Rscript executable docker image on CyVerse
#	illustrating interaction between DE "app" arguments and shell arguments
# Kurt Riitters, July 2024
#
# Useful de-bugging information is written to the "logs" directory in the user's Data Store
#	"analyses" directory. condor-stderr-0 reports failures. condor-stdout-0 reports outputs from
#	this script. JobParameters.csv shows the order and value of arguments passed to this script.
#
# From the dockerfile there is a user "ubuntu" with UID=1000, and directories /home/ubuntu/, 
#	/home/ubuntu/data-store/, and /home/ubuntu/.irods/.
#
# CyVerse sets $IPLANT_USER as the current user (who is running the container). e.g., "kriitters"
export HOME=/home/ubuntu
echo "this is the current CyVerse username: $IPLANT_USER"  
# This exposes $IPLANT_USER's external Data Store volumes within the container at: ~/data-store/. 
echo '{"irods_host": "data.cyverse.org", "irods_port": 1247, "irods_user_name": "$IPLANT_USER", "irods_zone_name": "iplant"}' | envsubst > $HOME/.irods/irods_environment.json
# 
echo "the name of this shell is: $0"  		# /home/ubuntu/entry.sh
echo "these are the run-time parameters set in the DE app:"
echo "this is the Rscript executable: $1" 	# /usr/local/bin/Rscript
echo "this is the R script: $2"				# /home/ubuntu/SpatCon_CyVerse_autorun.R
echo "this is the input directory: $3"		# <a user-selected directory in user's Data Store>
echo "this is the output directory: $4"		# <a user-defined name used to create a directory in the "analyses" folder in the user's Data Store>
# The dockerfile starts the user in /home/ubuntu/data-store
echo "this is the current directory set in the dockerfile: "
pwd
echo "this is the environment of entry.sh"
env

# Input and output directories.
# CyVerse reads the input directory files into the container, then executes this shell,
#	then copies the entire contents of ~/data-store/ to the user's Data Store "analyese" directory.
# The user's Data Store is not otherwise available to this shell, or to the executables run by this shell.
echo "listing of /home/ubuntu:"
ls -alR /home/ubuntu

# The input directory.
echo "listing of the input directory:"
ls /home/ubuntu/data-store/$3
# Note: while the user's input data directory is copied into ~/data-store/, that directory is EXCLUDED
#	during the later copying of ~/data-store/* into the user's Data Store "analyses" directory.

# The output directory.
# First, make the directory inside the container. This must be done here and not in the dockerfile
#	because CyVerse may/will trash ~/data-store/ when starting the container. This example illustrates
#	using a user-defined output directory name, the directory could be a generic "output" and in that
#	case there would be no need for a DE "section" to name it.
mkdir /home/ubuntu/data-store/$4
# The important thing is that all the outputs to be saved must put in there, so that they will become
#	available in the user's Data Store after job completion.
# For now, just put something there.
cp /home/ubuntu/testscript.R /home/ubuntu/data-store/$4/testscript.R
echo "listing of the output directory:"
ls /home/ubuntu/data-store/$4
# Then the contents are available in the $3 subdirectory in the analyses directory 
#
echo "try running spatcon manually: "
/home/ubuntu/spatcon/code/spatcon_lin64

# Running this app.
$1 $2
