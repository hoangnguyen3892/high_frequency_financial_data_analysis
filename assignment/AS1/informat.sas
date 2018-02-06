/*INPUTN and INPUTC functions*/
/*****************************/
data fixdates(drop=start readdate);
	length jobdesc $12 readdate $8;
	input source id lname $ jobdesc $ start$;
	if source=1 then readdate='date7.';
	else readdate='mmddyy8.';
	newdate=inputn(start, readdate);
datalines;
1 1604 Zinmin writer 09aug90
2 1010 hoang editor 26jan95
3 9293 min writer 10/25/92
;
proc print data=fixdates;
run;

/*ATTRIB and INFORMAT statements*/
/********************************/

