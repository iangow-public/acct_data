#!/usr/bin/env bash
perl wrds_to_pg_v2 --fix-missing audit.diroffichange --drop="match: prior: "
if [ $? -eq 1 ] ; then
    psql -f audit/fix_diroffichange.sql
fi

perl wrds_to_pg_v2 --fix-missing audit.auditnonreli --drop="match: prior: "
perl wrds_to_pg_v2 --fix-missing audit.namesauditnonreli
perl wrds_to_pg_v2 --fix-missing audit.namesdiroffichange
perl wrds_to_pg_v2 audit.namesbankrupt
perl wrds_to_pg_v2 audit.bankrupt --drop="match: closest: prior:"
perl wrds_to_pg_v2 audit.feed13cat

perl wrds_to_pg_v2 audit.feed14case
if [ $? -eq 1 ] ; then
    psql -f audit/fix_feed14case.sql
fi

perl wrds_to_pg_v2 audit.feed14party
if [ $? -eq 1 ] ; then
    psql -f audit/fix_feed14party.sql
fi

perl wrds_to_pg_v2 audit.feed17person
if [ $? -eq 1 ] ; then
    psql -f audit/fix_feed14person.sql
fi

perl wrds_to_pg_v2 audit.feed17change
perl wrds_to_pg_v2 audit.feed17del
perl wrds_to_pg_v2 audit.sholderact

Rscript audit/get_feed09filing.R
Rscript audit/get_feed09.R
Rscript audit/get_bankrupt.R
