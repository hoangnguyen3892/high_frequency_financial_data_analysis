libname estim 'C:\Users\Hoang\Dropbox\Final\data';

%let ticker_name = QCOM;

data &ticker_name;
set estim.estim_&ticker_name;
run;

ods html body='ttest.htm' style=HTMLBlue;
proc corr data=&ticker_name;
   var  sigma_d A_d s_d es_d res_d lambda1_d lambda2_d 
		psi1_d psi2_d rho_d gamma_d;
run;
ods html close;
