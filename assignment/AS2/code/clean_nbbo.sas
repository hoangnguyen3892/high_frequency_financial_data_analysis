/*Global setting*/
libname project 'C:\Users\Hoang\Google Drive\UNIST\3rd_Courses\finance\assignment\AS2\data';


data nbbo2;
set project.nbbo; *This is DailyNBBO data;

/*Select data in working hours*/
where (('9:00:00.000000't) <= time_m <= ('16:00:00.000000't)); 

/*Quote condition*/
if qu_cond not in ('A', 'B', 'H', 'O', 'R', 'W') then delete;

if qu_cancel = 'B' then delete;

*if best_ask le 0 and best_bid le 0 then delete;
*if best_asksiz le 0 and best_bidsiz le 0 then delete;
*if best_ask = . and best_bid = . then delete;
*if best_asksiz = . and best_bidsiz = . then delete;

/*Create spread and midpoint*/
spread = best_ask - best_bid;
midpoint = (best_ask + best_bid)/2;


if best_ask le 0 then do;
	best_ask = .;
	best_asksiz = .;
end;
if best_ask=. then best_asksiz=.;
/*-----------------------------*/
if best_asksiz le 0 then do;
	best_ask = .;
	best_asksiz = .;
end;
if best_asksiz=. then best_ask=.;
/*-----------------------------*/
if best_bid le 0 then do;
	best_bid = .;
	best_bidsiz = .;
end;
if best_bid=. then best_bidsiz=.;
/*-----------------------------*/
if best_bidsiz le 0 then do;
	best_bid = .;
	best_bidsiz = .;
end;
if best_bidsiz=. then best_bid=.;

/*Create new shares*/
best_bidsizeshares = best_bidsiz *100;
best_asksizeshares = best_asksiz *100;

format date date9.;
format time_m time20.6;
run;

/*****************************Step 3: Get previous midpoint*****************************/
proc sort
	data=nbbo2 (drop = best_bidsiz best_asksiz)
	by sym_root sym_suffix date time_m;
run;

data nbbo2;
set nbbo2;
by sym_root sym_suffix date time_m;
lmid = lag(midpoint);
if first.sym_root or first.date or first.sym_suffix then lmid =.;
lm25=lmid-2.5;
lp25=lmid+2.5;
run;

data nbbo2;
set nbbo2;
if spread gt 5 and best_bid lt lm25 then do;
	best_bid = .;
	best_bidsizeshares = .;
end;

if spread gt 5 and best_ask lt lp25 then do;
	best_ask = .;
	best_asksizeshares = .;
end;

keep 	date time_m ex sym_root sym_suffix
		best_bidex best_bid best_bidsizeshares 
		best_askex best_ask best_asksizeshares
		qu_seqnum spread;
run;

/*****************************Step 4: Output new NBBO*****************************/
data nbbo2;
set nbbo2;
if sym_root ne lag(sym_root)
or sym_suffix ne lag(sym_suffix)
or date ne lag(date)
or best_ask ne lag(best_ask)
or best_bid ne lag(best_bid)
or best_asksizeshares ne lag(best_asksizeshares)
or best_bidsizeshares ne lag(best_bidsizeshares);
run;


proc export data=nbbo2
outfile='C:\Users\Hoang\Google Drive\UNIST\3rd_Courses\finance\assignment\AS2\data\nbbo2.xlsx' 
dbms=xlsx replace;
sheet='nbbo';
run;
