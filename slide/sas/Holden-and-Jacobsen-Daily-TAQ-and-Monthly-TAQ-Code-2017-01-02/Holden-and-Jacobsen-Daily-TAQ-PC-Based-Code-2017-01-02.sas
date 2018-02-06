/* HOLDEN AND JACOBSEN DAILY TAQ PC-BASED CODE 2017-01-02 

   Our SAS code selects the Daily TAQ (DTAQ) data that you want from WRDS,
   downloads it to a PC, creates the official complete National Best Bid
   and Offer (NBBO), and computes standard liquidity measures. It was last
   updated on January 2, 2017.

   It is based on: Holden, C. and S. Jacobsen, 2014, Liquidity Measurement 
   Problems in Fast, Competitive Markets: Expensive and Cheap Solutions,
   Journal of Finance 69, 1747-1785. Our original research code has been 
   adapted to work with WRDS and updated for the switch to microseconds.

   Our code creates the following files in the "project" folder of a PC:

      (1) Raw data files containing DTAQ data downloaded from WRDS: 
          "project.DailyNBBO" contains NBBO data
          "project.DailyQuote" contains quote data
          "project.DailyTrade" contains trade data

          Importantly, the "project.DailyNBBO" file does NOT contain the 
          complete NBBO. When one exchange has both the best bid and best 
          offer it is only noted in the "project.DailyQuote" file, not the 
          "project.DailyNBBO" file. Our code combines data from both files
          to construct the official complete NBBO (see file below).

      (2) Intermediate data files:
          "project.OfficialCompleteNBBO" contains the official complete NBBO
          "project.TradesandCorrespondingNBBO" contains trades and the 
              corresponding NBBO from the prior microsecond
          "project.BuySellIndicators" adds buy/sell indicators based on three 
              conventions: LR = Lee & Ready (1991), EMO = Ellis, Michaely &
              O�Hara (2000), CLNV =Chakrabarty, Li, Nguyen, & Van Ness (2006)

      (3) Output files containing standard liquidity measures:
          "project.QuotedSpreadsandDepths" contains Quoted Spreads and Depths
          "project.EffectiveSpreads" contains Effective Spreads
          "project.RealizedSpreadsandPriceImpacts" contains Realized Spreads 
              and Price Impacts that are aggregated based three conventions:
              Ave = simple average, DW = dollar-weighted, SW = share-weighted
   
   Step-by-step instructions for running this program using WRDS PC-SAS 
   Connect are available at: www.kelley.iu.edu/cholden/instructions.pdf

   We welcome any comments or suggestions. We can be reached at:
      Craig Holden: cholden@indiana.edu
      Stacey Jacobsen: staceyj@cox.smu.edu 

   We thank Charles Collver, Ruslan Goyenko, and Zhong Zhang for helpful 
   suggestions and corrections. We are solely responsible for any remaining 
   errors. Of course, you use this code at your own risk. */

/* Global settings */
libname project 'C:\Project'; 
options errors=50;

/* STEP 1: RETRIEVE DAILY TRADE AND QUOTE (DTAQ) FILES FROM WRDS AND
           DOWNLOAD TO PC */

/* Connect to WRDS */
%let wrds=wrds-cloud.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

