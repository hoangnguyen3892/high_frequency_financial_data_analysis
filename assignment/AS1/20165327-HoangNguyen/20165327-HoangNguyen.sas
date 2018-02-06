/**********data0***********/
/**************************/
data data0;
input date date9.;
format date date9.;
datelines;
16MAR2005
;

proc print data=data0;
	title 'data0 with date9. format';
run;

/**********data1***********/
/**************************/
data data1;
input date date9.;
format date mmddyys8.;
datelines;
16MAR2005
;
proc print data=data1;
	title 'data1 with mmddyys8. format';
run;

/**********data2***********/
/**************************/
data data2;
input date date9.;
format date mmddyyd8.;
datelines;
16MAR2005
;
proc print data=data2;
	title 'data2 with mmddyyd8. format';
run;

/**********data3***********/
/**************************/
data data3;
input date date9.;
format date mmddyyd10.;
datelines;
16MAR2005
;
proc print data=data3;
	title 'data3 with mmddyyd10. format';
run;
/**********data4***********/
/**************************/
data data4;
input date date9.;
format date yymmddn8.;
datelines;
16MAR2005
;
proc print data=data4;
	title 'data4 with yymmddn8. format';
run;

/**********data5***********/
/**************************/
data data5;
input date date9.;
format date date11.;
datelines;
16MAR2005
;
proc print data=data5;
	title 'data5 with date11. format';
run;

/**********data6***********/
/**************************/
data data6;
input date date9.;
format date date7.;
datelines;
16MAR2005
;
proc print data=data6;
	title 'data6 with date7. format';
run;

/**************************/
data datepractice;
set data0 - data6;
run;

proc print data=datepractice;
	title 'Check SET statement';
run;



