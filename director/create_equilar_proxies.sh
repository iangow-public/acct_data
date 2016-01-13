#!/usr/bin/env bash
psql -f director/create_equilar_proxies.sql
R CMD BATCH import_gvkey_matches.R
