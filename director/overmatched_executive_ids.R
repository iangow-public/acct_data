library(dplyr)
library(readr)

sql <- paste(readLines("director/overmatched_executive_ids.sql"), collapse="\n")
pg <- src_postgres()

tbl(pg, sql(sql)) %>%
    collect() %>%
    write_csv("~/Google Drive/director_bio/overmatched_executive_ids.csv")
