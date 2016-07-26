lagmatrix <- function(data,lag.max=0,prenames=colnames(data)){
##browser()
  ## the length of lag.max should be checked. It needs to be either one or the number of columns in data.
  if(class(data)=="numeric")
    data <- matrix(data,ncol=1)
  
  dim.data <- dim(data)

    if(length(lag.max)==1){
      if(!is.null(names(data))){
        if("Time"==names(data)[1]){
          ##      timeidx <- which(names(data)=="Time")
          lag.max <- c(0,rep(lag.max,dim.data[2]-1))
        } else {
          lag.max <- c(rep(lag.max,dim.data[2]))
        }
      } else {
        lag.max <- c(rep(lag.max,dim.data[2]))
      }
    }
       
  
  max.lag.max <- max(lag.max)
  dim.newdata <- c(dim.data[1]-max.lag.max,sum(lag.max+1))
  newdata <- data.frame(idx=1:dim.newdata[1])
  lagidx <- array(dim=c(dim.newdata[1],max.lag.max+1))
  for(lag in 0:(max.lag.max)){
    col <- lag+1
    lagidx[,col] <- (max.lag.max+1-lag):(dim.data[1]-lag)
  }
if(is.null(prenames)){
  prenames <- paste("x",1:dim.data[2],sep=".")
}
  for (s in 1:length(prenames)){
    for(lag in 0:lag.max[s]){
      col <- lag+1
      newdata[,paste(prenames[s],".l",lag,sep="")] <- data[lagidx[,col],s]
    }
  }
  newdata <- newdata[,-c(1)]
  return(newdata)
}
