sql <- paste(readLines("director/cik_mult_cusips.sql"), collapse="\n")

library(dplyr)

pg <- src_postgres()
rs <- dbGetQuery(pg$con, "SET work_mem='2GB'")
dupes <- tbl(pg, sql(sql)) %>% collect() %>% as.data.frame()
dupes$cusip <- paste0("'", dupes$cusip)

library(googlesheets)

# Use gs_auth() or gs_auth(new_user = TRUE)
# before running this code the first time on a given computer.
gs <- gs_key("1vpyBXfURmd1qcPnlV7JX8ZnCKuoVp_Jcij8Fwdr3E9M")
gs_ws_delete(gs, ws = "mult_cusips")

gs <- gs_key("1vpyBXfURmd1qcPnlV7JX8ZnCKuoVp_Jcij8Fwdr3E9M")
gs_ws_new(gs, ws_title="mult_cusips", input=dupes)