/* Submit SAS statements to WRDS */
rsubmit;
    libname nbbo '/wrds/nyse/sasdata/taqms/nbbo';
    libname cq '/wrds/nyse/sasdata/taqms/cq';
    libname ct '/wrds/nyse/sasdata/taqms/ct';
    option msglevel=i mprint source; 

	/* Retrieve NBBO data */
    data DailyNBBO;

        /* Enter NBBO file names in YYYYMMDD format for the dates you want */
        set nbbo.nbbom_20161205 nbbo.nbbom_20161206;

		/* Enter company tickers you want */
        where sym_root in ('AAPL','IBM') and 

        /* Quotes are retrieved prior to market open time to ensure NBBO 
		   Quotes are available for beginning of the day trades */
        (("9:00:00.000000000"t) <= time_m <= ("16:00:00.000000000"t));
        format date date9.;
        format time_m part_time trf_time TIME20.9;
    run;

    /* Retrieve Quote data */
    data DailyQuote;

        /* Enter Quote file names in YYYYMMDD format for the same dates */
        set cq.cqm_20161205 cq.cqm_20161206;

		/* Enter the same company tickers as above */
        where sym_root in ('AAPL','IBM') and 

        /* Quotes are retrieved prior to market open time to ensure NBBO 
		   Quotes are available for beginning of the day trades*/
        (("9:00:00.000000000"t) <= time_m <= ("16:00:00.000000000"t));
        format date date9.;
        format time_m part_time trf_time TIME20.9;
    run;

    /* Retrieve Trade data */
    data DailyTrade;

        /* Enter Trade file names in YYYYMMDD format for the same dates */
        set ct.ctm_20161205 ct.ctm_20161206;

		/* Enter the same company tickers as above */
        where sym_root in ('AAPL','IBM') and 

        /* Retrieve trades during normal market hours */
        (("9:30:00.000000000"t) <= time_m <= ("16:00:00.000000000"t));
        type='T';
        format date date9.;
        format time_m part_time trf_time TIME20.9;
    run;

    /* Download to PC */
    proc download data=DailyNBBO out=project.DailyNBBO; 
    run;

    proc download data=DailyQuote out=project.DailyQuote; 
    run;

    proc download data=DailyTrade out=project.DailyTrade; 
    run;

endrsubmit;

/* STEP 2: CLEAN THE DTAQ NBBO FILE */ 

data NBBO2;
    set project.DailyNBBO;

    /* Quote Condition must be normal (i.e., A,B,H,O,R,W) */
    if Qu_Cond not in ('A','B','H','O','R','W') then delete;

	/* If canceled then delete */
    if Qu_Cancel='B' then delete;

	/* if both ask and bid are set to 0 or . then delete */
    if Best_Ask le 0 and Best_Bid le 0 then delete;
    if Best_Asksiz le 0 and Best_Bidsiz le 0 then delete;
    if Best_Ask = . and Best_Bid = . then delete;
    if Best_Asksiz = . and Best_Bidsiz = . then delete;

	/* Create spread and midpoint */
    Spread=Best_Ask-Best_Bid;
    Midpoint=(Best_Ask+Best_Bid)/2;

	/* If size/price = 0 or . then price/size is set to . */
    if Best_Ask le 0 then do;
        Best_Ask=.;
        Best_Asksiz=.;
    end;
    if Best_Ask=. then Best_Asksiz=.;
    if Best_Asksiz le 0 then do;
        Best_Ask=.;
        Best_Asksiz=.;
    end;
    if Best_Asksiz=. then Best_Ask=.;
    if Best_Bid le 0 then do;
        Best_Bid=.;
        Best_Bidsiz=.;
    end;
    if Best_Bid=. then Best_Bidsiz=.;
    if Best_Bidsiz le 0 then do;
        Best_Bid=.;
        Best_Bidsiz=.;
    end;
    if Best_Bidsiz=. then Best_Bid=.;

	/*	Bid/Ask size are in round lots, replace with new shares variable*/
	Best_BidSizeShares = Best_BidSiz * 100;
	Best_AskSizeShares = Best_AskSiz * 100;
run;

/* STEP 3: GET PREVIOUS MIDPOINT */

proc sort 
    data=NBBO2 (drop = Best_BidSiz Best_AskSiz);
    by sym_root date;
run; 

data NBBO2;
    set NBBO2;
    by sym_root date;
    lmid=lag(Midpoint);
    if first.sym_root or first.date then lmid=.;
    lm25=lmid-2.5;
    lp25=lmid+2.5;
run;

/* If the quoted spread is greater than $5.00 and the bid (ask) price is less
   (greater) than the previous midpoint - $2.50 (previous midpoint + $2.50), 
   then the bid (ask) is not considered. */

