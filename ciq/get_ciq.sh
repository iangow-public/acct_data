#!/bin/bash
./wrds_to_pg_v2 ciq.wrds_keydev

./wrds_to_pg_v2 --fix-missing ciq.wrds_cusip;
./wrds_to_pg_v2 --fix-missing ciq.wrds_cik;

psql -f ciq/ciq_indexes.sql
