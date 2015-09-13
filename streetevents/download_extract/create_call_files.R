#!/usr/bin/env Rscript

# Code to generate a list of files in the StreetEvents directory
# and post to PostgreSQL.

library("RPostgreSQL")
library("parallel")

getSHA1 <- function(file_name) {
    library("digest")
    digest(file=file_name, algo="sha1")
}


# Get a list of files
streetevent.dir <- file.path(Sys.getenv("EDGAR_DIR"), "streetevents_project")
full_path <- list.files(streetevent.dir,
                   pattern="*_T.xml", recursive = TRUE,
                   include.dirs=FALSE, full.names = TRUE)

file.list <- data.frame(full_path, stringsAsFactors=FALSE)
file.list$mtime <- file.mtime(full_path)
file.list$file_path <-
    gsub(paste0(streetevent.dir, "/"), "", file.list$full_path, fixed = TRUE)

library("RPostgreSQL")
pg <- dbConnect(PostgreSQL())

new_table <- !dbExistsTable(pg, c("streetevents", "calls"))
if (!new_table) {
    rs <- dbWriteTable(pg, c("streetevents", "call_files_temp"),
                       file.list[, c("file_path", "mtime")],
                       overwrite=TRUE, row.names=FALSE)

    dbGetQuery(pg, "CREATE INDEX ON streetevents.call_files_temp (file_path, mtime)")

    new_files <- dbGetQuery(pg, "
        SELECT file_path, mtime
        FROM streetevents.call_files_temp
        EXCEPT
        SELECT file_path, mtime
        FROM streetevents.call_files")

    if (dim(new_files)[1]>0) {
        new_files <- merge(new_files, file.list, by=c("file_path", "mtime"))
    }
} else {
    new_files <- file.list
}

if (dim(new_files)[1]>0) {
    file_info <- file.info(new_files$full_path)

    new_files$file_size <- file_info$size
    new_files$ctime <- file_info$ctime
    new_files$file_name <- gsub("\\.xml", "", basename(new_files$file_path))

    system.time({
        new_files$sha1 <- unlist(lapply(new_files$full_path, getSHA1))
    })

    new_files <- subset(new_files, select=c(file_path, file_size, mtime, ctime, file_name, sha1))

    rs <- dbWriteTable(pg, c("streetevents", "call_files"), new_files,
                           append=!new_table, row.names=FALSE)

    if (!new_table) dbGetQuery(pg, "DROP TABLE streetevents.call_files_temp")
    if (new_table) dbGetQuery(pg, "CREATE INDEX ON streetevents.call_files (file_name, mtime)")
}

rs <- dbDisconnect(pg)
