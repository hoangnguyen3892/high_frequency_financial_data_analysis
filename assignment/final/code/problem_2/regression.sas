libname estim 'C:\Users\Hoang\Dropbox\Final\data';

%let ticker_name = QCOM;

data &ticker_name;
set estim.estim_&ticker_name;
r_d = log(p_d/lag(p_d));
w_d = log(m_d/lag(m_d));
lag_y = lag(y_d);
lag_z = lag(z_d);
log_dv = log(DV_d);
log_p = log(p_d);
run;

proc reg data=&ticker_name;
model1: model r_d = y_d lag_y;
model2: model r_d = z_d lag_z;
model3: model w_d = y_d lag_y;
model4: model w_d = z_d lag_z;
model5: model s_d = log_dv sigma_d log_p;
model6: model es_d = log_dv sigma_d log_p;
model7: model res_d = log_dv sigma_d log_p;
run;quit;

