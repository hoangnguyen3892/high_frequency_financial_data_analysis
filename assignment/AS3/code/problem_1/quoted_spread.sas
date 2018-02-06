/*Global setting*/
libname as3 'C:\Users\Hoang\Dropbox\AS3\data';

/*Load data*/
data QSpread1;
set as3.OfficialCompleteNBBO;
run;

proc print data=QSpread1(obs=20);
run;


/**********************STEP 10*********************/
/**********************QUOTED SPREADS*********************/
data QSpread1;
set as3.OfficialCompleteNBBO;
if time_m lt ("9:30:00.000000"t) then delete;
run;

proc sort data=QSpread1;
by sym_root date descending time_m;
run;

data QSpread1;
set QSpread1;
by sym_root date;
inforce=abs(dif(time_m));
if first.sym_root or first.date
then inforce=max(("16:00:00.000000"t-time_m),0);
midpoint=(best_ask+best_bid)/2;
run;

proc sort data=QSpread1;
by sym_root date time_m;
run;

data as3.QSpread1;
set QSpread1;
run;

data QSpread2;
set QSpread1;
if Best_Ask=Best_Bid or Best_Ask<Best_Bid then delete;
wQuotedSpread_Dollar=(Best_Ask-Best_Bid)*inforce;
wQuotedSpread_Percent=(log(Best_Ask)-log(Best_Bid))*inforce;
/*----------------------------------------------------------*/
wBestOfcDepth_Dollar=Best_Ask*Best_AskSizeShares*inforce;
wBestBidDepth_Dollar=Best_Bid*Best_BidSizeShares*inforce;
/*----------------------------------------------------------*/
wBestOfcDepth_Share=Best_AskSizeShares*inforce;
wBestBidDepth_Share=Best_BidSizeShares*inforce;
run;

proc sql;
create table as3.QuotedSpreadsandDepths
as select sym_root, date,
sum(inforce) as sumtime,
sum(wQuotedSpread_Dollar) as swQuotedSpread_Dollar,
sum(wQuotedSpread_Percent) as swQuotedSpread_Percent,
sum(wBestOfcDepth_Dollar) as swBestOfcDepth_Dollar,
sum(wBestBidDepth_Dollar) as swBestBidDepth_Dollar,
sum(wBestOfcDepth_Share) as swBestOfcDepth_Share,
sum(wBestBidDepth_Share) as swBestBidDepth_Share
from QSpread2
group by sym_root, date
order by sym_root, date;
quit;

data as3.QuotedSpreadsandDepths;
set as3.QuotedSpreadsandDepths;
QuotedSpread_Dollar=swQuotedSpread_Dollar/sumtime;
QuotedSpread_Percent=swQuotedSpread_Percent/sumtime;
BestOfcDepth_Dollar=swBestOfcDepth_Dollar/sumtime;
BestBidDepth_Dollar=swBestBidDepth_Dollar/sumtime;
BestOfcDepth_Share=swBestOfcDepth_Share/sumtime;
BestBidDepth_Share=swBestBidDepth_Share/sumtime;
drop swQuotedSpread_Dollar swQuotedSpread_Percent
swBestOfcDepth_Dollar swBestBidDepth_Dollar
swBestOfcDepth_Share swBestBidDepth_Share;
run;

proc print data=as3.QuotedSpreadsandDepths;
run;

/*export result*/
proc export data=as3.QuotedSpreadsandDepths
outfile='C:\Users\Hoang\Dropbox\AS3\data\problem_1.xlsx' 
dbms=xlsx replace;
sheet='quotedspread';
run;
