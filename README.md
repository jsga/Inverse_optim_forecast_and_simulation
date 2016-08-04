This repository is a collection of code done during my PhD at the Technical University of Denmark. The main purpose is to pass forward the knowledge to my colleagues (cheers to Nacho and Giulia!), but also for anyone to get inspired on the use of R, GAMS, inverse optimization and parallel computing.


### Contributions
From the coding side, this repository is about:

- Use R for data processing, combined with GAMS&CPLEX for optimization modeling. The interaction is done using the functions from the [R_to_GAMS](https://github.com/jsga/R_to_GAMS) repository.

- Use the [High Performance Computer (HPC)](http://www.hpc.dtu.dk/) from DTU to parallelize the code. Here we do a cross-validation, so the same chunk of code is repeated with different combination of the input parameter.

From the data-analysis point of view, this repository consists on:

- Simulate the consumption of 100 "smart" buildings equipped with an Economic Model Predictive Control system, as in [this](http://www.rasmus.halvgaard.dk/papers/DTUMPC-2012-ISGT-Halvgaard.pdf) paper.

- Forecast the consumption of the 100 building using an **inverse optimization** approach, as in [this](http://arxiv.org/abs/1607.07209) paper. Basically, the aggregate behavior is modeled, or "summarized", by a simple optimization problem, which is characterized by a set of unknown parameters. The parameter estimation process boils down to solving a generalized inverse optimization problem. We overcome the non-linearity by solving instead two linear problems, one of which has a penalization term. The cross-validation obtain the "best" penalization.


### What's inside

- `Simulate_buildings.Rmd` A file explaining the simulation of 100 smart buildings

- `data_2flex` and `data_noflex`: datasets containing the simulated data, for two groups of houses: one with smart system, the other without.

- `CrossVal_all/` Folder containing the scripts used for the cross validation:
	- `prepare_data_init.R` Generate the inputs to be used in each parallel job. In this case it is just values of a parameter.
	- `cross_validation_adj_all.R` To be run in each job. Basically, if performs a forecast for each period and then computes some error measures. It is done in a rolling-horizon procedure and the forecasts are 1-step ahead.
	- `readandstudy_adj_cv_all.R` Reads the output from the cross validation and makes a plot of the out-of-sample error VS the value of _K_.
	- `submit_adj_cv_all.sh` To be executed by the HPC cluster from DTU. See below.

- `GAMS_models/` GAMS models:
	- `HeatPump_House_Z.gms` EMPC for each building
	- `InvForecast_2step.gms` Inverse-forecast algorithm.

- `R_auxiliary_functions/` Folder containing three scripts:
	- `AuxiliaryFunctions.R` Collection of functions that are used to interact easily with GAMS
	- `lagmatrix.R` Function to lag columns of a matrix
	- `R_to_GDX.R` Collection of functions from [R_to_GAMS](https://github.com/jsga/R_to_GAMS).


### HPC parallelization. Sh file

This is performed by the `submit_adj_cv_all.sh` file. In short, we use 1 processor for each job, 24 jobs at the same time, for a maximum processing time of 12 hours:

```
#PBS -l walltime=00:12:00:00

# -- Job array specification --

#PBS -t 1-24%24

# -- run in the current working (submission) directory --

cd $PBS_O_WORKDIR

Rscript /username/Simulated/CrossVal_all/cross_validation_adj_all.R $PBS_ARRAYID

```

In the cluster, the following must be run:

```sh
qrsh
cd CrossVal_all
qsub submit_adj_cv_all.sh
```
To check the status of the jobs, the queue, and delete jobs:

```sh
qstat -a
showq -u username
qdel 00000[00]

```


### R code in each job
Each job runs the script `cross_validation_adj_all.R`. The script starts by reading the job number, which was indicated in the .sh files in *$PBS_ARRAYID*


```R
pbs_iter <- as.numeric(commandArgs(TRUE))
message(paste('pbs_iter = ',pbs_iter,sep=""))
```

Then, we create a folder for each job. In the folders, the GAMS auxiliary files (gdx, lst, etc) will be saved. Folders are indexed with the job number.

```R
newDir = paste(wpath, 'CrossVal_all/working_dir_',pbs_iter,sep="")
dir.create(newDir)
setwd(newDir)
```

Finally, we load the data that is used in each job. In this case, a different value for _K_. Other examples could include different train and test sets.

```R
load(paste(wpath,"CrossVal_all/Init_data/input_",pbs_iter,sep=""))
```


### What this is not, and what is left to do

The code is not meant to be standalone, neither it is as well explained and commented as I would like it to be. It needs to be adapted to each specific problem.

The following can be improved:
- Elaborate on an easy example that shows forecasting using inverse optimization
- Make code more generic, specially the forecast scripts
- Translate the GAMS models to only R, for example by using [lpSolve](http://lpsolve.r-forge.r-project.org/) solver instead of CPLEX
- Clean the simulation platform more simple and modular