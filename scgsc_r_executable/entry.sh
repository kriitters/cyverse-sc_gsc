#!/bin/bash
# The ENTRYPOINT shell for an Rscript executable docker image on CyVerse
#	illustrating interaction between DE "app" arguments and shell arguments
# Kurt Riitters, August 2024
#
# Useful de-bugging information is written to the "logs" directory in the user's Data Store
#	"analyses" directory. condor-stderr-0 reports failures. condor-stdout-0 reports outputs from
#	this script. JobParameters.csv shows the order and value of arguments passed to this script.
#
# From the dockerfile there is a user "ruser" with UID=1000, and directories /home/ruser/, 
#	/home/ruser/data-store/, and /home/ruser/.irods/ 
#
# Input and output directories.
# CyVerse reads the input directory files into the container, then executes this shell,
#	then copies the non-input parts of ~/data-store/ to the user's Data Store "analyses" directory.
# The user's Data Store is not otherwise available to this shell, or to the executables run by this shell.
#
# required: not debug info
# This exposes $IPLANT_USER's external Data Store volumes within the container at: ~/data-store/. 
echo '{"irods_host": "data.cyverse.org", "irods_port": 1247, "irods_user_name": "$IPLANT_USER", "irods_zone_name": "iplant"}' | envsubst > $HOME/.irods/irods_environment.json
# Setup the Rscript usage
# The output directory inside the container. This must be done here and not in the dockerfile. Outputs saved 
#    here will become available in the user's Data Store/analyses/<analysisname>/$4 after job completion.
mkdir /home/ruser/data-store/$4
export INDIR="/home/ruser/data-store/$3"
export OUTDIR="/home/ruser/data-store/$4"
# Running this app. ( /usr/local/bin/Rscript <Rscript>.R )
$1 $2
#
# Debug info (move the preceding line to the end when debugging)
# CyVerse sets $IPLANT_USER as the current user (who is running the container). e.g., "kriitters"
echo "the current CyVerse username: $IPLANT_USER"  
echo "the name of this shell is: $0"  		# /home/ruser/entry.sh
echo "these are the run-time parameters set in the DE app:"
echo "the Rscript executable: $1" 	# /usr/local/bin/Rscript
echo "the R script: $2"				# e.g., /home/ruser/SpatCon_CyVerse_autorun.R
echo "the input directory: $3"		# <a user-selected directory in user's Data Store>
echo "the output directory: $4"		# <a user-defined name used to create a directory in the "analyses" folder in the user's Data Store>
echo "ls alR on /home:"
ls -alR /home
echo " "
echo "---------the environment------------"
env



