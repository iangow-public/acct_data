library(googlesheets)

# Use gs_auth() or gs_auth(new_user = TRUE)
# before running this code the first time on a given computer.
gs <- gs_key("1vpyBXfURmd1qcPnlV7JX8ZnCKuoVp_Jcij8Fwdr3E9M")
mult_cusips <- gs_read(gs)

mult_cusips %>%
    filter(good_match)
    select(equilar_id, cik) %>%
    distinct() %>%
    group_by(equilar_id) %>%
    summarize(num_ciks=n()) %>%
    filter(num_ciks > 1)

rs <-
    mult_cusips %>%
    filter(!good_match) %>%
    select(cusip, cik) %>%
    distinct() %>%
    as.data.frame() %>%
    dbWriteTable(pg$con, name = c("director", "bad_ciks"),
                 ., overwrite=TRUE, row.names=FALSE)

rs <- dbGetQuery(pg$con,"
    DELETE FROM director.ciks
    WHERE (cusip, cik) IN (SELECT cusip, cik FROM director.bad_ciks)")
