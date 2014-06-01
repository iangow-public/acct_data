cd ..
./wrds_to_pg_v2 crsp.msf --fix-missing
./wrds_to_pg_v2 crsp.dsf --fix-missing
./wrds_to_pg_v2 crsp.dseexchdates
./wrds_to_pg_v2 crsp.dsi
./wrds_to_pg_v2 crsp.msi
./wrds_to_pg_v2 crsp.msp500list
./wrds_to_pg_v2 crsp.stocknames
./wrds_to_pg_v2 crsp.ccmxpf_linktable --fix-missing
./wrds_to_pg_v2 crsp.ccmxpf_lnkhist --fix-missing
./wrds_to_pg_v2 crsp.ccmxpf_lnkused --fix-missing
./wrds_to_pg_v2 crsp.dsedelist --fix-missing
./wrds_to_pg_v2 crsp.dsedist --fix-missing
./wrds_to_pg_v2 crsp.msedelist --fix-missing
./wrds_to_pg_v2 crsp.fund_names --fix-missing

./wrds_to_pg_v2 crsp.dport1
./wrds_to_pg_v2 crsp.mport1 
cd crsp
./get_ermport.pl
./get_erdport.pl

psql -f crsp_make_erdport1.sql
psql -f crsp_make_ermport1.sql
psql -f crsp_make_mrets.sql
psql -f crsp_make_rets_alt.sql
psql -f ./permissions.sql 

pg_dump --format custom --no-tablespaces --verbose --file ~/Dropbox/pg_backup/crsp.backup --schema "crsp"
