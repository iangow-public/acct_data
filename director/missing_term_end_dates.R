director <- tbl(pg, sql("
    SELECT director.equilar_id(director_id),
        director.director_id(director_id) AS equilar_director_id, *
    FROM director.director")) %>%
    select(equilar_id, equilar_director_id, fy_end,
                          director_id, director, company, term_end_date)

co_fin <- tbl(pg, sql("
    SELECT director.equilar_id(company_id), *
    FROM director.co_fin"))

companies <-
    co_fin %>% group_by(equilar_id) %>%
    summarize(firm_last_fy_end=max(fy_end))

xt <- director %>%
    filter(is.na(term_end_date)) %>%
    group_by(equilar_id, equilar_director_id) %>%
    summarize(fy_end=max(fy_end)) %>%
    inner_join(companies) %>%
    filter(firm_last_fy_end > fy_end) %>%
    inner_join(director) %>%
    collect() %>%
    as_data_frame()

as_data_frame()

library(googlesheets)

# Use gs_auth() or gs_auth(new_user = TRUE)
# before running this code the first time on a given computer.
gs <- gs_new("missing_term_end_dates")

key <- "1LfT8pGedJ8b7Ho8aJxBUjVfLVRK6285WA73saf6Dd9U"
gs <- gs_key(key)
gs_ws_delete(gs, ws = "data")

gs <- gs_key(key)
gs_ws_new(gs, ws_title="data", input = missing_term_end_dates)
