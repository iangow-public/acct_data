../get_schema.pl dealscan borrowerbase
../get_schema.pl dealscan company
../get_schema.pl dealscan currfacpricing
../get_schema.pl dealscan dbo_df_fac_dates_data
../get_schema.pl dealscan dealamendment
../get_schema.pl dealscan facility
../get_schema.pl dealscan facilityamendment
../get_schema.pl dealscan facilitydates
../get_schema.pl dealscan facilityguarantor
../get_schema.pl dealscan facilitypaymentschedule
../get_schema.pl dealscan facilitysecurity
../get_schema.pl dealscan facilitysponsor
../get_schema.pl dealscan financialcovenant
../get_schema.pl dealscan financialratios
../get_schema.pl dealscan lendershares
../get_schema.pl dealscan link_table
../get_schema.pl dealscan lins
../get_schema.pl dealscan marketsegment
../get_schema.pl dealscan networthcovenant
../get_schema.pl dealscan organizationtype
../get_schema.pl dealscan package
../get_schema.pl dealscan performancepricing
../get_schema.pl dealscan performancepricingcomments
../get_schema.pl dealscan sublimits

pg_dump --host localhost --username "igow" --format custom --no-tablespaces --verbose --file ~/Dropbox/pg_backup/dealscan.backup --schema "dealscan" "crsp"
