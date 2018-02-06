/*Global setting*/
libname as3 'C:\Users\Hoang\Dropbox\AS3\data';

/*Load data*/
data QSpread1;
set as3.QSpread1;
run;

*proc print data=ESpread1(obs=20);
*run;


/**********************STEP 12*********************/
/**********************REALIZED SPREADS*********************/
data MidQ(keep=sym_root date type midpointnew time_m BEST_ASKnew BEST_BIDnew);
set QSpread1;
midpointnew=midpoint;
time_m=time_m-300;
Best_AskNew=Best_Ask;
Best_BidNew=Best_Bid;
run;

data MidT (keep=sym_root date time_M type midpoint price BuySellLR 
        BuySellEMO BuySellCLNV wEffectiveSpread_Dollar size dollar);
set as3.BuySellIndicators;
run;

proc sort data=MidQ;
by sym_root date Time_M type;
run;

proc sort data=MidT;
by sym_root date Time_M type;
run;

/* Stack Trades at Time T with NBBO Quotes at Time T+5 */
data Mid1;
set MidT MidQ;
by sym_root date Time_M type;
run;

/* For Each Trade at Time T, Identify the Outstanding NBBO at Time T+5 */
data Mid1;
    set Mid1;
    by sym_root date;
    retain midpoint5 Best_Ask5 Best_Bid5;
    if type='Q' then midpoint5=midpointnew;
    else midpoint5=midpoint5;
    if type='Q' then Best_Ask5=Best_AskNew;else Best_Ask5=Best_Ask5;
    if type='Q' then Best_Bid5=Best_BidNew;else Best_Bid5=Best_Bid5;
	drop midpointnew Best_AskNew Best_BidNew;
run;

/* Delete Trades at T Associated with Locked or Crossed Best Bids or Best Offers at T+5 */
data Mid1;
    set Mid1;
    if Best_Ask5=Best_Bid5 or Best_Ask5<Best_Bid5 then delete;
run;

/* Compute Dollar and Percent Realized Spread and Price Impact for LR, EMO, and CLNV*/
data Mid1; 
    set Mid1; 
    where type='T';

/* Compute Dollar and Percent Realized Spread for LR, EMO, and CLNV */
    wDollarRealizedSpread_LR=BuySellLR*(price-midpoint5)*2;
    wDollarRealizedSpread_EMO=BuySellEMO*(price-midpoint5)*2;
    wDollarRealizedSpread_CLNV=BuySellCLNV*(price-midpoint5)*2;
    wPercentRealizedSpread_LR=BuySellLR*(log(price)-log(midpoint5))*2;
    wPercentRealizedSpread_EMO=BuySellEMO*(log(price)-log(midpoint5))*2;
    wPercentRealizedSpread_CLNV=BuySellCLNV*(log(price)-log(midpoint5))*2;

/* Compute Dollar and Percent Price Impact for LR, EMO, and CLNV */
    wDollarPriceImpact_LR=BuySellLR*(midpoint5-midpoint)*2;
    wDollarPriceImpact_EMO=BuySellEMO*(midpoint5-midpoint)*2;
    wDollarPriceImpact_CLNV=BuySellCLNV*(midpoint5-midpoint)*2;
    wPercentPriceImpact_LR=BuySellLR*(log(midpoint5)-log(midpoint))*2;
    wPercentPriceImpact_EMO=BuySellEMO*(log(midpoint5)-log(midpoint))*2;
    wPercentPriceImpact_CLNV=BuySellCLNV*(log(midpoint5)-log(midpoint))*2;

/* Multiply Realized Spreads and Price Impact by Dollar and Share Size of Trade for LR, EMO, and CLNV */
	wDollarRealizedSpread_LR_SW=wDollarRealizedSpread_LR*size;
	wDollarRealizedSpread_LR_DW=wDollarRealizedSpread_LR*dollar;
	wPercentRealizedSpread_LR_SW=wPercentRealizedSpread_LR*size;
    wPercentRealizedSpread_LR_DW=wPercentRealizedSpread_LR*dollar;
	wDollarPriceImpact_LR_SW=wDollarPriceImpact_LR*size;
	wDollarPriceImpact_LR_DW=wDollarPriceImpact_LR*dollar;
	wPercentPriceImpact_LR_SW=wPercentPriceImpact_LR*size;
	wPercentPriceImpact_LR_DW=wPercentPriceImpact_LR*dollar;
	wDollarRealizedSpread_EMO_SW=wDollarRealizedSpread_EMO*size;
    wDollarRealizedSpread_EMO_DW=wDollarRealizedSpread_EMO*dollar;
    wPercentRealizedSpread_EMO_SW=wPercentRealizedSpread_EMO*size;
    wPercentRealizedSpread_EMO_DW=wPercentRealizedSpread_EMO*dollar;
	wDollarPriceImpact_EMO_SW=wDollarPriceImpact_EMO*size;
	wDollarPriceImpact_EMO_DW=wDollarPriceImpact_EMO*dollar;
	wPercentPriceImpact_EMO_SW=wPercentPriceImpact_EMO*size;
	wPercentPriceImpact_EMO_DW=wPercentPriceImpact_EMO*dollar;
	wDollarRealizedSpread_CLNV_SW=wDollarRealizedSpread_CLNV*size;
    wDollarRealizedSpread_CLNV_DW=wDollarRealizedSpread_CLNV*dollar;
    wPercentRealizedSpread_CLNV_SW=wPercentRealizedSpread_CLNV*size;
    wPercentRealizedSpread_CLNV_DW=wPercentRealizedSpread_CLNV*dollar;
	wDollarPriceImpact_CLNV_SW=wDollarPriceImpact_CLNV*size;
	wDollarPriceImpact_CLNV_DW=wDollarPriceImpact_CLNV*dollar;
	wPercentPriceImpact_CLNV_SW=wPercentPriceImpact_CLNV*size;
	wPercentPriceImpact_CLNV_DW=wPercentPriceImpact_CLNV*dollar;
