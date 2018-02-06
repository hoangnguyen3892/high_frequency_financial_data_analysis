/*Global setting*/
libname as3 'C:\Users\Hoang\Dropbox\AS3\data';

data quoteab;
set as3.cq;

/*Select data in working hours*/
where (('9:00:00.000000't) <= time_m <= ('16:00:00.000000't)); 

Spread = Ask - Bid;

/*Quote condition*/
if qu_cond not in ('A', 'B', 'H', 'O', 'R', 'W') then delete;

if Bid>Ask then delete;

if Spread>5 then delete;

if ask le 0 or ask=. then delete;
if asksiz le 0 or asksiz=. then delete;
if bid le 0 or bid=. then delete;
if bidsiz le 0 or bidsiz=. then delete;

drop sym_suffix bidex askex qu_cancel qu_source rpi ssr 
luld_bbo_cqs luld_bbo_utp finra_adf_mpid sip_message_id 
part_time rrn trf_time natl_bbo_luld;
run;

/*Save data*/
proc print data=quoteab(obs=20);
run;

*proc contents data=quoteab;
*run;

data as3.quote2;
set quoteab;
run;

/*
proc export data=cq
outfile='C:\Users\Hoang\Google Drive\UNIST\3rd_Courses\finance\assignment\AS2\data\quoteab.xlsx' 
dbms=xlsx;
sheet='quoteab';
run;
*/

