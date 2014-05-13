./get_schema_alt.pl crsp msf
./get_schema_alt.pl crsp dsf
./get_schema.pl crsp dport1
./get_schema.pl crsp dseexchdates
./get_schema.pl crsp dsi
./get_schema.pl crsp mport1 
./get_schema.pl crsp msi
./get_schema.pl crsp msp500list
./get_schema.pl crsp stocknames
./get_schema_alt.pl crsp ccmxpf_linktable
./get_schema_alt.pl crsp ccmxpf_lnkhist
./get_schema_alt.pl crsp ccmxpf_lnkused
./get_schema_alt.pl crsp dsedelist
./get_schema_alt.pl crsp dsedist
./get_schema_alt.pl crsp msedelist
./get_ermport.pl
./get_erdport.pl

psql -d crsp -f crsp_make_erdport1.sql
psql -d crsp -f crsp_make_mrets.sql
psql -d crsp -f crsp_make_rets_alt.sql
psql -d crsp -f ~/Dropbox/pg_backup/support/permissions.sql 

pg_dump --host localhost --username "igow" --format custom --no-tablespaces --verbose --file ~/Dropbox/pg_backup/crsp.backup --schema "crsp" "crsp"