run;

/* Find average across firm-day */
proc sql; 
    create table as3.RealizedSpreadsandPriceImpacts 
    as select sym_root,date,
    sum(dollar) as sumdollar,
    sum(size) as sumsize,
    mean(wDollarRealizedSpread_LR) as DollarRealizedSpread_LR_Ave,
    mean(wDollarRealizedSpread_EMO) as DollarRealizedSpread_EMO_Ave,
    mean(wDollarRealizedSpread_CLNV) as DollarRealizedSpread_CLNV_Ave,
    mean(wPercentRealizedSpread_LR) as PercentRealizedSpread_LR_Ave,
    mean(wPercentRealizedSpread_EMO) as PercentRealizedSpread_EMO_Ave,
    mean(wPercentRealizedSpread_CLNV) as PercentRealizedSpread_CLNV_Ave,
    mean(wDollarPriceImpact_LR) as DollarPriceImpact_LR_Ave,
    mean(wDollarPriceImpact_EMO) as DollarPriceImpact_EMO_Ave,
    mean(wDollarPriceImpact_CLNV) as DollarPriceImpact_CLNV_Ave,
    mean(wPercentPriceImpact_LR) as PercentPriceImpact_LR_Ave,
    mean(wPercentPriceImpact_EMO) as PercentPriceImpact_EMO_Ave,
    mean(wPercentPriceImpact_CLNV) as PercentPriceImpact_CLNV_Ave,
	sum(wDollarRealizedSpread_LR_SW) as waDollarRealizedSpread_LR_SW,
    sum(wDollarRealizedSpread_LR_DW) as waDollarRealizedSpread_LR_DW,
    sum(wPercentRealizedSpread_LR_SW) as waPercentRealizedSpread_LR_SW,
    sum(wPercentRealizedSpread_LR_DW) as waPercentRealizedSpread_LR_DW,
    sum(wDollarPriceImpact_LR_SW) as waDollarPriceImpact_LR_SW,
    sum(wDollarPriceImpact_LR_DW) as waDollarPriceImpact_LR_DW,
    sum(wPercentPriceImpact_LR_SW) as waPercentPriceImpact_LR_SW,
    sum(wPercentPriceImpact_LR_DW) as waPercentPriceImpact_LR_DW, 
	sum(wDollarRealizedSpread_EMO_SW) as waDollarRealizedSpread_EMO_SW,
    sum(wDollarRealizedSpread_EMO_DW) as waDollarRealizedSpread_EMO_DW,
    sum(wPercentRealizedSpread_EMO_SW) as waPercentRealizedSpread_EMO_SW,
    sum(wPercentRealizedSpread_EMO_DW) as waPercentRealizedSpread_EMO_DW,
    sum(wDollarPriceImpact_EMO_SW) as waDollarPriceImpact_EMO_SW,
    sum(wDollarPriceImpact_EMO_DW) as waDollarPriceImpact_EMO_DW,
    sum(wPercentPriceImpact_EMO_SW) as waPercentPriceImpact_EMO_SW,
    sum(wPercentPriceImpact_EMO_DW) as waPercentPriceImpact_EMO_DW, 
	sum(wDollarRealizedSpread_CLNV_SW) as waDollarRealizedSpread_CLNV_SW,
    sum(wDollarRealizedSpread_CLNV_DW) as waDollarRealizedSpread_CLNV_DW,
    sum(wPercentRealizedSpread_CLNV_SW) as waPercentRealizedSpread_CLNV_SW,
    sum(wPercentRealizedSpread_CLNV_DW) as waPercentRealizedSpread_CLNV_DW,
    sum(wDollarPriceImpact_CLNV_SW) as waDollarPriceImpact_CLNV_SW,
    sum(wDollarPriceImpact_CLNV_DW) as waDollarPriceImpact_CLNV_DW,
    sum(wPercentPriceImpact_CLNV_SW) as waPercentPriceImpact_CLNV_SW,
    sum(wPercentPriceImpact_CLNV_DW) as waPercentPriceImpact_CLNV_DW 
	from Mid1 
    group by sym_root,date 
    order by sym_root,date; 
