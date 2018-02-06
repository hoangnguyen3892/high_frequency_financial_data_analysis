/*
This function create a dataset with timeline. However, the time is recorded in number*/
data one;
input date1 mmddyy10.;
datalines;
4-7-2016
12-4-2015
1-31-2013
;
run;

proc print data=one;
run;

/**************/
proc print data=one;
format data1 date9.;
run;
/**************/
proc contents data=one;
run;

/**************/
data one;
input date1 mmddyy10.;
format date1 date9.;
datalines;
4-7-2016
12-4-2015
1-31-2013
;
run;
/*the proc contents helps to check the data format*/
proc print data=one;
run;
proc contents data=one;
run;
