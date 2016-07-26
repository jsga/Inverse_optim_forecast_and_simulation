SETS
    t Time
    b Number of blocks
    q Exogenous variables
    qr Exogenous variables for ramp estimation
;

*------------------------------------------------
*------------ RAMP ESTIMATION PROBLEM -----------
*------------------------------------------------

PARAMETER
    price 			Price of electricity
    status_sol_ramp	Return the status of the problem
    w    			  Weights
    x_meas      Consumption observed
    exo(t,q)		External information
    up_Exo(qr)		Upper bound of the external factor q
    down_Exo(qr)	Lower bound of the external factor q
	  exo(t,q) 		External factors
    exo_r(t,qr)    External factors ramp estimation
	  K			     	Weight factor between out and inside interval
;


$gdxin Input
$load   t,b,q,qr,price,x_meas,w,up_Exo,down_Exo,exo,exo_r,K
$gdxin


VARIABLES
    Obj_ramp     	Objective function
    alpha_u_exo(qr)	Coefficient for the ramp up and external variable q
    alpha_d_exo(qr)	Coefficient for the ramp down and external variable q
    mu_u_exo		Mean for the ramp up and external variable q
    mu_d_exo		Mean for the ramp down and external variable q
;

POSITIVE VARIABLES
    x(b,t)       		Estimated consumption at each block
    x_alpha_u(t)    	Positive side of the absolute value ramp up
    x_beta_u(t)     	Negative side of the absolute value ramp up
    x_alpha_d(t)    	Positive side of the absolute value ramp down
    x_beta_d(t)     	Negative side of the absolute value ramp down
    psi_ramp_1_exo(qr)	Dual variable of the robust constraint Pmax
    psi_ramp_2_exo(qr)	Dual variable of the robust constraint Pmin
;

EQUATIONS
    Obj_eq_ramp         Objective function ramp problem
    absolute_u(t)  			Used to deifne the absolute value linearly ramp up
    absolute_d(t)  			Used to deifne the absolute value linearly ramp down
    robust_eq_ramp_1		Robust constraint 1
    robust_eq_ramp_exo(qr)	Robust constraint 1
    ;


** OBJECTIVE FUNCTION
*    Obj_eq_ramp.. Obj_ramp =e=  sum(t,w(t)*( K*(x_alpha_u(t)*x_alpha_u(t)+  x_beta_d(t)*x_beta_d(t) ) + (1-K)*(x_beta_u(t)*x_beta_u(t) + x_alpha_d(t)*x_alpha_d(t)) ));
    Obj_eq_ramp.. Obj_ramp =e=  sum(t,w(t)*( K*(x_alpha_u(t)+  x_beta_d(t) ) + (1-K)*(x_beta_u(t) + x_alpha_d(t)) ));

** CONSTRAINTS
** Absolute value constraints
    absolute_u(t)..    x_meas(t) - mu_u_exo - sum(qr, alpha_u_exo(qr)*exo_r(t,qr))  =e= x_alpha_u(t) - x_beta_u(t) ;
    absolute_d(t)..   x_meas(t) - mu_d_exo - sum(qr, alpha_d_exo(qr)*exo_r(t,qr))  =e= x_alpha_d(t) - x_beta_d(t) ;

** Robustness of ramp limits
    robust_eq_ramp_1..    	- mu_u_exo  + mu_d_exo + sum(qr, psi_ramp_1_exo(qr)*up_exo(qr) - psi_ramp_2_exo(qr)*down_exo(qr)) =l= -0.01;
    robust_eq_ramp_exo(qr).. psi_ramp_1_exo(qr) - psi_ramp_2_exo(qr) =e= - alpha_u_exo(qr) +  alpha_d_exo(qr);


MODEL RAMP /Obj_eq_ramp,absolute_u,absolute_d,robust_eq_ramp_1,robust_eq_ramp_exo/;

* Solve this problem and split the meas load depending on the ramps
SOLVE RAMP USING lp minimizing Obj_ramp;
status_sol_ramp = RAMP.modelstat;


** COMPUTE PARAMS
PARAMETER
  Pmax(t)  			Estimated ramp up limit
  Pmin(t)  			Estimated ramp down limit
;
loop(t,
	Pmax(t) = mu_u_exo.l + sum(qr, alpha_u_exo.l(qr)*exo_r(t,qr));
	Pmin(t) =  mu_d_exo.l + sum(qr, alpha_d_exo.l(qr)*exo_r(t,qr));
);

** Split the load
PARAMETER
x_meas_s(b,t) 	Split measured load
E(b,t)			Width of each block
;

* Define the block width. The first block is the same as the Pmin, then they are equally distributed
loop(t,
  E('b1',t) = Pmin(t);
  loop(b$(ord(b) > 1),
    E(b,t) = (Pmax(t) - Pmin(t))/(card(b)-1)
  );
);

* Alias of the block needed for the loop
alias(b,b1);

