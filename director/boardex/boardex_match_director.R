library(dplyr)
pg <- src_postgres()

dbGetQuery(pg$con, "SET work_mem='3GB'")

dir_chars <- tbl(pg, sql("
    WITH

    raw_data AS (
        SELECT DISTINCT boardid, directorid, director_name
        FROM boardex.director_characteristics),

    parsed_names AS (
        SELECT boardid, directorid, director_name,
            (boardex.parse_name(director_name)).*
        FROM raw_data)

    SELECT *, first_names[1] AS first_name,
        first_names[2] AS first_name_alt,
        substring(first_names[1] from 1 for 1) AS first_initial
    FROM parsed_names")) %>%
    select(-first_names) %>%
    compute() %>%
    filter()

# dbGetQuery(pg$con, "DROP TABLE IF EXISTS dir_chars")

# rs <- dbGetQuery(pg$con, "CREATE INDEX ON dir_chars (boardid, last_name)")

director <- tbl(pg, sql("
    WITH raw_data AS (
        SELECT director.equilar_id(director_id) AS equilar_id,
            director.director_id(director_id) AS equilar_director_id,
            (director.parse_name(director)).*
        FROM director.director)
    SELECT *, substring(first_name from 1 for 1) AS first_initial
    FROM raw_data"))

boardex_merge <- tbl(pg, sql("SELECT * FROM director.boardex_merge")) %>%
    select(equilar_id, boardid) %>%
    filter(!is.na(boardid))

director_merge <-
    director %>%
    inner_join(boardex_merge) %>%
    inner_join(dir_chars, by=c("boardid", "last_name")) %>%
    compute()

# First, get matches that yield unique directorid values based on last_name
unique_last_name_matches <-
    director_merge %>%
    select(equilar_id, equilar_director_id, directorid) %>%
    distinct() %>%
    group_by(equilar_id, equilar_director_id) %>%
    # summarize(n_matches=n()) %>%
    filter(n() == 1) %>%
    compute()

# Second, get matches that yield unique directorid values based on first_name
unique_first_initial_matches <-
    director_merge %>%
    anti_join(unique_last_name_matches,
              by=c("equilar_id", "equilar_director_id")) %>%
    filter(first_initial.x==first_initial.y) %>%
    select(equilar_id, equilar_director_id, directorid) %>%
    distinct() %>%
    group_by(equilar_id, equilar_director_id) %>%
    filter(n() == 1) %>%
    compute()

unique_matches <-
    unique_last_name_matches %>%
    union(unique_first_initial_matches)

# Second, get matches that yield unique directorid values based on first_name
unique_first_name_matches <-
    director_merge %>%
    anti_join(unique_matches,
              by=c("equilar_id", "equilar_director_id")) %>%
    filter(first_name.x==first_name.y) %>%
    select(equilar_id, equilar_director_id, directorid) %>%
    distinct() %>%
    group_by(equilar_id, equilar_director_id) %>%
    filter(n() == 1) %>%
    compute()

unique_matches <-
    unique_last_name_matches %>%
    union(unique_first_initial_matches) %>%
    union(unique_first_name_matches) %>%
    as.data.frame()

rs <- dbWriteTable(pg$con, c("director", "boardex_match"),
             unique_matches, row.names=FALSE,
             overwrite=TRUE)

rs <- dbGetQuery(pg$con, "
    ALTER TABLE director.boardex_match
    ADD COLUMN director_id equilar_director_id")

rs <- dbGetQuery(pg$con, "
    UPDATE director.boardex_match
    SET director_id = (equilar_id, equilar_director_id)")

# Third, look at the rest?
to_investigate <-
    director_merge %>%
    anti_join(unique_matches,
              by=c("equilar_id", "equilar_director_id")) %>%
    select(equilar_id, equilar_director_id, directorid, director_name, last_name, first_name.x) %>%
    distinct() %>%
    arrange(equilar_id, equilar_director_id, directorid, director_name, last_name, first_name.x) %>%
    collect()

to_investigate %>%
    write_csv("~/Google Drive/director_bio/manual_board_ex_matches.csv")

to_investigate %>%
    select(equilar_id, equilar_director_id) %>%
    distinct() %>%
    collect()
