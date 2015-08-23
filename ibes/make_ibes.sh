#!/usr/bin/env bash 
Rscript ibes/get_iclink.R

./wrds_to_pg_v2.pl ibes.statsum_epsus
./wrds_to_pg_v2.pl ibes.act_epsus
./wrds_to_pg_v2.pl ibes.actpsumu_epsus
./wrds_to_pg_v2.pl ibes.actu_epsus
./wrds_to_pg_v2.pl ibes.detu_epsus
if [ $? -eq 1 ] ; then
    psql -c "SET maintenance_work_mem='10GB'; CREATE INDEX ON ibes.detu_epsus (ticker, revdats)"
fi

./wrds_to_pg_v2.pl ibes.det_epsus
./wrds_to_pg_v2.pl ibes.id
./wrds_to_pg_v2.pl ibes.idsum
./wrds_to_pg_v2.pl ibes.statsum_epsus
./wrds_to_pg_v2.pl ibes.statsumu_epsus
if [ $? -eq 1 ] ; then
    psql -c "SET maintenance_work_mem='10GB'; CREATE INDEX ON ibes.statsumu_epsus (ticker, statpers)"
fi

./wrds_to_pg_v2.pl ibes.surpsum

pg_dump  --format custom --no-tablespaces --verbose \
    --file $PGBACKUP_DIR/ibes.backup --schema "ibes" 
