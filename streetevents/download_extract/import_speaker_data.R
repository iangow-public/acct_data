#!/usr/bin/env Rscript

# Get a list of files that need to be processed ----

library("RPostgreSQL")
pg <- dbConnect(PostgreSQL())

if (!dbExistsTable(pg, c("streetevents", "speaker_data"))) {
    dbGetQuery(pg, "
        CREATE TABLE streetevents.speaker_data
            (
              file_name text,
              last_update timestamp without time zone,
              speaker_name text,
              employer text,
              role text,
              speaker_number integer,
              context text,
              speaker_text text,
              language text
            );

        SET maintenance_work_mem='3GB';

        CREATE INDEX ON streetevents.speaker_data (file_name, last_update);
        CREATE INDEX ON streetevents.speaker_data (file_name);")
}

# Note that this assumes that streetevents.calls is up to date.
file_list <- dbGetQuery(pg, "
    SET work_mem='2GB';

    WITH

    latest_mtime AS (
        SELECT a.file_name, last_update,
            max(DISTINCT mtime) AS mtime
        FROM streetevents.calls AS a
        INNER JOIN streetevents.call_files
        USING (file_path)
        GROUP BY a.file_name, last_update),

    calls AS (
        SELECT file_path, file_name, last_update
        FROM streetevents.calls
        INNER JOIN latest_mtime
        USING (file_name, last_update))

    SELECT DISTINCT file_path
    FROM calls
    WHERE (file_name, last_update) NOT IN
        (SELECT file_name, last_update FROM streetevents.speaker_data)")

rs <- dbDisconnect(pg)

# Create function to parse a StreetEvents XML file ----
parseFile <- function(file_path) {

    # Parse the indicated file using a Perl script
    system(paste("streetevents/download_extract/import_speaker_data.pl", file_path),
           intern = TRUE)
}

# Apply parsing function to files ----
library(parallel)
system.time({
    res <- unlist(mclapply(file_list$file_path, parseFile, mc.cores=12))
})
