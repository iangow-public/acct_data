#!/usr/bin/env Rscript

# The code in this file updates the older version of streetevents.speaker_data
# by adding a field last_update when there is a unique file associated with a
# a given file_name (the vast majority of cases).
# The purpose of doing this is to avoid re-parsing all the underlying
# call files. For cases where there are multiple updates,
# Get a list of files that need to be processed ----

fix_table <- function(table_name) {
    library("RPostgreSQL")
    pg <- dbConnect(PostgreSQL())

    dbGetQuery(pg, paste0("
        SET work_mem='3GB';

        ALTER TABLE streetevents.", table_name, "
            ADD COLUMN last_update timestamp without time zone;"))

    dbGetQuery(pg, "
        DROP TABLE IF EXISTS streetevents.last_updates;

        CREATE TABLE streetevents.last_updates AS
        WITH unique_file_names AS (
            SELECT file_name, count(DISTINCT file_path) AS num_files
            FROM streetevents.calls
            GROUP BY file_name
            HAVING count(DISTINCT file_path)=1)

        SELECT file_name, last_update
        FROM unique_file_names
        INNER JOIN streetevents.calls
        USING (file_name);

        CREATE INDEX ON streetevents.last_updates (file_name);")

    # Note that this assumes that streetevents.calls is up to date.
    file_list <- dbGetQuery(pg, paste0("
        SET work_mem='2GB';

        SELECT file_name
        FROM streetevents.last_updates
        WHERE file_name IN
            (SELECT file_name FROM streetevents.", table_name,
                                       " WHERE last_update IS NULL)"))

    rs <- dbDisconnect(pg)

    # Create function to parse a StreetEvents XML file ----
    addLastUpdated <- function(file_name) {
        pg <- dbConnect(PostgreSQL())

        # Parse the indicated file using a Perl script
        dbGetQuery(pg, sprintf("
        UPDATE streetevents.%s AS a
        SET last_update = (
            SELECT b.last_update
            FROM streetevents.last_updates  AS b
            WHERE a.file_name=b.file_name)
        WHERE a.file_name ='%s';", table_name, file_name))

        rs <- dbDisconnect(pg)

    }

    # Apply parsing function to files ----
    library(parallel)
    system.time({
        res <- unlist(mclapply(file_list$file_name, addLastUpdated, mc.cores=12))
    })

    # Drop unneeded last_updates table ----
    pg <- dbConnect(PostgreSQL())

    dbGetQuery(pg, "DROP TABLE IF EXISTS streetevents.last_updates;")
    dbGetInfo(pg, paste0("DELETE FROM streetevents.", table_name, " WHERE last_update IS NULL"))
    rs <- dbDisconnect(pg)
}

fix_table("qa_pairs")
