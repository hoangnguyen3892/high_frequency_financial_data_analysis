/*********Download stock***********/
libname as3 'C:\Users\Hoang\Dropbox\AS3\data';

/*Connect to WRDS*/

%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=hnguyen1 password='{SAS002}5B3C701F054358A017576B7E40CAC6AC28E24133214780B55B10E1C943B596FE';

/*Submit sas statements to WRDS*/
rsubmit;
	libname nbbo '/wrds/nyse/sasdata/taqms/nbbo';
	libname cq '/wrds/nyse/sasdata/taqms/cq';
	libname ct '/wrds/nyse/sasdata/taqms/ct';
	libname mast '/wrds/nyse/sasdata/taqms/mast';
	option msglevel=i mprint source;


/*Get the full cusip number*/
data temp;
set mast.mastm_20150826();
where substr(left(cusip), 1, 8) in ('62671710', '56584910', '88250810', '91301710', '30249130',
									'70339510', '63110310', '98970110', '98313410', '11132010');
keep symbol_root symbol_suffix cusip;
run;

*proc print data=temp;
*run;

/*Create data*/
proc sql;
create table nbbo as
select a.*
from nbbo.nbbom_20150826 as a, temp as b
where (a.sym_root = b.symbol_root) and (a.sym_suffix = b.symbol_suffix);
quit;

proc sql;
create table cq as
select a.*
from cq.cqm_20150826 as a, temp as b
where (a.sym_root = b.symbol_root) and (a.sym_suffix = b.symbol_suffix);
quit;

proc sql;
create table ct as
select a.*
from ct.ctm_20150826 as a, temp as b
where (a.sym_root = b.symbol_root) and (a.sym_suffix = b.symbol_suffix);
quit;

/*Download data*/
proc download data=temp out=as3.stock;
run;

proc download data=nbbo out=as3.nbbo;
run;

proc download data=cq out=as3.cq;
run;

proc download data=ct out=as3.ct;
run;

proc export data=as3.stock
outfile='C:\Users\Hoang\Dropbox\AS3\data\problem_1.xlsx' 
dbms=xlsx;
sheet='stock';
run;

endrsubmit;

/*No need to export data to excel*/
/*********Export to excel***********/
/*
data ct;
set as3.ct;
where (('9:00:00.00000't) <= time_m <= ('16:00:00.00000't)); 
format date date9.;
format time_m time20.6;
run;

data cq;
set as3.cq;
where (('9:00:00.00000't) <= time_m <= ('16:00:00.00000't)); 
format date date9.;
format time_m time20.6;
run;

data nbbo;
set as3.nbbo;
where (('9:00:00.00000't) <= time_m <= ('16:00:00.00000't)); 
format date date9.;
format time_m time20.6;
run;


proc export data=ct 
outfile='C:\Users\Hoang\Dropbox\AS3\trade.xlsx' 
dbms=xlsx;
sheet='trade';

proc export data=cq 
outfile='C:\Users\Hoang\Dropbox\AS3\quote.xlsx' 
dbms=xlsx;
sheet='quote';

proc export data=nbbo 
outfile='C:\Users\Hoang\Dropbox\AS3\nbbo.xlsx' 
dbms=xlsx;
sheet='nbbo';
run;
*/
