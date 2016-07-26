#
# Read cross validation files and make a plot
#

# Set working dir
wpath = '/home/CrossVal_all/'
setwd(wpath)


#---------- Movelog files and remove useless folders ----------#

## Move the log files to a separate folder
files = dir()
i_f = which(substr(files,1,6) == 'Adj_CV')
dir.create('Data_out/output_results')
file.copy(files[i_f], 'Data_out/output_results')
file.remove(files[i_f])
# Remove useless folders
files = dir()
i_f = which(substr(files,1,12) == 'working_dir_')
unlink(files[i_f])


#---------- Load datasets----------#


folder_result = 'Data_out/'
files_aux = dir(folder_result)
files = files_aux[grep('result_',files_aux)] # select the workspaces
# Order the files - obtain the last numbers
aux = unlist(strsplit(files,'.RData'))
nums= as.numeric(substr(aux,8,10))
ii = sort(nums,index.return=T)
files = files[ii$ix] # Ordered files
index_loop = as.numeric(substr(files,8,10)) # 8-10
#length(files)

upd_per = 1:1 # how oftern the parameters are re-estimated. equal to Update_horizon

result_all = list()
for(f in 1:length(index_loop)){
  
  load(paste(folder_result,'result_',index_loop[f],sep=""))
  if(f==1){
    result_all$K =  result$K
    result_all$EXP =  result$EXP
    result_all$mae = c(t(result$mae[,upd_per]))
    result_all$rmse = c(t(result$rmse[,upd_per]))
    result_all$mape = c(t(result$mape[,upd_per]))
    result_all$smape = c(t(result$smape[,upd_per]))
    result_all$C.pred= c(t(result[[7]][,upd_per]))
    result_all$C.actual= c(t(result[[8]][,upd_per]))
    
    }else{
    result_all$K = c(result_all$K, result$K)
    result_all$EXP = c(result_all$EXP, result$EXP)
    result_all$mae = cbind(result_all$mae,c(t(result$mae[,upd_per])))
    result_all$rmse = cbind(result_all$rmse,c(t(result$rmse[,upd_per])))
    result_all$mape = cbind(result_all$mape,c(t(result$mape[,upd_per])))
    result_all$smape = cbind(result_all$smape,c(t(result$smape[,upd_per])))
    result_all$C.pred= cbind(result_all$C.pred,c(t(result[[8]][,upd_per])))
    result_all$C.actual= cbind(result_all$C.actual,c(t(result[[9]][,upd_per])))
  }
}
str(result_all)

# Collect summary statistic
myfun = function(x) return(apply(x,2,mean,na.rm=T))

str(result_all)
ll = result_all[c(3:6)]
str(ll)
mean_stat = lapply(ll,myfun) # Calculate the mean of the statistic along the days (ie, one per L)


# Collect dataset
df = data.frame(K = result_all$K,
                EXP = result_all$EXP,
                smape = mean_stat$smape,
                rmse = mean_stat$rmse,
                mae = mean_stat$mae,
                mape = mean_stat$mape)


#---------- Make a plot of the RMSE ----------#


par(mar = c(4,4.1,1.1,2.1),mfrow=c(1,1))
plot(df$K, df$rmse,type="l", xlab="K",ylab="RMSE")
grid()

df$K[which.min(df$smape)]
df$K[which.min(df$rmse)]
