library(dplyr)

pg <- src_postgres()

director_matches <- tbl(pg, sql("
    SELECT *
    FROM director.director_matches"))

director <- tbl(pg, sql(
    "SELECT director.equilar_id(director_id),
    director.director_id(director_id) AS equilar_director_id, *
    FROM director.director")) %>%
    rename(director_id_original = director_id) %>%
    rename(director_id = equilar_director_id) %>%
    compute()

problem_cases <- director_matches %>%
    select(directorid, executive_id) %>%
    distinct() %>%
    group_by(directorid) %>%
    summarize(count = n())%>%
    filter(count > 1) %>%
    inner_join(director_matches) %>%
    select(directorid, executive_id, equilar_id, director_id) %>%
    distinct() %>%
    arrange(directorid, executive_id, equilar_id, director_id)

problem_cases %>%
    as.data.frame() %>%
    write_csv("~/Google Drive/director_bio/problematic_executive_ids.csv")


director_matches <- tbl(pg, sql("
     SELECT director_id::text, directorid, executive_ids::text
     FROM director.director_matches"))
