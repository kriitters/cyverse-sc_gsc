# cyverse-sc_gsc
CyVerse deployment of SpatCon.c (SC) and GraySpatCon (GSC)  
 
## Repository Organization  
<pre>
.  
|-- AUTHORS.md  
|-- README.md  
|-- vice-rstudio-verse-sc_gsc:  
|      SC and GSC on Tyson Swetnam's CyVerse DE VICE app "Rocker RStudio Verse"  
|      vice/rstudio/verse:latest  
|        |-- spatcon  
|        |-- grayspatcon  
|-- vice-rstudio-verse-demo:  
|--	   Used for FS RStudio demo, includes GSC to illustrate R scripts  
|--    SC and GSC on Tyson Swetnam's CyVerse DE VICE app "Rocker RStudio Verse"  
|      vice/rstudio/verse:latest   
|        |-- grayspatcon 
|--  vice-cli-bash-R_gsc_sc  
|      SC and GSC on Tyson Swetnam's CyVerse DE VICE app "Cloud Shell"  
|      This adds ubuntu packages needed to run R CLI apps, and installs R libraries needed to run the scripts.  
|        |-- spatcon  
|        |-- grayspatcon  
</pre>
## Additional Information  
The repository includes Dockerfiles, R scripts, C executables, examples, and documentaton. 