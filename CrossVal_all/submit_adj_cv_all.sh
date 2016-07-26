

#!/bin/sh

# embedded options to qsub - start with #PBS

# -- our name ---

#PBS -N Adj_CV_ALL

# -- specify queue --

#PBS -q compute

# -- number of processors/cores/nodes --

#PBS -l nodes=1:ppn=1

# -- user email address --

#PBS -M 

# -- mail notification --

# -- time limit for the process

#PBS -l walltime=00:12:00:00

# -- Job array specification --

#PBS -t 1-24%24

# -- run in the current working (submission) directory --

cd $PBS_O_WORKDIR

Rscript /zhome/60/4/49213/Dropbox/InverseOpt/InvOpt_Forecast/Simulated/CrossVal_all/cross_validation_adj_all.R $PBS_ARRAYID

