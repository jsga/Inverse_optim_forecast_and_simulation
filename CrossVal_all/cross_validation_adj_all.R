###
### Cross validation, decide on the value of L,E,R
###

wpath = '/home/jsga/inverse_opt/'
gams_file = '/home/jsga/GAMS23.7/gams'
library('gdxrrw')
igdx('/home/jsga/GAMS24.2.1/gams24.2_linux_x64_64_sfx')

#-------------- Load packages and functions --------------# 
source( paste(wpath,'AuxiliaryFunctions.R',sep="")) # Compilation of useful functions
source( paste(wpath,'R_to_GDX.r',sep="")) 


message('--------- Start, load data ----------')

# Read input from command line, namely the data file to be read
pbs_iter <- as.numeric(commandArgs(TRUE))
message(paste('pbs_iter = ',pbs_iter,sep=""))

# Create a separate workign dir for each job
newDir = paste(wpath, 'CrossVal_all/working_dir_',pbs_iter,sep="")
dir.create(newDir)
setwd(newDir)

# Read Grid of K
load(paste(wpath,"CrossVal_all/Init_data/input_",pbs_iter,sep=""))
K = list_input$K
EXP = list_input$EXP
B = 20

# Import data 
dataset_name = 'data_2flex'
load(paste(wpath,dataset_name,sep=""))
message(paste('Dataset:',dataset_name))

#--------------  Select rows - depending on the number of observations --------------# 

Dtrain = 7*24*4 
Dtest = 1 # Hours to predict ahead
Update_horizon = 1 # Indicates how often we perform a parameter estimation, 1 indicates every 15 min. Should be <= Dtest
Update_times = 24*7 # how many times we perform the estimation
Dremove = 24*7

# Select relevant times
Ztrain = Dremove + 1:Dtrain
Ztest = Dremove + (Dtrain+1):(Dtrain+Dtest)
n = length(Ztrain)
weight = ((Ztrain^EXP) /(24*Dtrain)^EXP)


message(' Dtrain = ', Dtrain, " \n B = ",B, "\n K = ", K, "\n EXP = ", EXP )


#--------------  Select columns - What features to use --------------# 

# Build dataframe
data = data_list$data
str(data)

# Select the data
index_load = which(colnames(data) == 'load')
# Explanatory variables for the utility estimaion
name_exo_vars = c("Ta","S",
                  paste('H.',0:23,sep=""),
                  paste('load.l',1:6,sep=""), paste('price.l',1:6,sep=""))
index_expl = which(colnames(data) %in% name_exo_vars)

# Explanatory vars for the ramp estimation (including price)
name_exo_vars_r = c(name_exo_vars)
index_expl_r = which(colnames(data) %in% name_exo_vars_r)




#--------------  Save measures of performance --------------# 
mae = matrix(NA,ncol=Dtest,nrow=Update_times)
rmse = matrix(NA,ncol=Dtest,nrow=Update_times)
mape = matrix(NA,ncol=Dtest,nrow=Update_times)
smape = matrix(NA,ncol=Dtest,nrow=Update_times)
logratio = matrix(NA,ncol=Dtest,nrow=Update_times)
test_C.pred = matrix(NA,ncol=Dtest,nrow=Update_times)
test_C.actual = matrix(NA,ncol=Dtest,nrow=Update_times)
test_Time = matrix(NA,ncol=Dtest,nrow=Update_times)


#--------------  Run Iterative estimation --------------# 

# Iterative
for(i in 1:Update_times){
  message(paste(i,'/',Update_times))
  
  # prepare inputs
  range_exo = apply(data[c(Ztrain,Ztest),index_expl_r],2,range)
  
  
  # Fit parameteres
  start_time = proc.time()  
  Inv_exact = inverse_exact(price_input = data$price[Ztrain],
                            x_meas_input = data$load[Ztrain],
                            Exo_input_r=data[Ztrain,index_expl_r],
                            Exo_input=data[Ztrain,index_expl],
                            B=B, K=K,
                            up_Exo = range_exo[2,],down_Exo = range_exo[1,],
                            w_input=weight,
                            folder_file = paste(wpath,'GAMS_models/',sep=""),
                            gams_file=gams_file)
  
  
  # PREDICTION
  C.predBD = c()
  a_test = matrix(NA,ncol=length(Ztest),nrow=B)
  rU_test = c()
  rD_test = c()
  data_test = data[Ztest,index_expl]
  data_test_r = data[Ztest,index_expl_r]
  
  # Compute the params for the considered (future) time
  a_test = matrix(rep(Inv_exact$coef$mu_a,Dtest),ncol=Dtest) +    matrix(rep(Inv_exact$coef$alpha_a %*% t(data_test),B),ncol=Dtest,byrow=T)
  a_test[1,] = 200
  rU_test = Inv_exact$coef$mu_u + Inv_exact$coef$alpha_u %*% t(data_test_r)
  rD_test = Inv_exact$coef$mu_d + Inv_exact$coef$alpha_d %*% t(data_test_r)
  E_test =  rbind(rD_test,matrix( rep( (rU_test - rD_test)/(B-1), B-1) , ncol=Dtest,byrow=T))
  
  # Calculate the optimal load
  x_estim = optimal_load(price = data$price[Ztest],
                         a = a_test,
                         E = E_test)
  
  # Show elapsed time
  end_time = start_time - proc.time()
  message(paste("Elapsed: ", -round(end_time[3]*100)/100), " sec")
  
  # Save predicted and actual consumption
  test_C.actual[i,] =  data$load[Ztest]
  test_C.pred[i,] = colSums(x_estim)
  
  # SAVE INFO
  mae[i,] =abs(test_C.actual[i,]  - test_C.pred[i,] )
  rmse[i,] =  sqrt(  (test_C.actual[i,]  - test_C.pred[i,] )^2)
  mape[i,] = abs( (test_C.actual[i,]  - test_C.pred[i,]) / test_C.actual[i,])
  smape[i,] = abs(test_C.actual[i,]  - test_C.pred[i,]) / (abs(test_C.actual[i,]) + abs( test_C.pred[i,]))/2
  logratio[i,] = log(test_C.pred[i,] / test_C.actual[i,])
  test_Time[i,] = data$Time[Ztest]
  
  ## UPDATE PARAMETERS
  # Move the window 
  Ztrain = Ztrain+Update_horizon
  Ztest = Ztest+Update_horizon
  
  # SAVE RESULTS in each iteration, in case walltime is reached
  result = list( K = K, EXP = EXP,
                 mae = mae, rmse = rmse,  mape = mape,smape=smape, logratio = logratio,
                 C.pred = test_C.pred,
                 C.actual = test_C.actual,
                 Time = test_Time
  )
  
  save(result,file=paste(wpath,'CrossVal_all/Data_out/result_',pbs_iter,sep=""))
  
}





message('--------- Results saved. Delete folder ----------')
# CLose session
unlink(newDir,recursive=TRUE)
