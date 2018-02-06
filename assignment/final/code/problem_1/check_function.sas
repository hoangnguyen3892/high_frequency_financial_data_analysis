libname local 'C:\Users\Hoang\Dropbox\Final\data';

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
	libname final '/home/unist/hnguyen1/final';
	option msglevel=i mprint source;


/***********************Get daily data***********************/
%let nbbo_name = 20030910;
%let ticker_name = WHR;

/**********************DAILY NBBO*********************/
data DailyNBBO;
set nbbo.nbbom_&nbbo_name;
where sym_root in ("&ticker_name")
and (('9:00:00.000000't) <= time_m <= ('16:00:00.000000't)); 
format date date9.;
format time_m part_time trf_time time20.6;
run;

proc print data=DailyNBBO(obs=10);
run;

endrsubmit;