quit;


/* Calculate Dollar-Weighted (DW) and Share-Weighted (SW) Realized Spreads 
   and Price Impact */
data as3.RealizedSpreadsandPriceImpacts;
    set as3.RealizedSpreadsandPriceImpacts;
    DollarRealizedSpread_LR_SW=waDollarRealizedSpread_LR_SW/sumsize;
    DollarRealizedSpread_LR_DW=waDollarRealizedSpread_LR_DW/sumdollar;
    PercentRealizedSpread_LR_SW=waPercentRealizedSpread_LR_SW/sumsize;
    PercentRealizedSpread_LR_DW=waPercentRealizedSpread_LR_DW/sumdollar;
    DollarPriceImpact_LR_SW=waDollarPriceImpact_LR_SW/sumsize;
    DollarPriceImpact_LR_DW=waDollarPriceImpact_LR_DW/sumdollar;
    PercentPriceImpact_LR_SW=waPercentPriceImpact_LR_SW/sumsize;
    PercentPriceImpact_LR_DW=waPercentPriceImpact_LR_DW/sumdollar;
    DollarRealizedSpread_EMO_SW=waDollarRealizedSpread_EMO_SW/sumsize;
    DollarRealizedSpread_EMO_DW=waDollarRealizedSpread_EMO_DW/sumdollar;
    PercentRealizedSpread_EMO_SW=waPercentRealizedSpread_EMO_SW/sumsize;
    PercentRealizedSpread_EMO_DW=waPercentRealizedSpread_EMO_DW/sumdollar;
    DollarPriceImpact_EMO_SW=waDollarPriceImpact_EMO_SW/sumsize;
    DollarPriceImpact_EMO_DW=waDollarPriceImpact_EMO_DW/sumdollar;
    PercentPriceImpact_EMO_SW=waPercentPriceImpact_EMO_SW/sumsize;
    PercentPriceImpact_EMO_DW=waPercentPriceImpact_EMO_DW/sumdollar;
	DollarRealizedSpread_CLNV_SW=waDollarRealizedSpread_CLNV_SW/sumsize;
    DollarRealizedSpread_CLNV_DW=waDollarRealizedSpread_CLNV_DW/sumdollar;
    PercentRealizedSpread_CLNV_SW=waPercentRealizedSpread_CLNV_SW/sumsize;
    PercentRealizedSpread_CLNV_DW=waPercentRealizedSpread_CLNV_DW/sumdollar;
    DollarPriceImpact_CLNV_SW=waDollarPriceImpact_CLNV_SW/sumsize;
    DollarPriceImpact_CLNV_DW=waDollarPriceImpact_CLNV_DW/sumdollar;
    PercentPriceImpact_CLNV_SW=waPercentPriceImpact_CLNV_SW/sumsize;
    PercentPriceImpact_CLNV_DW=waPercentPriceImpact_CLNV_DW/sumdollar;
	drop waDollarRealizedSpread_LR_SW waDollarRealizedSpread_LR_DW
	     waPercentRealizedSpread_LR_SW waPercentRealizedSpread_LR_DW
		 waDollarPriceImpact_LR_SW waDollarPriceImpact_LR_DW
         waPercentPriceImpact_LR_SW waPercentPriceImpact_LR_DW
         waDollarRealizedSpread_EMO_SW waDollarRealizedSpread_EMO_DW
	     waPercentRealizedSpread_EMO_SW waPercentRealizedSpread_EMO_DW
		 waDollarPriceImpact_EMO_SW waDollarPriceImpact_EMO_DW
         waPercentPriceImpact_EMO_SW waPercentPriceImpact_EMO_DW
	     waDollarRealizedSpread_CLNV_SW waDollarRealizedSpread_CLNV_DW
	     waPercentRealizedSpread_CLNV_SW waPercentRealizedSpread_CLNV_DW
		 waDollarPriceImpact_CLNV_SW waDollarPriceImpact_CLNV_DW
         waPercentPriceImpact_CLNV_SW waPercentPriceImpact_CLNV_DW;
run;



proc print data=as3.RealizedSpreadsandPriceImpacts;
run;

/*export result*/
proc export data=as3.RealizedSpreadsandPriceImpacts
outfile='C:\Users\Hoang\Dropbox\AS3\data\problem_1.xlsx' 
dbms=xlsx replace;
sheet='realizedspread';
run;
