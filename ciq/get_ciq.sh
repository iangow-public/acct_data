#!/bin/bash
./wrds_update.pl ciq.wrds_keydev

./wrds_update.pl --fix-missing ciq.wrds_gvkey;
./wrds_update.pl --fix-missing ciq.wrds_cusip;
./wrds_update.pl --fix-missing ciq.wrds_cik;

psql -f ciq/ciq_indexes.sql
