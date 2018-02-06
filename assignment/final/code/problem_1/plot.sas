libname estim 'C:\Users\Hoang\Dropbox\Final\data';

%let ticker_name = QCOM;

data &ticker_name;
set estim.estim_&ticker_name;
run;

/*problem d*/
title1 'Rolls Implicit Spread Measure (QCOM)';                                                                                                        
footnote1 ' ';                                                                                                                                  
 /* Define symbol characteristics */                                                                                                    
symbol1 color=vibg interpol=spline;                                                                                                                    
                                                                                                                                        
 /* Generate plot of two variables */ 
proc gplot data=&ticker_name;
plot s_d*date;
run;
quit;

/*problem f*/
title1 'Weighted Average of Effective Spread (QCOM)';                                                                                                        
footnote1 ' ';                                                                                                                                  
 /* Define symbol characteristics */                                                                                                    
symbol1 color=vibg interpol=spline;                                                                                                                    
                                                                                                                                        
 /* Generate plot of two variables */ 
proc gplot data=&ticker_name;
plot es_d*date;
run;
quit;

title1 'Weighted Average of Relative Effective Spread (QCOM)';                                                                                                        
footnote1 ' ';                                                                                                                                  
 /* Define symbol characteristics */                                                                                                    
symbol1 color=vibg interpol=spline;                                                                                                                    
                                                                                                                                        
 /* Generate plot of two variables */ 
proc gplot data=&ticker_name;
plot res_d*date;
run;
quit;


/*problem g*/
title1 'Price Impact Coefficient (QCOM, i=1)';                                                                                                        
footnote1 ' ';                                                                                                                                  
 /* Define symbol characteristics */                                                                                                    
symbol1 color=vibg interpol=spline;                                                                                                                    
                                                                                                                                        
 /* Generate plot of two variables */ 
proc gplot data=&ticker_name;
plot lambda1_d*date;
run;
quit;

title1 'Price Impact Coefficient (QCOM, i=2)';                                                                                                        
footnote1 ' ';                                                                                                                                  
 /* Define symbol characteristics */                                                                                                    
symbol1 color=vibg interpol=spline;                                                                                                                    
                                                                                                                                        
 /* Generate plot of two variables */ 
proc gplot data=&ticker_name;
plot lambda2_d*date;
run;
quit;

title1 'Price Reversal Coefficient (QCOM, i=1)';                                                                                                        
footnote1 ' ';                                                                                                                                  
 /* Define symbol characteristics */                                                                                                    
symbol1 color=vibg interpol=spline;                                                                                                                    
                                                                                                                                        
 /* Generate plot of two variables */ 
proc gplot data=&ticker_name;
plot psi1_d*date;
run;
quit;

title1 'Price Reversal Coefficient (QCOM, i=2)';                                                                                                        
footnote1 ' ';                                                                                                                                  
 /* Define symbol characteristics */                                                                                                    
symbol1 color=vibg interpol=spline;                                                                                                                    
                                                                                                                                        
 /* Generate plot of two variables */ 
proc gplot data=&ticker_name;
plot psi2_d*date;
run;
quit;

/**********************************************/
