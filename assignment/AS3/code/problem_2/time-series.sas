libname as3 'C:\Users\Hoang\Dropbox\AS3\data';

/*Time series for Trade data*/
/*
'BRCM'
'FMC'
'MRO'
'MUR'
'NDAQ'
'PDCO'
'TXN'
'UTX'
'WYNN'
'ZION'
*/

data trade;
set as3.trade2;
where sym_root in ('UTX')
and (('9:30:00.00000't) <= time_m <= ('16:00:00.00000't))
and price > 0;
*and Tr_Corr = '00' this condition is already satisfied; 
format date date9.;
format time_m time20.6;
keep sym_root date time_m price size;
run;

proc sort data=trade;
by sym_root date time_m;
run;

*proc print data=trade(obs=20);
*run;

data trade;
set trade;
by sym_root;
ret = log(price/lag(price));
oi = log(size/lag(size));
if first.sym_root then do;
ret=.;
oi=.;
end;
run;

/*Estimate p and q*/
/*ARIMA identification*/
proc arima data=trade;
by sym_root;
identify var=ret;
run;
quit;

/*SCAN: Smallest Canonical Correlation*/
proc arima data=trade;
by sym_root;
identify var=ret scan minic; *option scan mimic;
run;
quit;

/*ESACF: Extended Sample ACF*/
proc arima data=trade;
by sym_root;
identify var=ret esacf minic; *option scan;
run;
quit;


/*Estimate the model*/
/*
proc arima data=trade;
by sym_root;
identify var=ret;
estimate p=0 q=3 method=ml; *maximum likelihood;
run;quit;
*/
