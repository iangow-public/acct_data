require(RCurl)

getSheetData = function(key, gid=NULL) {
  library(RCurl)
  url <- paste0("https://docs.google.com/spreadsheets/d/", key,
                "/export?format=csv&id=", key, if (is.null(gid)) "" else paste0("&gid=", gid),
                "&single=true")
  csv_file <- getURL(url, verbose=FALSE)
  the_data <- read.csv(textConnection(csv_file), as.is=TRUE)
  return( the_data )
}

key <- "14F6zjJQZRsf5PonOfZ0GJrYubvx5e_eHMV_hCGe42Qg"
gid <- 1613221647
permnos <- getSheetData(key, gid)

pg_comment <- function(table, comment) {
    library(RPostgreSQL)
    pg <- dbConnect(PostgreSQL())
    sql <- paste0("COMMENT ON TABLE ", table, " IS '",
                  comment, " ON ", Sys.time() , "'")
    rs <- dbGetQuery(pg, sql)
    dbDisconnect(pg)
}

library(RPostgreSQL)
pg <- dbConnect(PostgreSQL())

rs <- dbWriteTable(pg, c("streetevents", "manual_permno_matches"),
                   permnos,
                   overwrite=TRUE, row.names=FALSE)

rs <- dbGetQuery(pg, "
    ALTER TABLE streetevents.manual_permno_matches
    OWNER TO personality_access")

dbGetQuery(pg, "
  DELETE 
  FROM streetevents.manual_permno_matches   
  WHERE file_name IN (
    SELECT file_name
    FROM streetevents.manual_permno_matches
    GROUP BY file_name
    HAVING count(DISTINCT permno)>1) AND comment != 'Fix by Nastia/Vincent in January 2015'")

rs <- dbDisconnect(pg)

rs <- pg_comment("streetevents.manual_permno_matches",
           paste0("CREATED USING import_manual_permno_matches.R ON ", Sys.time()))
