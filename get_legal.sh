perl wrds_to_pg_v2 --fix-missing audit.diroffichange --drop="match: prior: "
perl wrds_to_pg_v2 --fix-missing audit.namesauditnonreli
perl wrds_to_pg_v2 --fix-missing audit.namesdiroffichange
perl wrds_to_pg_v2 audit.namesbankrupt

perl wrds_to_pg_v2 audit.feed13cat
perl wrds_to_pg_v2 audit.feed14case
perl wrds_to_pg_v2 audit.feed14party
perl wrds_to_pg_v2 audit.feed17person
perl wrds_to_pg_v2 audit.feed17change
perl wrds_to_pg_v2 audit.feed17del
perl wrds_to_pg_v2 audit.sholderact
psql -f audit/fix_legal.sql
psql -f audit/get_aa_data.sql