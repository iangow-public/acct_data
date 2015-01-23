library("RPostgreSQL")

pg <- dbConnect(PostgreSQL())

if(!dbExistsTable(pg, c("streetevents", "nerdata"))) {
    dbGetQuery(pg, "
        CREATE TABLE streetevents.nerdata 
            (file_name text, question_num integer, ner_tags jsonb);

        CREATE INDEX ON streetevents.nerdata (file_name);
    
        ALTER TABLE streetevents.nerdata OWNER TO personality_access;")
}

file_list <- dbGetQuery(pg, "
    SELECT DISTINCT file_name
    FROM streetevents.qa_pairs
    WHERE file_name NOT IN (SELECT file_name FROM streetevents.nerdata)")

rs <- dbDisconnect(pg)

addNERdata <- function(file_name) {
    library("RPostgreSQL")
    sql <- "
        INSERT INTO streetevents.nerdata 
        WITH question_nums AS (
            SELECT file_name, unnest(question_nums) AS question_num,
                unnest(questions) AS question
            FROM streetevents.qa_pairs
            WHERE file_name='%s')

        SELECT file_name, question_num,
                findner(question) 
        FROM question_nums"

    pg <- dbConnect(PostgreSQL())    
    dbGetQuery(pg, sprintf(sql, file_name))
    dbDisconnect(pg)
}

library(parallel)
system.time(res <- unlist(mclapply(file_list$file_name[1:10], addNERdata, mc.cores=6)))

