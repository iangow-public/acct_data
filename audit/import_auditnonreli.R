# st auditnonreli.sas7bdat auditnonreli.csv; gzip auditnonreli.csv
feed09filing <- read.csv("~/Downloads/auditnonreli.csv.gz", stringsAsFactors=FALSE,
                 fileEncoding="ISO-8859-1") 

names(feed09filing) <- tolower(names(feed09filing))
names(feed09filing) <- gsub("^res_(period_aud|other_rescat)_fkey$", "res_\\1_fkey_list", 
                            names(feed09filing))


# Delete unncessary variables
unnecessary <- c(grep("^(prior|match)(fy|qu)", names(feed09filing), value=TRUE), 
                 grep("(title(_list)?|date_num)$", names(feed09filing), value=TRUE),
                 grep("res_(period|begin|end)_aud_names?", names(feed09filing), value=TRUE),
                 "file_date_aud_name")
for (i in unnecessary) feed09filing[, i] <- NULL

logical.vars <- c("res_accounting", "res_fraud", "res_adverse", "res_improves",
                  "res_other", "res_sec_invest", "res_cler_err")
for (i in logical.vars) feed09filing[,i] <- as.logical(feed09filing[,i])

date.vars <- c("res_begin_date", "file_date", "res_end_date")
for (i in date.vars) {
    feed09filing[, i]<- as.Date(feed09filing[, i], format="%m/%d/%Y")
}

blanks_to_null <- function(vector) {
    vector[vector==""] <- NA
    vector
}
array.vars <- c(grep("fkey_list$", names(feed09filing), value=TRUE))

for (i in array.vars) {
    feed09filing[,i]<- blanks_to_null( feed09filing[,i])
}

feed09filing$file_accepted <- 
    as.POSIXct(feed09filing$file_accepted,
               format="%m/%d/%Y %H:%M:%S", tz="America/New_York")

feed09filing$disc_text <- gsub("(\u0092|\u0093|\u0094)", "'", feed09filing$disc_text)
feed09filing$disc_text <- gsub("\u0095", "\u2022", feed09filing$disc_text)
feed09filing$disc_text <- gsub("\u0096", "\u2013", feed09filing$disc_text)
feed09filing$disc_text <- gsub("\u0097", "\u2014", feed09filing$disc_text)

library(RPostgreSQL)
pg <- dbConnect(PostgreSQL())
rs <- dbWriteTable(pg, c("audit", "feed09filing"), feed09filing,
                   row.names=FALSE, overwrite=TRUE)


for (i in array.vars) {
    new_name <- gsub("_list$", "s", i)
    dbGetQuery(pg, paste("ALTER TABLE audit.feed09filing ADD COLUMN", new_name, "integer[]"))
    sql <- paste0("UPDATE audit.feed09filing SET ", new_name, 
                "=array_remove(regexp_split_to_array(", i, ", '\\|'), '')::integer[]")
    dbGetQuery(pg, sql)
    sql <- paste("ALTER TABLE audit.feed09filing DROP COLUMN", i)
    dbGetQuery(pg, sql)
}

rs <- dbGetQuery(pg, "
    CREATE INDEX ON audit.feed09filing (company_fkey);
    CREATE INDEX ON audit.feed09filing (file_date);
    GRANT SELECT ON audit.feed09filing TO crsp_plus;")
rs <- dbDisconnect(pg)



