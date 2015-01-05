library("RPostgreSQL")
pg <- dbConnect(PostgreSQL())

file_list <- dbGetQuery(pg, "
    SET work_mem='2GB';

    SELECT file_name, call_type, call_desc
    FROM streetevents.calls 
    WHERE file_name NOT IN (SELECT file_name FROM streetevents.speaker_data)")

rs <- dbDisconnect(pg)
parseFile <- function(file_name) {
    se.dir <- "/Volumes/2TB/data/streetevents2013"

    # Find last digit before underscore
    m <- regexpr("[0-9](?=_T)", file_name, perl=TRUE)
    last_digit <- regmatches(file_name, m)
    file_path <- file.path(se.dir, paste("dir", last_digit, sep="_"), 
                           paste0(file_name, ".xml"))
    
    system(paste("streetevents/import_speaker_data.pl", file_path),
           intern = TRUE)
}

library(parallel)
system.time({
    res <- unlist(mclapply(file_list$file_name, parseFile, mc.cores=12))
})