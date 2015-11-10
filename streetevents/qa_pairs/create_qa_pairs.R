library("RPostgreSQL")

pg <- dbConnect(PostgreSQL())

dbSendQuery(pg, "CREATE LANGUAGE plpythonu")
rs <- dbSendQuery(pg, "
    CREATE OR REPLACE FUNCTION array_min(an_array integer[])
        RETURNS integer AS
    $BODY$
        if an_array is None:
            return None
        return min(an_array)
    $BODY$ LANGUAGE plpythonu")

if (!dbExistsTable(pg, c("streetevents", "qa_pairs"))) {
    dbGetQuery(pg, "
        DROP TABLE IF EXISTS streetevents.qa_pairs;

        CREATE TABLE streetevents.qa_pairs
        (
          file_name text,
          last_update timestamp without time zone,
          answer_nums integer[],
          question_nums integer[]
        );

        CREATE INDEX ON streetevents.qa_pairs (file_name, last_update);

        GRANT SELECT ON streetevents.qa_pairs TO personality_access;")
}

file_list <- dbGetQuery(pg, "
    SET work_mem='3GB';

    SELECT DISTINCT file_name, last_update
    FROM streetevents.calls AS a
    WHERE call_type=1 AND
        (file_name, last_update) NOT IN
            (SELECT file_name, last_update
             FROM streetevents.qa_pairs)")

rs <- dbDisconnect(pg)

addQAPairs <- function(file_name) {
    library("RPostgreSQL")
    sql <- paste(readLines("streetevents/qa_pairs/create_qa_pairs.sql"), collapse="\n")

    pg <- dbConnect(PostgreSQL())
    dbGetQuery(pg, sprintf(sql, file_name, file_name))
    dbDisconnect(pg)
}

library(parallel)
system.time(res <- unlist(mclapply(file_list$file_name, addQAPairs, mc.cores=8)))

