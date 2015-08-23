#!/usr/bin/env bash
./wrds_to_pg_v2.pl comp.anncomp 
./wrds_to_pg_v2.pl comp.adsprate
./wrds_to_pg_v2.pl comp.co_hgic
./wrds_to_pg_v2.pl comp.co_ifndq
./wrds_to_pg_v2.pl comp.company
./wrds_to_pg_v2.pl comp.idx_ann
./wrds_to_pg_v2.pl comp.idx_index
./wrds_to_pg_v2.pl comp.io_qbuysell
./wrds_to_pg_v2.pl comp.names
./wrds_to_pg_v2.pl comp.secm
./wrds_to_pg_v2.pl comp.wrds_segmerged
./wrds_to_pg_v2.pl comp.spind_mth
./wrds_to_pg_v2.pl comp.funda --fix-missing
./wrds_to_pg_v2.pl comp.fundq --fix-missing
./wrds_to_pg_v2.pl comp.g_sec_divid
psql < comp/create_ciks.sql
psql < comp/comp_indexes.sql
psql < pg/permissions.sql

pg_dump --format custom --no-tablespaces --verbose --file \
    $PGBACKUP_DIR/comp.backup --schema "comp" "crsp"