data NBBO2;
    set NBBO2;
    if Spread gt 5 and Best_Bid lt lm25 then do;
        Best_Bid=.;
        Best_BidSizeShares=.;
    end;
    if Spread gt 5 and Best_Ask gt lp25 then do;
        Best_Ask=.;
        Best_AskSizeShares=.;
    end;
	keep date time_m sym_root Best_Bidex Best_Bid Best_BidSizeShares Best_Askex 
         Best_Ask Best_AskSizeShares Qu_SeqNum;
run;

/* STEP 4: OUTPUT NEW NBBO RECORDS - IDENTIFY CHANGES IN NBBO RECORDS 
   (CHANGES IN PRICE AND/OR DEPTH) */

data NBBO2;
    set NBBO2;
    if sym_root ne lag(sym_root) 
       or date ne lag(date) 
       or Best_Ask ne lag(Best_Ask) 
       or Best_Bid ne lag(Best_Bid) 
       or Best_AskSizeShares ne lag(Best_AskSizeShares) 
       or Best_BidSizeShares ne lag(Best_BidSizeShares); 
run;

/* STEP 5: CLEAN DTAQ QUOTES DATA */

data quoteAB;
    set project.DailyQuote;

    /* Create spread and midpoint*/;
    Spread=Ask-Bid;

	/* Delete if abnormal quote conditions */
    if Qu_Cond not in ('A','B','H','O','R','W')then delete; 

	/* Delete if abnormal crossed markets */
    if Bid>Ask then delete;

	/* Delete abnormal spreads*/
    if Spread>5 then delete;

	/* Delete withdrawn Quotes. This is 
	   when an exchange temporarily has no quote, as indicated by quotes 
	   with price or depth fields containing values less than or equal to 0 
	   or equal to '.'. See discussion in Holden and Jacobsen (2014), 
	   page 11. */
    if Ask le 0 or Ask =. then delete;
    if Asksiz le 0 or Asksiz =. then delete;
    if Bid le 0 or Bid =. then delete;
    if Bidsiz le 0 or Bidsiz =. then delete;
	drop Sym_Suffix Bidex Askex Qu_Cancel RPI SSR LULD_BBO_CQS 
         LULD_BBO_UTP FINRA_ADF_MPID SIP_Message_ID Part_Time RRN TRF_Time 
         Spread NATL_BBO_LULD;
run;

/* STEP 6: CLEAN DAILY TRADES DATA - DELETE ABNORMAL TRADES */

data trade2;
    set project.DailyTrade;
    where Tr_Corr eq '00' and price gt 0;
	drop Tr_Corr Tr_Source TR_RF Part_Time RRN TRF_Time Sym_Suffix Tr_SCond 
         Tr_StopInd;
run;

/* STEP 7: THE NBBO FILE IS INCOMPLETE BY ITSELF (IF A SINGLE EXCHANGE 
   HAS THE BEST BID AND OFFER, THE QUOTE IS INCLUDED IN THE QUOTES FILE, BUT 
   NOT THE NBBO FILE). TO CREATE THE COMPLETE OFFICIAL NBBO, WE NEED TO 
   MERGE WITH THE QUOTES FILE (SEE FOOTNOTE 6 AND 24 IN OUR PAPER) */

data quoteAB2 (rename=(Ask=Best_Ask Bid=Best_Bid));
    set quoteAB;
    where (Qu_Source = "C" and NatBBO_Ind='1') or (Qu_Source = "N" and NatBBO_Ind='4');
    keep date time_m sym_root Qu_SeqNum Bid Best_BidSizeShares Ask Best_AskSizeShares;

	/*	Bid/Ask size are in round lots, replace with new shares variable
	and rename Best_BidSizeShares and Best_AskSizeShares*/
	Best_BidSizeShares = Bidsiz * 100;
	Best_AskSizeShares = Asksiz * 100;
run;

proc sort data=NBBO2;
    by sym_root date Qu_SeqNum;
run;

proc sort data=quoteAB2;
    by sym_root date Qu_SeqNum;
run;

data project.OfficialCompleteNBBO (drop=Best_Askex Best_Bidex);
    set NBBO2 quoteAB2;
    by sym_root date Qu_SeqNum;
