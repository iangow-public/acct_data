#!/usr/bin/env bash
psql -f director/create_ciks.sql
Rscript director/import_mult_ids.R
psql -f director/create_db_merge.sql
