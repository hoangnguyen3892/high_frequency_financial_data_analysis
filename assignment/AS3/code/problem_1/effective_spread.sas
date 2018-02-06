/*Global setting*/
libname as3 'C:\Users\Hoang\Dropbox\AS3\data';

/*Load data*/
data ESpread1;
set as3.BuySellIndicators;
run;

*proc print data=ESpread1(obs=20);
*run;


/**********************STEP 11*********************/
/**********************EFFECTIVE SPREADS*********************/
data as3.BuySellIndicators;
set as3.BuySellIndicators;
wEffectiveSpread_Dollar=(abs(price-midpoint))*2;
wEffectiveSpread_Percent=(abs(log(price)-log(midpoint)))*2;
dollar=price*size;
wEffectiveSpread_Dollar_DW=wEffectiveSpread_Dollar*dollar;
wEffectiveSpread_Dollar_SW=wEffectiveSpread_Dollar*size;
wEffectiveSpread_Percent_DW=wEffectiveSpread_Percent*dollar;
wEffectiveSpread_Percent_SW=wEffectiveSpread_Percent*size;
run;

data TSpread2;
set as3.BuySellIndicators;
if lock=1 or cross=1 then delete;
run;

proc sql;
create table as3.EffectiveSpreads
as select sym_root, date,
sum(dollar) as sumdollar,
sum(size) as sumsize,
mean(wEffectiveSpread_Dollar) as EffectiveSpread_Dollar_Ave,
mean(wEffectiveSpread_Percent) as EffectiveSpread_Percent_Ave,
sum(wEffectiveSpread_Dollar_DW) as waEffectiveSpread_Dollar_DW,
sum(wEffectiveSpread_Dollar_SW) as waEffectiveSpread_Dollar_SW,
sum(wEffectiveSpread_Percent_DW) as waEffectiveSpread_Percent_DW,
sum(wEffectiveSpread_Percent_SW) as waEffectiveSpread_Percent_SW
from TSpread2
group by sym_root, date
order by sym_root, date;
quit;


data as3.EffectiveSpreads;
set as3.EffectiveSpreads;
EffectiveSpread_Dollar_DW=waEffectiveSpread_Dollar_DW/sumdollar;
EffectiveSpread_Dollar_SW=waEffectiveSpread_Dollar_SW/sumsize;
EffectiveSpread_Percent_DW=waEffectiveSpread_Percent_DW/sumdollar;
EffectiveSpread_Percent_SW=waEffectiveSpread_Percent_SW/sumsize;
drop waEffectiveSpread_Dollar_DW waEffectiveSpread_Dollar_SW
waEffectiveSpread_Percent_DW waEffectiveSpread_Percent_SW
run;

proc print data=as3.EffectiveSpreads;
run;

/*export result*/
proc export data=as3.EffectiveSpreads
outfile='C:\Users\Hoang\Dropbox\AS3\data\problem_1.xlsx' 
dbms=xlsx replace;
sheet='effectivespread';
run;
