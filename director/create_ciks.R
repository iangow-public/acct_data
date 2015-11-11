system("psql -f director/create_ciks.sql")

library(dplyr)
pg <- src_postgres()

ciks <- tbl(pg, sql("SELECT * FROM director.ciks"))

ciks %>%
    group_by(matched_on) %>%
    summarize(count=n()) %>%
    collect()

ciks %>%
    filter(matched_on != "equilar")
