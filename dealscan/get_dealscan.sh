cd ..
./wrds_to_pg_v2 dealscan.borrowerbase
./wrds_to_pg_v2 dealscan.company
./wrds_to_pg_v2 dealscan.currfacpricing
./wrds_to_pg_v2 dealscan.dbo_df_fac_dates_data
./wrds_to_pg_v2 dealscan.dealamendment
./wrds_to_pg_v2 dealscan.facility
./wrds_to_pg_v2 dealscan.facilityamendment
./wrds_to_pg_v2 dealscan.facilitydates
./wrds_to_pg_v2 dealscan.facilityguarantor
./wrds_to_pg_v2 dealscan.facilitypaymentschedule
./wrds_to_pg_v2 dealscan.facilitysecurity
./wrds_to_pg_v2 dealscan.facilitysponsor
./wrds_to_pg_v2 dealscan.financialcovenant
./wrds_to_pg_v2 dealscan.financialratios
./wrds_to_pg_v2 dealscan.lendershares
./wrds_to_pg_v2 dealscan.link_table
./wrds_to_pg_v2 dealscan.lins
./wrds_to_pg_v2 dealscan.marketsegment
./wrds_to_pg_v2 dealscan.networthcovenant
./wrds_to_pg_v2 dealscan.organizationtype
./wrds_to_pg_v2 dealscan.package
./wrds_to_pg_v2 dealscan.performancepricing
./wrds_to_pg_v2 dealscan.performancepricingcomments
./wrds_to_pg_v2 dealscan.sublimits

pg_dump --format custom --no-tablespaces --verbose --file ~/Dropbox/pg_backup/dealscan.backup --schema "dealscan" "crsp"