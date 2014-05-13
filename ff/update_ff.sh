R CMD BATCH --slave get_bbl_16.R
R CMD BATCH --slave get_ff_ind.R
R CMD BATCH --slave get_ff_factors_daily.R
R CMD BATCH --slave get_ff_factors_monthly.R
R CMD BATCH --slave import_be_beme.R
R CMD BATCH --slave get_ff_port_rets_monthly.R
R CMD BATCH --slave get_ff_port_rets.R
