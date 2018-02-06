/*Global setting*/
libname as3 'C:\Users\Hoang\Dropbox\AS3\data';

data trade2;
set as3.ct;
where (('9:30:00.000000't) <= time_m <= ('16:00:00.000000't)) and
Tr_corr eq '00' and price gt 0; 
type='T';
drop tr_corr tr_source tr_rf part_time
rnn trf_time sym_suffix tr_scond tr_stopind;
run;

/*Save data*/
proc print data=trade2(obs=20);
run;

*proc contents data=quoteab;
*run;

data as3.trade2;
set trade2;
run;

/*
proc export data=ct
outfile='C:\Users\Hoang\Downloads\Hail\trade2.xlsx' 
dbms=xlsx replace;
sheet='trade';
run;
*/
