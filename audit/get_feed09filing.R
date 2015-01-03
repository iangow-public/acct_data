library("RPostgreSQL")
pg <- dbConnect(PostgreSQL())

dbGetQuery(pg, "
    DROP TABLE IF EXISTS audit.feed09filing;
    DROP TABLE IF EXISTS audit.disclosure_text;
    CREATE TABLE audit.disclosure_text 
           (res_filing_key integer, disclosure_text text);")

dbDisconnect(pg)

system('perl ./wrds_to_pg_v2 audit.feed09filing --drop="disclosure_text file_date_num"')

sas_code <- "
    libname pwd '/sastemp6';

    options nosource nonotes;
      
    proc sql;
        CREATE TABLE pwd.disclosure_text AS
        SELECT res_filing_key, disclosure_text
        FROM audit.feed09filing;
    quit;

    proc export data=pwd.disclosure_text 
            outfile=stdout dbms=csv;
    run;"


  
# Use PostgreSQL's COPY function to get data into the database
cmd = paste0("echo \"", sas_code, "\" | ",
            "ssh -C iangow@wrds.wharton.upenn.edu 'sas -stdio -noterminal' 2>/dev/null | ",
            "psql -d crsp -c \"COPY audit.disclosure_text FROM STDIN CSV HEADER ENCODING 'latin1' \"")

system(cmd)

convertToBoolean <- function(var) {
    library("RPostgreSQL")
    pg <- dbConnect(PostgreSQL())
    sql <- paste0("ALTER TABLE audit.feed09filing ALTER COLUMN ",
              var, " TYPE boolean USING ", var, "=1")
    dbGetQuery(pg, sql)
    dbDisconnect(pg)
}

convertToInteger <- function(var) {
    library("RPostgreSQL")
    pg <- dbConnect(PostgreSQL())
    sql <- paste0("ALTER TABLE audit.feed09filing ALTER COLUMN ",
              var, " TYPE integer USING ", var)
    dbGetQuery(pg, sql)
    dbDisconnect(pg)
}


logical.vars <- c("res_accounting", "res_fraud", "res_cler_err", 
                  "res_non_fin", "res_adverse", "res_improves",
                  "res_sec_invest", "res_other") 
for (var in logical.vars) convertToBoolean(var)

integer.vars <- c("res_filing_key", "res_notify_key")
for (var in integer.vars) convertToInteger(var)

pg <- dbConnect(PostgreSQL())
dbGetQuery(pg,"
    ALTER TABLE audit.feed09filing ADD COLUMN disclosure_text text;

    UPDATE audit.feed09filing AS a SET disclosure_text=b.disclosure_text
           FROM audit.disclosure_text AS b
           WHERE a.res_filing_key=b.res_filing_key;
           
    DROP TABLE audit.disclosure_text")


