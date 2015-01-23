library("RPostgreSQL")

pg <- dbConnect(PostgreSQL())

if (!dbExistsTable(pg, c("streetevents", "qa_pairs"))) {
    dbGetQuery(pg, "
        DROP TABLE IF EXISTS streetevents.qa_pairs;
    
        CREATE TABLE streetevents.qa_pairs
        (
          file_name text,
          questioner text,
          questions text[],
          question_nums integer[],
          answerers text[],
          answer_nums integer[],
          answers text[],
          answerer_roles text[]
        );
                   
        CREATE INDEX ON streetevents.qa_pairs (file_name);
        
        GRANT SELECT ON streetevents.qa_pairs TO personality_access;")
}

file_list <- dbGetQuery(pg, "
    SELECT DISTINCT file_name
    FROM streetevents.speaker_data AS a
    INNER JOIN streetevents.calls
    USING (file_name)
    WHERE call_type=1 AND 
        file_name NOT IN (SELECT file_name FROM streetevents.qa_pairs)")

rs <- dbDisconnect(pg)

addQAPairs <- function(file_name) {
    library("RPostgreSQL")
    sql <- paste(readLines("streetevents/create_qa_pairs.sql"), collapse="\n")

    pg <- dbConnect(PostgreSQL())    
    dbGetQuery(pg, sprintf(sql, file_name))
    dbDisconnect(pg)
}

library(parallel)
system.time(res <- unlist(mclapply(file_list$file_name, addQAPairs, mc.cores=12)))