run;

/* If the NBBO Contains two quotes in the exact same microseond, assume 
   last quotes (based on sequence number) is active one */
proc sort data=project.OfficialCompleteNBBO;
    by sym_root date time_m descending Qu_SeqNum;
run;

proc sort data=project.OfficialCompleteNBBO nodupkey;
    by sym_root date time_m;
run;

/* STEP 8: INTERLEAVE TRADES WITH NBBO QUOTES. DTAQ TRADES AT MICROSECOND 
   TMMMMMM ARE MATCHED WITH THE DTAQ NBBO QUOTES STILL IN FORCE AT THE 
   MICROSECOND TMMMMM(M-1) */;

data project.OfficialCompleteNBBO;
    set project.OfficialCompleteNBBO;type='Q';
    time_m=time_m+.000000001;
	drop Qu_SeqNum;
run;

proc sort data=project.OfficialCompleteNBBO;
    by sym_root date time_m;
run;

proc sort data=trade2;
    by sym_root date time_m Tr_SeqNum;
run;

data project.TradesandCorrespondingNBBO;
    set project.OfficialCompleteNBBO trade2;
    by sym_root date time_m type;
run;

data project.TradesandCorrespondingNBBO 
    (drop=Best_Ask Best_Bid Best_AskSizeShares Best_BidSizeShares);
    set project.TradesandCorrespondingNBBO;
    by sym_root date;
    retain QTime NBO NBB NBOqty NBBqty;
    if first.sym_root or first.date and type='T' then do;
		QTime=.;
        NBO=.;
        NBB=.;
        NBOqty=.;
        NBBqty=.;
    end;
    if type='Q' then Qtime=time_m;
        else Qtime=Qtime;
    if type='Q' then NBO=Best_Ask;
        else NBO=NBO;
    if type='Q' then NBB=Best_Bid;
        else NBB=NBB;
    if type='Q' then NBOqty=Best_AskSizeShares;
        else NBOqty=NBOqty;
    if type='Q' then NBBqty=Best_BidSizeShares;
        else NBBqty=NBBqty;
	format Qtime TIME20.9;
run;

/* STEP 9: CLASSIFY TRADES AS "BUYS" OR "SELLS" USING THREE CONVENTIONS:
   LR = LEE AND READY (1991), EMO = ELLIS, MICHAELY, AND O'HARA (2000)
   AND CLNV = CHAKRABARTY, LI, NGUYEN, AND VAN NESS (2006); DETERMINE NBBO 
   MIDPOINT AND LOCKED AND CROSSED NBBOs */

data project.BuySellIndicators;
    set project.TradesandCorrespondingNBBO;
    where type='T';
    midpoint=(NBO+NBB)/2;
    if NBO=NBB then lock=1;else lock=0;
    if NBO<NBB then cross=1;else cross=0;
run;

/* Determine Whether Trade Price is Higher or Lower than Previous Trade 
   Price, or "Trade Direction" */
data project.BuySellIndicators;
    set project.BuySellIndicators;
    by sym_root date;
	retain direction2;
    direction=dif(price);
    if first.sym_root or first.date then direction=.;
    if direction ne 0 then direction2=direction; 
    else direction2=direction2;
	drop direction;
run;

/* First Classification Step: Classify Trades Using Tick Test */
data project.BuySellIndicators;
    set project.BuySellIndicators;
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

/* Second Classification Step: Update Trade Classification When 
   Conditions are Met as Specified by LR, EMO, and CLNV */
data project.BuySellIndicators;
    set project.BuySellIndicators;
    if lock=0 and cross=0 and price gt midpoint then BuySellLR=1;
    if lock=0 and cross=0 and price lt midpoint then BuySellLR=-1;
    if lock=0 and cross=0 and price=NBO then BuySellEMO=1;
    if lock=0 and cross=0 and price=NBB then BuySellEMO=-1;
    ofr30=NBO-.3*(NBO-NBB);
    bid30=NBB+.3*(NBO-NBB);
    if lock=0 and cross=0 and price le NBO and price ge ofr30
        then BuySellCLNV=1;
    if lock=0 and cross=0 and price le bid30 and price ge NBB 
        then BuySellCLNV=-1;
