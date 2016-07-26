### Prepare data for cross validation



K_all = seq(0.4,0.99,0.025)
E_all = c(0) # OLD, do not use

inputNum = 1
for(j in 1:length(K_all)){
  K = K_all[j]
  
  for(k in 1:length(E_all)){
    EXP = E_all[k]
    
    # Save
    list_input = list(K = K,
                      EXP = EXP)
    save(list_input,
         file=paste('/home/jsga/inverse_opt/CrossVal_all/Init_data/input_',inputNum,sep=""))
    inputNum = inputNum+1
  }
}



