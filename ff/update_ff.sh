#!/usr/bin/env bash 
psql -c "CREATE SCHEMA IF NOT EXISTS ff"

Rscript ff/import_bbl_16.R
Rscript ff/get_ff_ind.R
Rscript ff/get_ff_factors_daily.R
Rscript ff/get_ff_factors_monthly.R
Rscript ff/import_be_beme.R
Rscript ff/get_ff_port_rets_monthly.R
Rscript ff/get_ff_port_rets.R

psql < pg/permissions.sql
