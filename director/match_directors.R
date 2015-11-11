system("psql -f director/match_directors.sql")

director_matches <- tbl(pg, sql("
    SELECT director_id::text, matched_ids::text, directorid, executive_ids::text
    FROM director.director_matches"))
director_matches

# Cases where executive_ids map to multiple directorids.
# I don't use these for matches unless there are no directorids
# for either firm or the directorids agree.
overmatched <- director_matches %>%
     filter(!is.na(directorid)) %>%
     select(directorid, executive_ids) %>%
     distinct() %>%
     group_by(executive_ids) %>%
     summarize(count=n()) %>% filter(count > 1) %>%
     inner_join(director_matches) %>%
     arrange(executive_ids) %>%
     collect()

overmatched %>%
    select(executive_ids) %>%
    distinct() %>%
    summarize(n())

overmatched %>%
    mutate(director_id=paste0("'", director_id)) %>%
    write_csv("~/Google Drive/director_bio/overmatched.csv")
