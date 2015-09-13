bbl_16 <- read.csv("ff/bbl_16.csv", as.is=TRUE, row.names=NULL)

# Connect to my database
library(RPostgreSQL)
pg <- dbConnect(PostgreSQL())
dbWriteTable(pg, c("ff", "bbl_16"), bbl_16, overwrite=TRUE, row.names=FALSE)

sql <- paste0("
    COMMENT ON TABLE ff.bbl_16 IS
    'CREATED USING get_bbl_16.R ON ", Sys.time() , "';")
rs <- dbGetQuery(pg, paste(sql, collapse="\n"))

rs <- dbGetQuery(pg, "VACUUM ff.bbl_16")

rs <- dbDisconnect(pg)
