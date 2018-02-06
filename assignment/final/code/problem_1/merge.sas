/*This function is used to merge all file*/
libname whr 'C:\Users\Hoang\Dropbox\Final\data';


data estim;
set whr.estim_:;
run;
