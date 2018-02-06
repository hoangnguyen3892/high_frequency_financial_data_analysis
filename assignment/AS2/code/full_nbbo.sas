/*Global setting*/
libname project 'C:\Users\Hoang\Google Drive\UNIST\3rd_Courses\finance\assignment\AS2\data';

/**********************NBBO*********************/
data nbbo2;
set project.nbbo; *This is DailyNBBO data;

/*Select data in working hours*/
where (('9:00:00.000000't) <= time_m <= ('16:00:00.000000't)); 

/*Quote condition*/
if qu_cond not in ('A', 'B', 'H', 'O', 'R', 'W') then delete;

if qu_cancel = 'B' then delete;


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


proc sort
	data=nbbo2 (drop = best_bidsiz best_asksiz);
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

keep 	date time_m sym_root sym_suffix 
		best_bidex best_bid best_bidsizeshares 
		best_askex best_ask best_asksizeshares
		qu_seqnum;
run;

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

/**********************QUOTE*********************/
data cq;
set project.cq;

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


/**********************TRADE*********************/
data trade2;
set project.ct;
where (('9:30:00.000000't) <= time_m <= ('16:00:00.000000't)); 
type='T';
drop tr_corr tr_source tr_rf part_time
rnn trf_time sym_suffix tr_scond tr_stopind;
run;


/**********************OFFICIAL NBBO*********************/
data quoteab2 (rename=(ask=best_ask bid=best_bid));
set cq;
where natbbo_ind='1' or nasdbbo_ind='4';
keep date time_m sym_root qu_seqnum bid best_bidsizeshares ask best_asksizeshares;

best_bidsizeshares = bidsiz*100;
best_asksizeshares = asksiz*100;
run;


proc sort data=nbbo2;
by sym_root date qu_seqnum;
run;

proc sort data=quoteab2;
by sym_root date qu_seqnum;
run;

data project.Officialcompletenbbo (drop=best_askex best_bidex);
set nbbo2 quoteab2;
by sym_root date qu_seqnum;
run;

proc sort data=project.Officialcompletenbbo;
by sym_root date time_m descending qu_seqnum;
run;

proc sort data=project.Officialcompletenbbo nodupkey;
by sym_root date time_m;
run;

/**********************OFFICIAL NBBO*********************/
data project.Officialcompletenbbo;
set project.Officialcompletenbbo; type='Q';
time_m=time_m+.000001;
drop qu_seqnum;
run;

proc sort data=trade2;
by sym_root date time_m tr_seqnum;
run;

data project.tradesandcorrespondingnbbo;
set project.Officialcompletenbbo trade2;
by sym_root date time_m type;
run;

data project.tradesandcorrespondingnbbo (drop=best_ask best_bid best_asksizesshares best_bidsizeshares);
set project.tradesandcorrespondingnbbo;
by sym_root date;
retain Qtime nbo nbb nboqty nbbqty;
if first.sym_root or first.date and type='T' then do;
	qtime=.;
	nbo=.;
	nbb=.;
	nboqty=.;
	nbbqty=.;
end;

if type='Q' then qtime=time_m;
else qtime=qtime;

if type='Q' then nbo=best_ask;
else nbo=nbo;

if type='Q' then nbb=best_bid;
else nbb=nbb;

if type='Q' then nboqty=best_asksizeshares;
else nboqty=nboqty;

if type='Q' then nbbqty=best_bidsizeshares;
else nbbqty=nbbqty;
format qtime time20.6;
run;

*proc export data=project.trade2 
outfile='C:\Users\Hoang\Google Drive\UNIST\3rd_Courses\finance\assignment\AS2\data\trade2.xlsx' 
dbms=xlsx replace;
*sheet='trade';

proc export data=project.tradesandcorrespondingnbbo 
outfile='C:\Users\Hoang\Google Drive\UNIST\3rd_Courses\finance\assignment\AS2\data\tradesandcorrespondingnbbo.xlsx' 
dbms=xlsx replace;
sheet='tradesandcorrespondingnbbo';

proc export data=project.Officialcompletenbbo
outfile='C:\Users\Hoang\Google Drive\UNIST\3rd_Courses\finance\assignment\AS2\data\officialcompletenbbo.xlsx' 
dbms=xlsx replace;
sheet='Officialcompletenbbo';
