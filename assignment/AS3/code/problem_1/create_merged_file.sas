/*Global setting*/
libname as3 'C:\Users\Hoang\Dropbox\AS3\data';

/*Load data*/
data quoteab;
set as3.quote2;
run;

data trade2;
set as3.trade2;
run;

data nbbo2;
set as3.nbbo2;
run;

*proc print data=quoteab(obs=20);
*run;
*proc print data=trade2(obs=20);
*run;
*proc print data=nbbo2(obs=20);
*run;


/**********************STEP 7*********************/
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

data as3.OfficialCompleteNBBO (drop=best_askex best_bidex);
set nbbo2 quoteab2;
by sym_root date qu_seqnum;
run;

proc sort data=as3.OfficialCompleteNBBO;
by sym_root date time_m descending qu_seqnum;
run;

proc sort data=as3.OfficialCompleteNBBO nodupkey;
by sym_root date time_m;
run;


/**********************STEP 8*********************/
/**********************OFFICIAL NBBO*********************/
data as3.OfficialCompleteNBBO;
set as3.OfficialCompleteNBBO; type='Q';
time_m=time_m+.000001;
drop qu_seqnum;
run;

proc sort data=trade2;
by sym_root date time_m tr_seqnum;
run;

data as3.TradesandCorrespondingNBBO;
set as3.OfficialCompleteNBBO trade2;
by sym_root date time_m type;
run;

data as3.TradesandCorrespondingNBBO (drop=best_ask best_bid best_asksizesshares best_bidsizeshares);
set as3.TradesandCorrespondingNBBO;
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

proc print data=as3.OfficialCompleteNBBO(obs=20);
run;

proc print data=as3.TradesandCorrespondingNBBO(obs=100);
run;

/**********************STEP 10*********************/
/**********************BUY SELL INDICATORS*********************/
data as3.BuySellIndicators;
set as3.TradesandCorrespondingNBBO;
where type='T';

midpoint=(NBO+NBB)/2;
if NBO=NBB then lock=1;else lock=0;
if NBO<NBB then cross=1;else cross=0;
run;

data as3.BuySellIndicators;
set as3.BuySellIndicators;
by sym_root date;
retain direction2;
direction=dif(price);
if first.sym_root or first.date then direction=.;
if direction ne 0 then direction2=direction;
else direction2=direction2;
drop direction;
run;

data as3.BuySellIndicators;
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

data as3.BuySellIndicators;
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

proc print data=as3.BuySellIndicators;
run;

