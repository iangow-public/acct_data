# pg_dump --host localhost --format custom --no-tablespaces -O --verbose --table "filings.original_names" | pg_restore --host iangow.me --dbname "crsp"

# DELETE  *
# FROM filings.original_names
# WHERE original_name ~ '</[^T]';

trim_dashes <- function(names) {
    new_names <- gsub("</?TABLE>", "", names)
    new_names <- gsub("(?:\302\240)", " ", new_names)
    new_names <- gsub("\\.{2,}", "", new_names)
    new_names <- gsub("^[-\\.=\\s ]+", "", new_names)
    new_names <- gsub("[-=\\s ]+$", "", new_names)

    # Scrub names with HTML tags in them
    new_names[grepl("</", new_names)] <- NA
    trimws(new_names)
}

nuke_duds <- function(name) {
    new_name <- gsub("(?i)Securities and Exchange Commission", NA, name)
    new_name <- gsub("(?i)Transition Report", NA, new_name)
}

library(dplyr)
pg <- src_postgres()

filings <- tbl(pg, sql("
    SELECT file_name, cik
    FROM filings.filings"))

original_names <- tbl(pg, sql("
    SELECT *
    FROM filings.original_names")) %>%
    inner_join(filings)

original_names_edited <-
    original_names %>%
    collect() %>%
    mutate(original_name_edited = nuke_duds(trim_dashes(original_name))) %>%
    as.data.frame()

# Push data to PostgreSQL ----
library(RPostgreSQL)
pg <- dbConnect(PostgreSQL())
dbGetQuery(pg, "DROP VIEW IF EXISTS filings.company_names")

rs <- dbWriteTable(pg, c("filings", "original_names_edited"),
             original_names_edited, overwrite=TRUE, row.names=FALSE)

rs <- dbGetQuery(pg, "
    CREATE VIEW filings.company_names AS
    SELECT DISTINCT cik::integer, upper(original_name_edited) AS company_name
    FROM filings.original_names_edited
    WHERE original_name_edited IS NOT NULL
    UNION
    SELECT DISTINCT cik::integer, upper(company_name) AS company_name
    FROM filings.filings
    WHERE form_type='10-K'
    ORDER BY cik")

dbDisconnect(pg)
