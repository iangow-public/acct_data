library(dplyr)
library(googlesheets)
library(RPostgreSQL)
# Use gs_auth() or gs_auth(new_user = TRUE)
# before running this code the first time on a given computer.
gs <- gs_key("1vpyBXfURmd1qcPnlV7JX8ZnCKuoVp_Jcij8Fwdr3E9M")
mult_cusips <- gs_read(gs)

pg <- src_postgres()

equilar_ciks <- tbl(pg, sql("SELECT * FROM director.company_ids")) %>%
    collect()

bad_ciks <-
    mult_cusips %>%
    filter(!good_match) %>%
    select(equilar_id, cik) %>%
    distinct() %>%
    inner_join(equilar_ciks)

if (nrow(bad_ciks)>0) {
    rs <-
        bad_ciks %>%
        as.data.frame() %>%
        dbWriteTable(pg$con, name = c("director", "bad_ciks"),
                     ., overwrite=TRUE, row.names=FALSE)

    # Do any bad CIK matches line up with good CIK matches?
    bad_ciks %>%
        left_join(mult_cusips %>%
                      filter(good_match), by="cik")

    rs <- dbGetQuery(pg$con,"
        DELETE FROM director.ciks
        WHERE (equilar_id, cik) IN
                     (SELECT equilar_id, cik FROM director.bad_ciks)")
} else {
    rs <- dbGetQuery(pg$con, "DROP TABLE IF EXISTS director.bad_ciks")
}

