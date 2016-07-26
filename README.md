This repository is a collection of code that has been one during the course of my PhD research. The main purpose is to pass forward the knowledge with my colleagues (cheers to Nacho and Giulia!) but also for anyone to get inspired on the use of R, GAMS, inverse optimization and parallel computations.

### Contributions
From the coding-side, this repository does the following:

- Use R for data processing, combined with GAMS&CPLEX for optimization modeling. The interaction is done by using [R_to_GAMS](https://github.com/jsga/R_to_GAMS) repository.

- Use the [High Performance Computer](http://www.hpc.dtu.dk/) from DTU to parallelize the code. Here, as an example, we do a cross-validation, so the same chunk of code is repeated with different combination of input parameters.

From the data analysis point of view, this repository consists on:

- Simulate the consumption of 100 "smart" buildings using an Economic Model Predictive Control approach, as in [this](http://www.rasmus.halvgaard.dk/papers/DTUMPC-2012-ISGT-Halvgaard.pdf) paper.

- Forecast the consumption of the 100 building by using an **inverse optimization** approach, as in [this](http://arxiv.org/abs/1607.07209) paper. Basically, the aggregate behavior is modeled, or "summarized", by a simple optimization problem, which is characterized by a set of unknown parameters. The parameter estimation process boils down to solving a generalized inverse optimization problem.



### What this is not and what is left to do

This code is not meant to be stand alone, neither it is as well explained and commented as I would like it to be. It needs to be adapted to each specific problem.

The following can be improved:
- Elaborate on an easy example that involves forecast
- Make code more generic, specially the forecast scripts
- Translate the GAMS models to only R, for example by using [lpSolve](http://lpsolve.r-forge.r-project.org/) solver instead of CPLEX
- Clean the simulation platform more simple and modular

### What's inside

- `Simulate_buildings` A file explaining the simulation of 100 smart buildings
- `data_2flex` and `data_noflex`: datasets containing the simulated data, for two groups of houses: one with smart system, the other without.
- `CrossVal_all/` Folder containing the scripts used for the cross validation
	-`prepare_data_init.R` Generate inputs to be imported in each parallel job. In this case it is just values of a parameter.
	-`cross_validation_adj_all.R`
	-`readandstudy_adj_cv_all.R`
	-`submit_adj_cv_all.sh` To be run in the HPC cluster from DTU. See below.
- `GAMS_models/` self-explained. Two models are inside: the EMPC for each building, and the inverse-forecast algorithm.
- `R_auxiliary_functions/` Folder containing three scripts:
	- `AuxiliaryFunctions.R` Collection of functions that are used to interact easily with GAMS
	- `lagmatrix.R` Function to lag columns of a matrix
	- `R_to_GDX.R` Collection of functions from [R_to_GAMS](https://github.com/jsga/R_to_GAMS).


### HPC parallelization

This is performed by the `submit_adj_cv_all.sh` file. In short, we use 1 processor for each job, 24 at the same time, for a maximum of 12 hours:

```
#PBS -l walltime=00:12:00:00

# -- Job array specification --

#PBS -t 1-24%24

# -- run in the current working (submission) directory --

cd $PBS_O_WORKDIR

Rscript /zhome/60/4/49213/Dropbox/InverseOpt/InvOpt_Forecast/Simulated/CrossVal_all/cross_validation_adj_all.R $PBS_ARRAYID

```

In the cluster, the following must be run:

```
qrsh
cd CrossVal_all/submit_adj_cv_all.sh
qsub 
```
To check the status of the jobs and the queue:

```
qstat -a
showq -u username
```
