bbl_16 <- read.csv("http://iangow.me/~igow/data/bbl_16.csv", as.is=TRUE, row.names=NULL)

# Connect to my database
library(RPostgreSQL)
drv <- dbDriver("PostgreSQL")
pg <- dbConnect(drv, dbname = "crsp", host="localhost", port=5432)
dbWriteTable(pg, c("ff", "bbl_16"), bbl_16, overwrite=TRUE, row.names=FALSE)

rs <- dbGetQuery(pg, "ALTER TABLE ff.bbl_16 OWNER TO activism")
sql <- paste0("
    COMMENT ON TABLE ff.bbl_16 IS
    'CREATED USING get_bbl_16.R ON ", Sys.time() , "';")
rs <- dbGetQuery(pg, paste(sql, collapse="\n"))

rs <- dbGetQuery(pg, "VACUUM ff.bbl_16")

rs <- dbDisconnect(pg)