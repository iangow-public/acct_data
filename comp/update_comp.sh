#!/usr/bin/env bash
cd ..
./wrds_to_pg_v2 comp.anncomp 
./wrds_to_pg_v2 comp.adsprate
./wrds_to_pg_v2 comp.co_hgic
./wrds_to_pg_v2 comp.co_ifndq
./wrds_to_pg_v2 comp.company
./wrds_to_pg_v2 comp.idx_ann
./wrds_to_pg_v2 comp.idx_index
./wrds_to_pg_v2 comp.io_qbuysell
./wrds_to_pg_v2 comp.names
./wrds_to_pg_v2 comp.secm
./wrds_to_pg_v2 comp.wrds_segmerged
./wrds_to_pg_v2 comp.spind_mth
./wrds_to_pg_v2 comp.funda --fix-missing
./wrds_to_pg_v2 comp.fundq --fix-missing
./wrds_to_pg_v2 comp.g_sec_divid
psql < comp.create_ciks.sql
psql < ~/Dropbox/pg_backup/support/permissions.sql

pg_dump --format custom --no-tablespaces --verbose --file ~/Dropbox/pg_backup/comp.backup --schema "comp" "crsp"
