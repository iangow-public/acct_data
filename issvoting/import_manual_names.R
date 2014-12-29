# Get corrected data on board-related activism from Google Sheets document ----
require(RCurl)
csv_file <- getURL(paste0("https://docs.google.com/spreadsheet/pub?",
                         "key=0AuGYuDecQAVTdEc5WmhEWVY1ZWF1cjlxVFJEaHRzUFE",
                         "&output=csv"),
                   verbose=FALSE)
manual_names <- read.csv(textConnection(csv_file), as.is=TRUE)

for (i in names(manual_names)) class(manual_names[,i]) <- "character"

library(RPostgreSQL)
pg <- dbConnect(PostgreSQL())

rs <- dbWriteTable(pg, name=c("issvoting", "manual_names"), manual_names,
                   overwrite=TRUE, row.names=FALSE)

rs <- dbGetQuery(pg, "ALTER TABLE issvoting.manual_names OWNER TO activism")


sql <- paste("
  COMMENT ON TABLE issvoting.manual_names IS
    'CREATED USING import_manual_names ON ", Sys.time() , "';", sep="")
rs <- dbGetQuery(pg, sql)
dbDisconnect(pg)

