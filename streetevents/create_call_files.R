#!/usr/bin/env Rscript

# Code to generate a list of files in the StreetEvents directory
# and post to PostgreSQL.

library("RPostgreSQL")

getSHA1 <- function(file_name) {
    library("digest")
    digest(file=file_name, algo="sha1")
}

pg <- dbConnect(PostgreSQL())

streetevent.dir <- "/Volumes/2TB/data/streetevents"
file_path <- list.files(streetevent.dir,
                   pattern="*_T.xml", recursive = TRUE,
                   include.dirs=FALSE, full.names = TRUE)
file_info <- file.info(file_path)
file.list <- data.frame(file_path, stringsAsFactors=FALSE)

file.list$mtime <- file_info$mtime
file.list$ctime <- file_info$ctime
file.list$file_name <- gsub("\\.xml", "", basename(file.list$file_path))

system.time({
    file.list$sha1 <- unlist(mclapply(file.list$file_path, 
                                      getSHA1, mc.cores=12))
})

library("RPostgreSQL")
pg <- dbConnect(PostgreSQL())

rs <- dbWriteTable(pg, c("streetevents", "call_files"), file.list,
             overwrite=TRUE, row.names=FALSE)

rs <- dbGetQuery(pg, "CREATE INDEX ON streetevents.call_files (file_name) ")

rs <- dbDisconnect(pg)
