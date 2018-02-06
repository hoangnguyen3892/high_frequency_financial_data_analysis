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
where sym_root in ('ZION')
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



data trade;
set trade;
by sym_root;
ret = log(price/lag(price));
dret= dif(ret);
if first.sym_root then do;
ret=.;
dret=.;
end;
run;

/*Estimate the model*/
proc arima data=trade;
by sym_root;
identify var=ret;
estimate p=5 q=5 method=ml; *maximum likelihood;
run;quit;


proc arima data=trade;
by sym_root;
identify var=dret;
estimate p=4 q=5 method=ml; *maximum likelihood;
run;quit;

