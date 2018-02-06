libname project 'C:\Users\Hoang\Google Drive\UNIST\3rd_Courses\finance\assignment\AS2\data';

/*Filter the data*/

data ct;
set project.ct;
where (('9:00:00.00000't) <= time_m <= ('16:00:00.00000't)); 
format date date9.;
format time_m time20.6;
run;

data cq;
set project.cq;
where (('9:00:00.00000't) <= time_m <= ('16:00:00.00000't)); 
format date date9.;
format time_m time20.6;
run;

data nbbo;
set project.nbbo;
where (('9:00:00.00000't) <= time_m <= ('16:00:00.00000't)); 
format date date9.;
format time_m time20.6;
run;


proc export data=ct 
outfile='C:\Users\Hoang\Google Drive\UNIST\3rd_Courses\finance\assignment\AS2\data\data.xlsx' 
dbms=xlsx;
sheet='trade';

proc export data=cq 
outfile='C:\Users\Hoang\Google Drive\UNIST\3rd_Courses\finance\assignment\AS2\data\data.xlsx' 
dbms=xlsx replace;
sheet='quote';

proc export data=nbbo 
outfile='C:\Users\Hoang\Google Drive\UNIST\3rd_Courses\finance\assignment\AS2\data\data.xlsx' 
dbms=xlsx replace;
sheet='nbbo';
run;
