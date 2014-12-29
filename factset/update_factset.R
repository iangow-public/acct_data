runSQL <- function(sql_file) {
    library(RPostgreSQL)
    pg <- dbConnect(PostgreSQL())
    sql <- paste(readLines(sql_file), collapse="\n")
    rs <- dbGetQuery(pg, sql)
    dbDisconnect(pg)
    return(rs)
}

temp <- runSQL("factset/update_factset.sql")

write.csv(temp, file="~/Google Drive/activism/data/campaign_ids.csv")
