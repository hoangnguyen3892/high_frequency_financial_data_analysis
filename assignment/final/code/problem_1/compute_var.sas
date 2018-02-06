libname local 'C:\Users\Hoang\Dropbox\Final\data';

data BuySellIndicators;
set local.BuySellIndicators;
run;

data mediate1;
set BuySellIndicators;
DV = size*price; *problem b;
y = BuySellLR*size - lag(BuySellLR)*lag(size); *problem b;
z = BuySellLR*size*price - lag(BuySellLR)*lag(size)*lag(price); *problem b;
r = log(price) - log(lag(price)); *problem c;
delta_pt = price-lag(price); *problem d;
delta_pt1 = lag(price)-lag2(price); *problem d;
A = abs(r)/(price*size); *problem e;
wes_Dollar = (abs(price-midpoint))*2; *problem f;
wes_Dollar_SW = wes_Dollar*size; *problem f;
wres_Dollar_SW = wes_Dollar_SW/midpoint; *problem f;
res = es/midpoint; *problem f;
lag_y = lag(y); *problem g;
lag_z = lag(z); *problem g;
run;

/*problem a*/
data mediate2 (keep=date sym_root p_d m_d);
set BuySellIndicators;
by sym_root;
if last.sym_root;
rename price = p_d; *problem a;
rename midpoint = m_d; *problem a;
run;

/*problem b, c, e*/
proc means noprint data=mediate1 mean std;
var size DV y z A;
output out= mediate3
mean(size) = V_d
mean(DV) = DV_d
mean(y) = y_d
mean(z)= z_d
std(r) = sigma_d
mean(A) = A_d
;
run; 

/*problem d*/
proc corr noprint data=mediate1 outp=mediate4 cov; *or outs;
var delta_pt delta_pt1;
run;

data mediate4(keep=s_d);
set mediate4;
where _NAME_ in ('delta_pt1') and _TYPE_ in ('COV');
s_d = sqrt(-delta_pt)/2;
run;

/*problem f*/
proc sql;
create table effectivespread
as select
sum(size) as sumsize,
sum(wes_Dollar_SW) as waes_Dollar_SW,
sum(wres_Dollar_SW) as wares_Dollar_SW
from mediate1;
quit;

data mediate5 (keep= es_d res_d);
set effectivespread;
es_d = waes_Dollar_SW/sumsize;
res_d = wares_Dollar_SW/sumsize;
run;

/*problem g*/
proc reg noprint data=mediate1 outest=mediate6;
model r = y lag_y;
run;
data mediate6 (keep=lambda1_d psi1_d);
set mediate6;
rename y = lambda1_d;
rename lag_y = psi1_d;
run;

proc reg noprint data=mediate1 outest=mediate7;
model r = z lag_z;
run;
data mediate7 (keep=lambda2_d psi2_d);
set mediate7;
rename z = lambda2_d;
rename lag_z = psi2_d;
run;

/*problem h*/
proc arima data=mediate1;
identify var=BuySellLR noprint;
estimate p=1 q=1 method=ml outest=mediate8 noprint; 
run;quit;

data mediate8 (keep=rho_d gamma_d);
set mediate8;
where _TYPE_ in ('EST');
rename AR1_1 = rho_d;
rename MA1_1 = gamma_d;
run;


data estim (keep=date sym_root p_d m_d V_d DV_d y_d z_d sigma_d A_d s_d 
			es_d res_d lambda1_d psi1_d lambda2_d psi2_d rho_d gamma_d);
set mediate2;
set mediate3;
set mediate4;
set mediate5;
set mediate6;
set mediate7;
set mediate8;
run;
