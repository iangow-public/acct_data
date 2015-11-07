sql <- paste(readLines("director/problematic_ids.sql"), collapse="\n")

library(dplyr)

pg <- src_postgres()

problems <- tbl(pg, sql(sql)) %>% collect() %>% as.data.frame()
problems$cusip <- paste0("'", problems$cusip)

library(googlesheets)

# Use gs_auth() or gs_auth(new_user = TRUE)
# before running this code the first time on a given computer.
gs <- gs_key("19kg-MLRYa4g7-rvUocJ_v9h2nIZGiueqaaZuXI4Q1D4")
gs_ws_delete(gs, ws = "problems")

gs <- gs_key("19kg-MLRYa4g7-rvUocJ_v9h2nIZGiueqaaZuXI4Q1D4")
gs_ws_new(gs, ws_title="problems", input = problems)