run;

/* STEP 10: CALCULATE QUOTED SRPEADS AND DEPTHS */

/* Use Quotes During Normal Market Hours */
data QSpread1;
    set project.OfficialCompleteNBBO;
    if time_m lt ("9:30:00.000000000"t) then delete;
run;

/* Determine Time Each Quote is In Force - If Last Quote of Day, then Quote
   is Inforce Until 4:00 pm */

proc sort data=QSpread1;
    by sym_root date descending time_m;
run;

data QSpread1;
    set QSpread1;
    by sym_root date;
    inforce=abs(dif(time_m));
	if first.sym_root or first.date 
    then inforce=max(("16:00:00.000000000"t-time_m),0);
	midpoint=(Best_Ask+Best_Bid)/2;
run;

proc sort data=QSpread1;
    by sym_root date time_m;
run;

data QSpread2;
    set QSpread1;
/* Delete Locked and Crossed Quotes */
    if Best_Ask=Best_Bid or Best_Ask<Best_Bid then delete;
/* Multiply Dollar Quoted Spread, Percent Quoted Spread, Best Dollar 
   Depth, and Best Share Depth by Time Inforce */
    wQuotedSpread_Dollar=(Best_Ask-Best_Bid)*inforce;
    wQuotedSpread_Percent=(log(Best_Ask)-log(Best_Bid))*inforce;
    wBestOfrDepth_Dollar=Best_Ask*Best_AskSizeShares*inforce;
    wBestBidDepth_Dollar=Best_Bid*Best_BidSizeShares*inforce;
    wBestOfrDepth_Share=Best_AskSizeShares*inforce;
    wBestBidDepth_Share=Best_BidSizeShares*inforce;
run;

/* Find Average Across Firm-Day */
proc sql;
    create table project.QuotedSpreadsandDepths 
    as select sym_root,date,
    sum(inforce) as sumtime,
    sum(wQuotedSpread_Dollar) as swQuotedSpread_Dollar,
    sum(wQuotedSpread_Percent) as swQuotedSpread_Percent,
    sum(wBestOfrDepth_Dollar) as swBestOfrDepth_Dollar,
    sum(wBestBidDepth_Dollar) as swBestBidDepth_Dollar,
    sum(wBestOfrDepth_Share) as swBestOfrDepth_Share,
    sum(wBestBidDepth_Share) as swBestBidDepth_Share 
    from QSpread2 
    group by sym_root,date 
    order by sym_root,date;
quit;

/* Calculate Time-Weighted Dollar Quoted Spread, Percent Quoted Spread, 
   Best Dollar Depth, and Best Share Depth */
data project.QuotedSpreadsandDepths;
    set project.QuotedSpreadsandDepths;
    QuotedSpread_Dollar=swQuotedSpread_Dollar/sumtime;
    QuotedSpread_Percent=swQuotedSpread_Percent/sumtime;
    BestOfrDepth_Dollar=swBestOfrDepth_Dollar/sumtime;
    BestBidDepth_Dollar=swBestBidDepth_Dollar/sumtime;
    BestOfrDepth_Share=swBestOfrDepth_Share/sumtime;
    BestBidDepth_Share=swBestBidDepth_Share/sumtime;
	drop swQuotedSpread_Dollar swQuotedSpread_Percent 
         swBestOfrDepth_Dollar swBestBidDepth_Dollar
         swBestOfrDepth_Share swBestBidDepth_Share;
run;

/* STEP 11: CALCULATE EFFECTIVE SPREADS; AGGREGATE BASED ON 3 CONVENTIONS:
   Ave = SIMPLE AVERAGE, DW = DOLLAR-WEIGHTED, SW = SHARE-WEIGHTED */