* For every time t
loop(t,
  if(x_meas(t) ge Pmax(t),
* We fill up all the blocks, end.
    loop(b, x_meas_s(b,t) = E(b,t); );
  else
    if(x_meas(t) le Pmin(t),
* We fill up the first block up to the min (!!!!) Pmin(t);
       x_meas_s('b1',t) = Pmin(t);
* Here x_meas is somewhere in between, hence we just fill a few. The first one msut be fully filled.
    else
      x_meas_s('b1',t) = E('b1',t);
      loop(b$(ord(b) ge 2),
* Find the block where x_meas stands
        if(  (sum(b1$(ord(b1) < ord(b)), E(b1,t)) < x_meas(t)) and  (x_meas(t) le sum(b1$(ord(b1) le ord(b)), E(b1,t))),
         loop(b1$(ord(b1) < ord(b)),
* Fill the blocks up to b-1
         x_meas_s(b1,t) = E(b1,t);
         );
* Partially fill the block b
         x_meas_s(b,t) = x_meas(t) - sum(b1$(ord(b1) < ord(b)), E(b1,t));
        );
      );
    );
  );
);

$ontext OLD TRANSFORMATION
loop(t,
    E(t) = (Pmax(t) - Pmin(t))/card(b)
);
* For every time t
loop(t,
  if(x_meas(t) ge Pmax(t),
* We fill up all the blocks, end.
    loop(b, x_meas_s(b,t) = E(t) ; );
  else
* All block are zero
    if(x_meas(t) le Pmin(t),
      loop(b,x_meas_s(b,t) =0; 
        );
* Here x_meas is somewhere in between, hence we just fill a few.
    else
      loop(b$(ord(b) ge 1),
* Find the block where x_meas stands
        if(  (Pmin(t)+sum(b1$(ord(b1) < ord(b)), E(t)) < x_meas(t)) and  (x_meas(t) le (Pmin(t)+sum(b1$(ord(b1) le ord(b)), E(t)))),
         loop(b1$(ord(b1) < ord(b)),
* Fill the blocks up to b-1
         x_meas_s(b1,t) = E(t);
         );
* Partially fill the block b
         x_meas_s(b,t) = x_meas(t) - (Pmin(t)+ sum(b1$(ord(b1) < ord(b)), E(t)));
        );
      );
    );
  );
);
$offtext



* Check that the split load is correct
file out;
put out;
PARAMETER aux;
loop(t,
aux = sum(b,x_meas_s(b,t));
if(sum(b,x_meas_s(b,t))  <> x_meas(t),
put 'Time', ord(t)/;
 put 'x_meas_s=', aux ,' x_meas= ',x_meas(t) /;
);
);
* Of course, it does not have to be the same, it depends on the K we choose.




*------------------------------------------------
*------------ UTIL ESTIMATION PROBLEM -----------
*------------------------------------------------

PARAMETERS
	status_sol_refine	Status of the problem
;

EQUATIONS
  Obj_eq_util         Objective function ramp problem
  util_convexity(b)	Ensure decreasing utility
	stat_cond(b,t)		stationary condition
	strong_dual_cond(t) Strong Duality Condition
  first_block
;

VARIABLES
	Obj_util		Objective function for the util constraint
  alpha_a_exo(q)	Coefficient for the utility and external variable q
  mu_a_exo(b)		Mean for the utility and external variable q
;

POSITIVE VARIABLES
	gap(t)			Duality gap
	psi_up(t)		Dual variable total power up
	psi_do(t)		Dual variable total power down
  phi_up(b,t) Dual variable for each block max
  phi_do(b,t) Dual variable for each block positive
;



** OBJECTIVE FUNCTION
    Obj_eq_util.. Obj_util =e=  sum(t,w(t)*gap(t));

** CONSTRAINTS
  util_convexity(b)$(ord(b) ge 2).. mu_a_exo(b-1) =g= mu_a_exo(b);
  first_block.. mu_a_exo('b1') =g= 500 + mu_a_exo('b2');

	strong_dual_cond(t)..	sum(b, x_meas_s(b,t)*(mu_a_exo(b) + sum(q, alpha_a_exo(q)*exo(t,q)) - price(t))) + gap(t) =e=   - Pmin(t)*psi_do(t) + Pmax(t)*psi_up(t) + sum(b, E(b,t)*phi_up(b,t));

	stat_cond(b,t).. -phi_do(b,t) + phi_up(b,t) -psi_do(t) + psi_up(t) =e= mu_a_exo(b) + sum(q, alpha_a_exo(q)*exo(t,q)) - price(t);


MODEL REFINE /Obj_eq_util,util_convexity,strong_dual_cond,stat_cond,first_block/;

* Solve this problem and split the meas load depending on the ramps
SOLVE REFINE USING lp minimizing Obj_util;
status_sol_refine = REFINE.modelstat;


* Calculate the estimated utility
PARAMETER
    a(b,t)  			Estimated ramp up limit
;
loop(t,
	a(b,t) = mu_a_exo.l(b) + sum(q, alpha_a_exo.l(q)*exo(t,q));
);
*loop(t, a('b1',t) = 200;);

** DISPLAY
display x_meas, x_meas_s,E,Pmax,Pmin,alpha_u_exo.l,alpha_d_exo.l,mu_u_exo.l,mu_d_exo.l;
display psi_up.l, psi_do.l;



** EXPORT DATA
execute_unload 'Output',Obj_ramp, Obj_util, status_sol_ramp,status_sol_refine,Pmax,Pmin,a,gap,mu_u_exo,mu_d_exo,alpha_u_exo,alpha_d_exo,mu_a_exo,alpha_a_exo,x_meas_s,E;
