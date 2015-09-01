#!/usr/bin/env bash
./wrds_to_pg_v2.pl tfn.amend
./wrds_to_pg_v2.pl tfn.avgreturns
./wrds_to_pg_v2.pl tfn.rule10b5
./wrds_to_pg_v2.pl tfn.table1
./wrds_to_pg_v2.pl tfn.table2
./wrds_to_pg_v2.pl tfn.s12
./wrds_to_pg_v2.pl tfn.s12type1
./wrds_to_pg_v2.pl tfn.s12type2
./wrds_to_pg_v2.pl tfn.s34
./wrds_to_pg_v2.pl tfn.s34type1
./wrds_to_pg_v2.pl tfn.s34type2
if [ $? -eq 1 ] ; then
    pg_dump  --format custom --no-tablespaces --verbose \
        --file $PGBACKUP_DIR/tfn.backup --schema "tfn" 
fi