data project.BuySellIndicators;
    set project.BuySellIndicators;
    wEffectiveSpread_Dollar=(abs(price-midpoint))*2;
    wEffectiveSpread_Percent=abs(log(price)-log(midpoint))*2;
    dollar=price*size;
    wEffectiveSpread_Dollar_DW=wEffectiveSpread_Dollar*dollar;
    wEffectiveSpread_Dollar_SW=wEffectiveSpread_Dollar*size;
    wEffectiveSpread_Percent_DW=wEffectiveSpread_Percent*dollar;
    wEffectiveSpread_Percent_SW=wEffectiveSpread_Percent*size;
run;

/* Delete Trades Associated with Locked or Crossed Best Bids or Best 
   Offers */
data TSpread2;
    set project.BuySellIndicators;
    if lock=1 or cross=1 then delete;
run;

/* Find average across firm-day */
proc sql;
    create table project.EffectiveSpreads 
    as select sym_root,date,
    sum(dollar) as sumdollar,
    sum(size) as sumsize,
    mean(wEffectiveSpread_Dollar) as EffectiveSpread_Dollar_Ave,
    mean(wEffectiveSpread_Percent) as EffectiveSpread_Percent_Ave,
    sum(wEffectiveSpread_Dollar_DW) as waEffectiveSpread_Dollar_DW,
    sum(wEffectiveSpread_Dollar_SW) as waEffectiveSpread_Dollar_SW,
    sum(wEffectiveSpread_Percent_DW) as waEffectiveSpread_Percent_DW,
    sum(wEffectiveSpread_Percent_SW) as waEffectiveSpread_Percent_SW 
    from TSpread2 
    group by sym_root,date 
    order by sym_root,date;
quit;

/* Calculate Dollar-Weighted (DW) and Share-Weighted (SW) Dollar Effective 
   Spreads and Percent Effective Spreads */
data project.EffectiveSpreads;
    set project.EffectiveSpreads;
    EffectiveSpread_Dollar_DW=waEffectiveSpread_Dollar_DW/sumdollar;
    EffectiveSpread_Dollar_SW=waEffectiveSpread_Dollar_SW/sumsize;
    EffectiveSpread_Percent_DW=waEffectiveSpread_Percent_DW/sumdollar;
    EffectiveSpread_Percent_SW=waEffectiveSpread_Percent_SW/sumsize;
	drop waEffectiveSpread_Dollar_DW waEffectiveSpread_Dollar_SW
         waEffectiveSpread_Percent_DW waEffectiveSpread_Percent_SW;
run;

/* STEP 12: CALCULATE REALIZED SPREADS AND PRICE IMPACTS BASED ON THREE:
   CONVENTIONS: LR = LEE AND READY (1991), EMO = ELLIS, MICHAELY, AND O'HARA 
   (2000) AND CLNV = CHAKRABARTY, LI, NGUYEN, AND VAN NESS (2006);  
   FIND THE NBBO MIDPOINT 5 MINUTES SUBSEQUENT TO THE TRADE */

/* Redefine the time variable as 5 minutes earlier (e.g., quotes at 
   10:00:00 are redefined as occurring at 9:55:00 in order to match to 
   trades occurring at 9:55:00. This way we match trades occurring at time T
   to NBBO quotes outstanding at T+5). */
data MidQ (keep=sym_root date type midpointnew time_m BEST_ASKnew 
    BEST_BIDnew);
    set QSpread1;
    midpointnew=midpoint;
    time_m=time_m-300;
    Best_AskNew=Best_Ask;
    Best_BidNew=Best_Bid;
run;

data MidT (keep=sym_root date time_M type midpoint price BuySellLR 
        BuySellEMO BuySellCLNV wEffectiveSpread_Dollar size dollar);
    set project.BuySellIndicators;
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

/* Delete Trades at T Associated with Locked or Crossed Best Bids or Best 
   Offers at T+5 */
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

    /* Multiply Realized Spreads and Price Impact by Dollar and Share Size
	   of Trade for LR, EMO, and CLNV */
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
    create table project.RealizedSpreadsandPriceImpacts 
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
data project.RealizedSpreadsandPriceImpacts;
    set project.RealizedSpreadsandPriceImpacts;
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
