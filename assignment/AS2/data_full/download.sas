/*********Download stock***********/

libname project 'C:\Users\Hoang\Google Drive\UNIST\3rd_Courses\finance\assignment\AS2';

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

%let dt='06JUN2013'd;

*'62671710'-'626717102': N; 
*'70339510'-'703395103': Q;

data temp;
set mast.mastm_20130606();
where substr(left(cusip), 1, 8) in ('62671710','70339510');
keep symbol_root symbol_suffix cusip;
run;

proc print data=temp;
run;

proc sql;
create table nbbo as
select a.*
from nbbo.nbbom_20130606 as a, temp as b
where (a.sym_root = b.symbol_root) and (a.sym_suffix = b.symbol_suffix);
quit;

proc sql;
create table cq as
select a.*
from cq.cqm_20130606 as a, temp as b
where (a.sym_root = b.symbol_root) and (a.sym_suffix = b.symbol_suffix);
quit;

proc sql;
create table ct as
select a.*
from ct.ctm_20130606 as a, temp as b
where (a.sym_root = b.symbol_root) and (a.sym_suffix = b.symbol_suffix);
quit;

proc download data=nbbo out=project.nbbo;
run;

proc download data=cq out=project.cq;
run;

proc download data=ct out=project.ct;
run;


endrsubmit;
