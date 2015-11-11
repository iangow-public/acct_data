library(dplyr)
library(readr)

pg <- src_postgres()

company_ids <- tbl(pg, sql("
    SELECT DISTINCT director.equilar_id(company_id)
    FROM director.co_fin
    ORDER BY 1")) %>%
    collect() %>%
    write_csv(path="~/Google Drive/director_bio/company_ids.csv")

director_ids <- tbl(pg, sql("
    SELECT DISTINCT director.equilar_id(director_id),
        director.director_id(director_id)
    FROM director.director
    ORDER BY 1, 2")) %>%
    collect() %>%
    write_csv(path="~/Google Drive/director_bio/director_ids.csv")
