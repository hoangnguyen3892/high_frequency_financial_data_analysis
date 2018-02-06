libname project 'C:\Users\Hoang\Google Drive\UNIST\3rd_Courses\finance\assignment\AS2';

data ct;
set project.ct;
run;

data cq;
set project.cq;
run;

data nbbo;
set project.nbbo;
run;

proc export data=ct outfile='C:\Users\Hoang\Google Drive\UNIST\3rd_Courses\finance\assignment\AS2\data.xlsx' dbms=excelcs replace;
sheet='trade';

proc export data=cq outfile='C:\Users\Hoang\Google Drive\UNIST\3rd_Courses\finance\assignment\AS2\data.xlsx' dbms=excelcs replace;
sheet='quote';

proc export data=nbbo outfile='C:\Users\Hoang\Google Drive\UNIST\3rd_Courses\finance\assignment\AS2\data.xlsx' dbms=excelcs replace;
sheet='nbbo';
run;
