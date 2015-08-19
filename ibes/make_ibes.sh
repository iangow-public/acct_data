#!/usr/bin/env bash 
R CMD BATCH get_iclink.R

./wrds_to_pg_v2 ibes.statsum_epsus
./wrds_to_pg_v2 ibes.act_epsus
./wrds_to_pg_v2 ibes.actpsumu_epsus
./wrds_to_pg_v2 ibes.actu_epsus
./wrds_to_pg_v2 ibes.detu_epsus
if [ $? -eq 1 ] ; then
    psql -c "SET maintenance_work_mem='10GB'; CREATE INDEX ON ibes.detu_epsus (ticker, revdats)"
fi

./wrds_to_pg_v2 ibes.det_epsus
./wrds_to_pg_v2 ibes.id
./wrds_to_pg_v2 ibes.idsum
./wrds_to_pg_v2 ibes.statsum_epsus
./wrds_to_pg_v2 ibes.statsumu_epsus
if [ $? -eq 1 ] ; then
    psql -c "SET maintenance_work_mem='10GB'; CREATE INDEX ON ibes.statsumu_epsus (ticker, statpers)"
fi

./wrds_to_pg_v2 ibes.surpsum

pg_dump  --format custom --no-tablespaces --verbose --file ~/Dropbox/pg_backup/ibes.backup --schema "ibes" "crsp"
