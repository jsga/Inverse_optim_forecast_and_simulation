# Auxiliary functions to gdxrrw
#
# # Javier Saez
# 

################ 
# PLot two time series on the same plot
plotTwoY = function(y1,y2,xcomlabel="x",y1label="y1",y2label="y2",y1leg="y1",y2leg="y2",col=c("red","blue"),abV = 0,last=F){
  x = 1:length(y1)
  plot(x,y1,type="l",col=col[1],xlab=xcomlabel,ylab=y1label, xaxt = "n")
  par(new=T)
  plot(x, y2,type="l",col=col[2],xaxt="n",yaxt="n",xlab="",ylab="",lty=2)
  axis(4)
  mtext(y2label,side=4,line=3,cex=par("cex"))
  abline(v=abV,col=8,lty=3,lwd=1)
  legend("topleft",col=col,legend=c(y1leg,y2leg),lty=c(1,2),bg="white")
}


######################################
# Inverse problem with multiple exogenogenous variables
inverse_exact = function(price_input,x_meas_input,
                         Exo_input=Exo_input,
                         Exo_input_r=Exo_input_r,
                         B=NULL,w_input=1,K=0.5,
                         up_Exo,down_Exo,
                         gams_file = "",
                         folder_file = ""){
  # Write gdx file
  N = length(x_meas_input)
  Q = dim(Exo_input)[2]
  Qr = dim(Exo_input_r)[2]
  
  # Initialise sets for data structuring in GDX file
  Time = uelsGDX('t',N)
  Blocks = uelsGDX('b',B)
  Qexo =  uelsGDX('q',Q)
  Qexor =  uelsGDX('q',Qr)
  
  # write sets
  set.t<-inputGDX('t',matrix(1, 1, N), Time, type="set")
  set.b<-inputGDX('b',matrix(1, 1, B), Blocks, type="set")
  set.q<-inputGDX('q',matrix(1, 1, Q), Qexo, type="set")
  set.qr<-inputGDX('qr',matrix(1, 1, Qr), Qexor, type="set")
  
  
  # Input parameters
  K = inputGDX('K', K)
  x_meas = inputGDX('x_meas',x_meas_input,Time)
  price = inputGDX('price',price_input,Time)
  w = inputGDX('w',w_input,Time)
  up_Exo = inputGDX('up_Exo',up_Exo,Qexor)
  down_Exo = inputGDX('down_Exo',down_Exo,Qexor)
  Exo_input<-inputGDX2('exo',as.matrix(Exo_input),Time,Qexo)
  Exo_input_r<-inputGDX2('exo_r',as.matrix(Exo_input_r),Time,Qexor)
  
  
  # Make gdx file
  wgdx('Input.gdx',set.t,set.b,set.q,set.qr,price,x_meas,w,up_Exo,down_Exo,Exo_input,Exo_input_r,K) 
  
  # Run gams code
  system(paste(gams_file, ' ', folder_file,'InvForecast_2step.gms lo=3',sep=""))
  
  # Check the status
  status_sol_ramp = rgdx('Output',list(name=c("status_sol_ramp")))$val
  status_sol_refine = rgdx('Output',list(name=c("status_sol_refine")))$val
  if (status_sol_ramp ==1 & status_sol_refine == 1){
    message("Succesful optimization. Status_sol = 1")
  }else{
    message(paste("(!!!!) Something went wrong. status_sol_ramp=",status_sol_ramp, 'status_sol_refine=',status_sol_refine))
  }
  
  # Read solution
  return_list = list()
  return_list$B = B
  
  # Return main parameters
  return_list$rU_inv = ProcessRGDX('Output', 'Pmax',list(Time),c("Time"))$value
  return_list$rD_inv = ProcessRGDX('Output', 'Pmin',list(Time),c("Time"))$value
  return_list$util_inv = ProcessRGDX('Output', 'a',list(Blocks,Time),c("Blocks","Time"),"Blocks","Time")[,-1]
  return_list$Obj_ramp = ProcessRGDX_SingleValue('Output', 'Obj_ramp')
  return_list$Obj_util = ProcessRGDX_SingleValue('Output', 'Obj_util')
  return_list$gap= ProcessRGDX('Output', 'gap',list(Time),c("Time"))$value
  
  return_list$x_meas_s = ProcessRGDX('Output', 'x_meas_s',list(Blocks,Time),c("Blocks","Time"),"Blocks","Time")[,-1]
  return_list$Eb = ProcessRGDX('Output', 'E',list(Blocks,Time),c("Blocks","Time"),"Blocks","Time")[,-1]
  
  # Return coefficients
  return_list$coef$mu_u = ProcessRGDX_SingleValue('Output', 'mu_u_exo')
  return_list$coef$mu_d = ProcessRGDX_SingleValue('Output', 'mu_d_exo')
  return_list$coef$mu_a =  ProcessRGDX('Output', 'mu_a_exo',list(Blocks),c("Blocks"))$value
  return_list$coef$alpha_u = ProcessRGDX('Output', 'alpha_u_exo',list(Qexor),c("Qexor"))$value
  return_list$coef$alpha_d = ProcessRGDX('Output', 'alpha_d_exo',list(Qexor),c("Qexor"))$value
  return_list$coef$alpha_a = ProcessRGDX('Output', 'alpha_a_exo',list(Qexo),c("Qexo"))$value
  
  return(return_list)
  
}


