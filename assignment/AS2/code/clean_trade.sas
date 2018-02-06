/*Global setting*/
libname project 'C:\Users\Hoang\Downloads\Hail';


data ct;
set project.ct;
where (('9:30:00.000000't) <= time_m <= ('16:00:00.000000't)); 
type='T';
drop tr_corr tr_source tr_rf part_time
rnn trf_time sym_suffix tr_scond tr_stopind;
run;

proc export data=ct
outfile='C:\Users\Hoang\Downloads\Hail\trade2.xlsx' 
dbms=xlsx replace;
sheet='trade';
run;
