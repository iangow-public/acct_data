#!/usr/bin/env Rscript
# Get a list of files that need to be processed ----

# Note that this assumes that streetevents.calls is up to date.
library("RPostgreSQL")
pg <- dbConnect(PostgreSQL())

if (!dbExistsTable(pg, c("streetevents", "calls"))) {
    dbGetQuery(pg, "
        CREATE TABLE streetevents.calls
            (
              file_path text,
              file_name text,
              ticker text,
              co_name text,
              call_desc text,
              call_date timestamp without time zone,
              city text,
              call_type integer,
              last_update timestamp without time zone
            );

        CREATE INDEX ON streetevents.calls (file_name);")
}

file_list <- dbGetQuery(pg, "
    SET work_mem='2GB';

    SELECT *
    FROM streetevents.call_files
    WHERE file_name NOT IN (SELECT file_name FROM streetevents.calls)")

rs <- dbDisconnect(pg)

# Create function to parse a StreetEvents XML file ----
parseFile <- function(file_path) {

    # Parse the indicate file using a Perl script
    system(paste("streetevents/download_extract/parse_xml_files.pl", file_path),
           intern = TRUE)
}

# Apply parsing function to files ----
library(parallel)
system.time({
    res <- unlist(mclapply(file_list$file_path, parseFile, mc.cores=8))
})
