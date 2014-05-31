../wrds_to_pg crsp.msf --fix-missing
../wrds_to_pg crsp.dsf --fix-missing
../wrds_to_pg crsp.dport1
../wrds_to_pg crsp.dseexchdates
../wrds_to_pg crsp.dsi
../wrds_to_pg crsp.mport1 
../wrds_to_pg crsp.msi
../wrds_to_pg crsp.msp500list
../wrds_to_pg crsp.stocknames
../wrds_to_pg crsp.ccmxpf_linktable --fix-missing
../wrds_to_pg crsp.ccmxpf_lnkhist --fix-missing
../wrds_to_pg crsp.ccmxpf_lnkused --fix-missing
../wrds_to_pg crsp.dsedelist --fix-missing
../wrds_to_pg crsp.dsedist --fix-missing
../wrds_to_pg crsp.msedelist --fix-missing
../get_ermport.pl
../get_erdport.pl

psql -f crsp_make_erdport1.sql
psql -f crsp_make_mrets.sql
psql -f crsp_make_rets_alt.sql
psql -f ../permissions.sql 

pg_dump --format custom --no-tablespaces --verbose --file ~/Dropbox/pg_backup/crsp.backup --schema "crsp"
