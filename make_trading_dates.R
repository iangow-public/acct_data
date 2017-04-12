library(dplyr, warn.conflicts = FALSE)
pg <- src_postgres()

dsi <- tbl(pg, sql("SELECT * FROM crsp.dsi"))

trading_dates <-
    dsi %>%
    select(date) %>%
    distinct() %>%
    arrange(date) %>%
    mutate(td = rank())

all_dates <-
    trading_dates %>%
    summarize(min_date = min(date), max_date=max(date)) %>%
    mutate(min_date = sql("min_date::timestamp"),
           max_date = sql("max_date::timestamp")) %>%
    mutate(anncdate = generate_series(min_date, max_date, '1 day')) %>%
    mutate(anncdate = sql("anncdate::date")) %>%
    select(anncdate)

w <- "(ORDER BY anncdate ROWS BETWEEN CURRENT ROW AND 7 FOLLOWING)"
td_sql <- paste("min(td) OVER", w)
date_sql <- paste("min(date) OVER", w)
anncdates <-
    all_dates %>%
    left_join(trading_dates, by=c("anncdate"="date")) %>%
    mutate(td = sql(td_sql), date = sql(date_sql)) %>%
    mutate(td = as.integer(td)) %>%
    arrange(anncdate) %>%
    compute()