########################################################
# Given estimate for the utility and ramps, and certain price, compute the optimal load

optimal_load = function(price,a,E){
  
  N = length(price) # Number of time slot
  
  # Get the dimensions
  B = dim(a)[1] # Number of blocks
  # Save the estimated load here
  x_estim = matrix(0,ncol=N,nrow=B)
  # Fill the blocks with higher util
  for(b in 1:B) {
    i_fill = which(a[b,] >= price) 
    x_estim[b,i_fill] = as.numeric(E[b,i_fill])
  }
  
  # Return
  return(x_estim)
}



######################################
# Heat pump simulator
# Input proided by the gen_pool_HP function

heat_pump_sim = function(price,Ta,S,pv,
                         a11,a12,a13,a21,a22,a23,a31,a32,a33,
                         b1,b2,b3,d1,d2,e1,e2,e3,
                         maxHP,minHP,rampUpHP,rampDownHP,minComfort,maxComfort,
                         gams_file = "",
                         folder_file = "", N){
  # Write data into a gdx file
  Time = uelsGDX('t',N)
  set.t<-inputGDX('t',matrix(1, 1, N), Time, type="set")
  
  price = inputGDX('price',price,Time)
  Ta = inputGDX('Ta',Ta,Time)
  S = inputGDX('S',S,Time)
  
  pv = inputGDX('pv',pv)
  a11 = inputGDX('a11',a11);  a12 = inputGDX('a12',a12);  a13 = inputGDX('a13',a13)
  a21 = inputGDX('a21',a21);  a22 = inputGDX('a22',a22);  a23 = inputGDX('a23',a23)
  a31 = inputGDX('a31',a31);  a32 = inputGDX('a32',a32);  a33 = inputGDX('a33',a33)
  b1 = inputGDX('b1',b1);  b2 = inputGDX('b2',b2);  b3 = inputGDX('b3',b3)
  d1 = inputGDX('d1',d1);  d2 = inputGDX('d2',d2)
  e1 = inputGDX('e1',e1);  e2 = inputGDX('e2',e2);  e3 = inputGDX('e3',e3)
  
  maxHP = inputGDX('maxHP',maxHP)
  minHP = inputGDX('minHP',minHP)
  rampUpHP = inputGDX('rampUpHP',rampUpHP)
  rampDownHP = inputGDX('rampDownHP',rampDownHP)
  
  minComfort = inputGDX('minComfort',minComfort,Time)
  maxComfort = inputGDX('maxComfort',maxComfort,Time)
  wgdx('InputHeatPump.gdx',set.t,price,Ta,S,minComfort,maxComfort,pv,maxHP,minHP,rampUpHP,rampDownHP,a11,a12,a13,a21,a22,a23,a31,a32,a33,b1,b2,b3,d1,d2,e1,e2,e3)
  
  # Execute .gms file
  system(paste(gams_file, ' ', folder_file,'HeatPump_House_Z.gms lo=2',sep=""))
  
  # Read output
  Wc = ProcessRGDX('Output', 'Wc',list(Time),c("Time"))$value
  Tr = ProcessRGDX('Output', 'Tr',list(Time),c("Time"))$value
  Tf = ProcessRGDX('Output', 'Tf',list(Time),c("Time"))$value
  Tw = ProcessRGDX('Output', 'Tw',list(Time),c("Time"))$value
  D = ProcessRGDX('Output', 'D',list(Time),c("Time"))$value
  status = ProcessRGDX_SingleValue('Output', 'status_sol')
  
  # Return
  data = list(time=1:N, Wc = Wc, Tr = Tr,Tf = Tf, Tw = Tw, D=D,status=status)
  return(data)
}