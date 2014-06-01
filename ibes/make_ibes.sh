R CMD BATCH get_iclink.R

cd ..
./wrds_to_pg_v2 ibes.statsum_epsus
./wrds_to_pg_v2 ibes.act_epsus
./wrds_to_pg_v2 ibes.actpsumu_epsus
./wrds_to_pg_v2 ibes.actu_epsus
./wrds_to_pg_v2 ibes.detu_epsus
./wrds_to_pg_v2 ibes.id
./wrds_to_pg_v2 ibes.idsum
./wrds_to_pg_v2 ibes.statsum_epsus
./wrds_to_pg_v2 ibes.statsumu_epsus
./wrds_to_pg_v2 ibes.surpsum

cd ibes
psql < index_ibes.sql
pg_dump  --format custom --no-tablespaces --verbose --file ~/Dropbox/pg_backup/ibes.backup --schema "ibes" "crsp"
