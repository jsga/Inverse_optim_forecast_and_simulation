SETS
t time
  ;


PARAMETER
* Relative to the objective function
price(t)  Price of electricity
pv        Penalty

* Relative to the state-space model of the building
a11
a12
a13
a21
a22
a23
a31
a32
a33
b1
b2
b3
d1
d2
e1
e2
e3
S(t)  Solar radiation
Ta(t) Ambient temperature

* Relative to the control of the MPC
maxHP       Maximum consumption
minHP       Mininum consumption
rampUpHP    Ramp up limit of the heat pump
rampDownHP  Ramp down limit of the heat pump
minComfort(t)  Minimum comfort temperature
maxComfort(t)  Maximum comfort temperature

* Auxiliary
status_sol  return the status of the solver
;



*Import Data from gdx file, created with MatLab
$gdxin InputHeatPump
$load pv,maxHP,minHP,rampUpHP,rampDownHP,a11,a12,a13,a21,a22,a23,a31,a32,a33,b1,b2,b3,d1,d2,e1,e2,e3,t,price,S,Ta,minComfort,maxComfort
$gdxin


display price,pv,maxHP,minHP,rampUpHP,rampDownHP,a11,a12,a13,a21,a22,a23,a31,a32,a33,b1,b2,b3,d1,d2,e1,e2,e3;

VARIABLES
Obj     Objective function
Tr    Room air temperature
Tf    Floor temperature
Tw    Water temperature in floor heating pipes
Wc    Heat pump compressor input power
;

POSITIVE VARIABLES
D     Discomfort variable
;

EQUATIONS
Obj_eq      Objective function

state_eq1(t)   State space equation 1
state_eq2(t)   State space equation 2
state_eq3(t)   State space equation 3

maxHP_eq(t) Maximum consumption
minHP_eq(t) Mininum consumption

rampUpHP_eq(t) Ramp up limit of the heat pump
rampDownHP_eq(t) Ramp down limit of the heat pump

minComfort_eq(t) Minimum comfort temperature
maxComfort_eq(t) Maximum comfort temperature

;


** OBJECTIVE FUNCTION
Obj_eq.. Obj =e= sum(t, (1/1000)*price(t)*Wc(t) + pv*D(t));

** CONSTRAINTS

* State-space
state_eq1(t)$(ord(t) ge 2).. Tr(t) =e= a11*Tr(t-1) +  a12*Tf(t-1) + a13*Tw(t-1) + b1*Wc(t-1) + d1*S(t-1) + e1*Ta(t-1);
state_eq2(t)$(ord(t) ge 2).. Tf(t) =e= a21*Tr(t-1) +  a22*Tf(t-1) + a23*Tw(t-1) + b2*Wc(t-1) + d2*S(t-1)+ e2*Ta(t-1);
state_eq3(t)$(ord(t) ge 2).. Tw(t) =e= a31*Tr(t-1) +  a32*Tf(t-1) + a33*Tw(t-1) + b3*Wc(t-1) + e3*Ta(t-1);


* MPC constraints
maxHP_eq(t).. Wc(t) =l= maxHP;
minHP_eq(t).. minHP =l= Wc(t);

rampUpHP_eq(t)$(ord(t) ge 2)..    Wc(t) - Wc(t-1) =l= rampUpHP ;
rampDownHP_eq(t)$(ord(t) ge 2)..  rampDownHP =l= Wc(t) - Wc(t-1) ;

minComfort_eq(t).. minComfort(t)  =l= Tr(t)  + D(t) ;
maxComfort_eq(t).. Tr(t) - D(t)  =l= maxComfort(t);

* Starting temperatures
Tr.fx('t1') = 20;
Tw.fx('t1') = 60;
Tf.fx('t1') = 20;


MODEL HeatPump /ALL/;
SOLVE HeatPump USING LP minimizing Obj;
status_sol = HeatPump.modelstat;

display Obj.l,D.l;
execute_unload 'Output',Obj.l,Wc.l,Tr.l,Tf.l,Tw.l,D.l,status_sol;
