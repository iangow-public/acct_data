amatch <- function(str1, str2) {
    if (str1=="" | str2 =="") return(NA)
    agrepl(str1, str2) | agrepl(str2, str1)
}

library("RPostgreSQL")
pg <- dbConnect(PostgreSQL())
sql <- paste(readLines("streetevents/ticker_mismatches.sql"),
             collapse="\n")

sample <- dbGetQuery(pg, sql)
dbDisconnect(pg)

dim(unique(subset(sample, diff_name, ticker)))