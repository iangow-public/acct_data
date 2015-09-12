#!/bin/bash
./wrds_to_pg_v2.pl ciq.wrds_keydev

./wrds_to_pg_v2.pl --fix-missing ciq.wrds_gvkey;
./wrds_to_pg_v2.pl --fix-missing ciq.wrds_cusip;
./wrds_to_pg_v2.pl --fix-missing ciq.wrds_cik;

psql -f ciq/ciq_indexes.sql
