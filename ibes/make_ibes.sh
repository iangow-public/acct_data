#!/usr/bin/env bash
Rscript ibes/get_iclink.R

./wrds_update.pl ibes.statsum_epsus
./wrds_update.pl ibes.act_epsus
./wrds_update.pl ibes.actpsumu_epsus
./wrds_update.pl ibes.actu_epsus
./wrds_update.pl ibes.detu_epsus
if [ $? -eq 1 ] ; then
    psql -c "SET maintenance_work_mem='10GB'; CREATE INDEX ON ibes.detu_epsus (ticker, revdats)"
fi

./wrds_update.pl ibes.det_epsus
./wrds_update.pl ibes.id
./wrds_update.pl ibes.idsum
./wrds_update.pl ibes.statsum_epsus
./wrds_update.pl ibes.statsumu_epsus
if [ $? -eq 1 ] ; then
    psql -c "SET maintenance_work_mem='10GB'; CREATE INDEX ON ibes.statsumu_epsus (ticker, statpers)"
fi

./wrds_update.pl ibes.surpsum

pg_dump  --format custom --no-tablespaces --verbose \
    --file $PGBACKUP_DIR/ibes.backup --schema "ibes"
