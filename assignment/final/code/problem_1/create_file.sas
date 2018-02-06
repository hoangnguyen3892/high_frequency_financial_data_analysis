/*********Download stock***********/
libname check 'C:\Users\Hoang\Dropbox\Final\data';
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

/**********************DAILY NBBO*********************/
data DailyNBBO;
set nbbo.nbbom_20030910;
where sym_root in ('WHR')
and (('9:00:00.000000't) <= time_m <= ('16:00:00.000000't)); 
format date date9.;
format time_m part_time trf_time time20.6;
run;


/**********************DAILY QUOTE*********************/
data DailyQuote;
set cq.cqm_20030910;
where sym_root in ('WHR')
and (('9:00:00.000000't) <= time_m <= ('16:00:00.000000't)); 
format date date9.;
format time_m part_time trf_time time20.6;
run;

/**********************DAILY TRADE*********************/
data DailyTrade;
set ct.ctm_20030910;
where sym_root in ('WHR')
and (('9:30:00.000000't) <= time_m <= ('16:00:00.000000't));
type='T'; 
format date date9.;
format time_m part_time trf_time time20.6;
run;


/***********************Clean daily data***********************/

/**********************NBBO*********************/
data nbbo2;
set DailyNBBO; *This is DailyNBBO data;

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
data quoteab;
set DailyQuote;

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
set DailyTrade;
where (('9:30:00.000000't) <= time_m <= ('16:00:00.000000't)) and
Tr_corr eq '00' and price gt 0; 
type='T';
drop tr_corr tr_source tr_rf part_time
rnn trf_time sym_suffix tr_scond tr_stopind;
run;

/*Create merged file*/

/**********************OFFICIAL NBBO*********************/
data quoteab2 (rename=(ask=best_ask bid=best_bid));
set quoteab;
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

data OfficialCompleteNBBO (drop=best_askex best_bidex);
set nbbo2 quoteab2;
by sym_root date qu_seqnum;
run;

proc sort data=OfficialCompleteNBBO;
by sym_root date time_m descending qu_seqnum;
run;

proc sort data=OfficialCompleteNBBO nodupkey;
by sym_root date time_m;
run;


/**********************OFFICIAL NBBO*********************/
data OfficialCompleteNBBO;
set OfficialCompleteNBBO; type='Q';
time_m=time_m+.000001;
drop qu_seqnum;
run;

proc sort data=trade2;
by sym_root date time_m tr_seqnum;
run;

data TradesandCorrespondingNBBO;
set OfficialCompleteNBBO trade2;
by sym_root date time_m type;
run;

data TradesandCorrespondingNBBO (drop=best_ask best_bid best_asksizesshares best_bidsizeshares);
set TradesandCorrespondingNBBO;
by sym_root date;
retain Qtime nbo nbb nboqty nbbqty;
if first.sym_root and type='T' then do;
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


/**********************BUY SELL INDICATORS*********************/
data BuySellIndicators;
set TradesandCorrespondingNBBO;
where type='T';

midpoint=(NBO+NBB)/2;
if NBO=NBB then lock=1;else lock=0;
if NBO<NBB then cross=1;else cross=0;
run;

data BuySellIndicators;
set BuySellIndicators;
by sym_root date;
retain direction2;
direction=dif(price);
if first.sym_root or first.date then direction=.;
if direction ne 0 then direction2=direction;
else direction2=direction2;
drop direction;
run;

data BuySellIndicators;
set as3.BuySellIndicators;
if direction2>0 then BuySellLR=1;
if direction2<0 then BuySellLR=-1;
if direction2=. then BuySellLR=.;

if direction2>0 then BuySellEMO=1;
if direction2<0 then BuySellEMO=-1;
if direction2=. then BuySellEMO=.;

if direction2>0 then BuySellCLNV=1;
if direction2<0 then BuySellCLNV=-1;
if direction2=. then BuySellCLNV=.;
run;

data BuySellIndicators;
set as3.BuySellIndicators;
if lock=0 and cross=0 and price gt midpoint then BuySellLR=1;
if lock=0 and cross=0 and price lt midpoint then BuySellLR=-1;

if lock=0 and cross=0 and price=NBO then BuySellEMO=1;
if lock=0 and cross=0 and price=NBB then BuySellEMO=-1;

ofr30=NBO-.3*(NBO-NBB);
bid30=NBB+.3*(NBO-NBB);

if lock=0 and cross=0 and price le NBO and price ge ofr30 then BuySellCLNV=1;
if lock=0 and cross=0 and price le bid30 and price ge NBB then BuySellCLNV=-1;
run;


data final.buysell_20030910;
set BuySellIndicators;
run;

/***********************Estimate parameters***********************/
data mediate1;
set BuySellIndicators;
DV = ;

data mediate1 (keep = p_d m_d);
set BuySellIndicators;
by sym_root;
if last.sym_root;
rename price = p_d;
rename midpoint = m_d;
run;

data mediate2;
set mediate1 BuySellIndicators;


proc print data=estim_20030910;
run;

proc download data=final.buysell_20030910 out=check.buysell_20030910;
run;

endrsubmit;


proc export data=check.buysell_20030910
outfile='C:\Users\Hoang\Dropbox\Final\data\buysell.xlsx' 
dbms=xlsx;
sheet='buysellindicators';
run;
