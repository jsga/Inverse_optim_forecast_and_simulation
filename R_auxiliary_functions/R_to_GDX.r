#############################
# Define the set indices: i is the desired index letter, N is the extent of the set
uelsGDX = function(i,N){
  ret = paste(i,1:N,sep='')
  return(ret)
}

#############################
### Input Function for one dimensional (1-D) data
### Provide: name_input (parameter name, string)
#            val (parameter value, array)
#            uels (set indices, variable,  as previously defined using uelsGDX)
#            dim (data dimension, integer, can be set to zero for single value input)
#            type (GDX data type, can be set to "set" when desired, default is "parameter")

inputGDX = function(name_input,val,uels=NULL,dim=1,type='parameter',form='full',ts=''){
  
  output = list()
  output$name=name_input

  output$type=type
  output$form=form  
  
  if(!is.null(uels)){
    output$uels[[1]] = uels
  }
  
  output$dim = dim
  
  if(length(val) == 1){ # Single parameter
    output$dim = 0
    output$val = val
  }else{ # Array with dimenstion 1
    output$dim = 1#dim(array(val))
    output$val = array(val)
  }
  


  return(output)
}


#############################
### Input Function for 2-D data
### Provide: name_input (parameter name, string)
#            val (parameter value, array)
#            uels1 (set indices for first dimension, variable,  as previously defined using uelsGDX)
#            uels2 (set indices for second dimension, variable,  as previously defined using uelsGDX)
inputGDX2 = function(name_input,val,uels1=NULL,uels2=NULL,dim=2,type='parameter',form='full',ts=''){
  
  output = list()
  output$name=name_input
  
  output$type=type
  output$form=form  
  
  if(!is.null(uels1)){
    output$uels = list(uels1,uels2)
  }
  
  output$dim <- dim

  output$val <- val

  return(output)
}

#############################
### Input Function for 3-D data
### Provide: name_input (parameter name, string)
#            val (parameter value, array)
#            uels1 (set indices for first dimension, variable,  as previously defined using uelsGDX)
#            uels2 (set indices for second dimension, variable,  as previously defined using uelsGDX)
#            uels3 (set indices for third dimension, variable,  as previously defined using uelsGDX)
inputGDX3 = function(name_input,val,uels1=NULL,uels2=NULL,uels3=NULL,dim=3,type='parameter',form='full',ts=''){
  
  output = list()
  output$name=name_input
  
  output$type=type
  output$form=form  
  
  if(!is.null(uels1)){
    output$uels = list(uels1,uels2,uels3)
  }
  
  output$dim <- dim
  output$val<- val
  
  return(output)
}

#############################
### Input Function for 4-D data
### Provide: name_input (parameter name, string)
#            val (parameter value, array)
#            uels1 (set indices for first dimension, variable,  as previously defined using uelsGDX)
#            uels2 (set indices for second dimension, variable,  as previously defined using uelsGDX)
#            uels3 (set indices for third dimension, variable,  as previously defined using uelsGDX)
#            uels4 (set indices for fourth dimension, variable,  as previously defined using uelsGDX)

inputGDX4 = function(name_input,val,uels1=NULL,uels2=NULL,uels3=NULL,uels4=NULL,dim=4,type='parameter',form='full',ts=''){
  
  output = list()
  output$name=name_input
  
  output$type=type
  output$form=form  
  
  if(!is.null(uels1)){
    output$uels = list(uels1,uels2,uels3,uels4)
  }
  
  output$dim <- dim
  output$val<- val
  
  return(output)
}


###############################
# Process the output GDX file from executed gams script.
# Provide: GDXName (Name of output GDX file, string excluding extension)
#          VarName (Name of the variable you wish to read, string)
#          VarSets (list of the indices of the data you wish to read - indices are previously initiated using uelsGDX )
#          VarSetNames (concatenation of strings e.g. c("a","b","c") indicating the header titles on the resulting dataframe)
#          ReShapeX (if you wish to reshape the data, indicate the indices that should run along the vertical axis)
#          ReShapeY (if you wish to reshape the data, indicate the indices that should run along the horizontal axis, ie. data headers (optional))
ProcessRGDX <-function(GDXName, VarName, VarSets=NULL, VarSetNames=NULL, ReShapeX=NULL, ReShapeY=NULL){

  a <- rgdx(GDXName, list(name = VarName, form="full", uels=VarSets),squeeze=FALSE)$val 
  a <- melt(a)
  i <- sapply(a, is.factor)
  a[,i] <- lapply(a[i], as.character)
  colnames(a)[1:length(VarSetNames)]<-VarSetNames
  
  
  for(j in 1:length(VarSetNames)){
    a[,j]<-substring(a[,j],2)
    a[,j]<-as.numeric(a[,j])
  }
  
  if(!is.null(ReShapeX) && !is.null(ReShapeY)){
  b<-dcast(a,as.formula(paste0(ReShapeX,"~",ReShapeY)))
  b[is.na(b)]<-0
  }else if(!is.null(ReShapeX) && is.null(ReShapeY)) {
  b<-dcast(a,as.formula(paste0("...~",ReShapeX)))
  b[is.na(b)]<-0 
  } else{b<-a}
  return(b)
}

##### Process the output for a single value 
# Provide: GDXName (Name of output GDX file, string excluding extension)
#          VarName (Name of the variable you wish to read, string)
ProcessRGDX_SingleValue<-function(GDXName, VarName){
  a<-rgdx(GDXName, list(name=VarName))$val
  # bug: if a is empty then equal to zero
  return(ifelse(length(a)==0,0,a))
}
