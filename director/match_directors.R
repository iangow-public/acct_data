system("psql -f director/match_directors.sql")

library(dplyr)

pg <- src_postgres()

director_matches <- tbl(pg, sql("
    SELECT (director_id).*, matched_ids::text, directorid,
        UNNEST(executive_ids) AS executive_id
    FROM director.director_matches
    WHERE array_length(executive_ids, 1)=1"))
director_matches

# Cases where executive_ids map to multiple directorids.
# I don't use these for matches unless there are no directorids
# for either firm or the directorids agree.
overmatched <- director_matches %>%
     filter(!is.na(directorid)) %>%
     select(directorid, executive_id) %>%
     distinct() %>%
     group_by(executive_id) %>%
     summarize(count=n()) %>% filter(count > 1) %>%
     inner_join(director_matches) %>%
     arrange(executive_id) %>%
     collect()

overmatched %>%
    select(executive_id) %>%
    distinct() %>%
    summarize(n())

overmatched %>%
    mutate(director_id=paste0("'", director_id)) %>%
    write_csv("~/Dropbox/data/equilar/overmatched.csv")
