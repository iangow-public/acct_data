# Load up the PostgreSQL driver, create a connection to the database
library(dplyr)

# The following function takes a list of permnos and event dates, then for each
# calls the function above to get event returns for each PERMNO-event date
# combination.
getEventReturnsDB <- function(df, days_before=0, days_after=0,
                            end_event_date=NULL, label="ret", conn=NULL) {

    # Make df ----
    if (!inherits(df, "tbl_postgres")) {
        df <- copy_to(conn, df, temporary = TRUE, overwrite = TRUE)
    } else {
        conn = df$src
    }

    df <-
        df %>%
        select(permno, event_date) %>%
        distinct() %>%
        mutate(event_date = sql("event_date::date"))

    if (is.null(end_event_date)) {
        df <-
            df %>%
            mutate(end_event_date = event_date)
    }

    df <-
        df %>%
        mutate(end_event_date = sql("end_event_date::date"),
               permno = as.integer(permno))


    rets <- tbl(conn, sql("SELECT * FROM crsp.rets"))
    dsi <- tbl(conn, sql("SELECT * FROM crsp.dsi"))
    anncdates <- tbl(conn, sql("SELECT * FROM crsp.anncdates"))
    trading_dates <- tbl(conn, sql("SELECT * FROM crsp.trading_dates"))

    max_date <-
        dsi %>%
        summarize(date =  max(date)) %>%
        collect() %>%
        .[[1]]

    # Merge data ----
    permnos_plus <-
        df %>%
        inner_join(anncdates, by=c("event_date"="anncdate")) %>%
        select(-date) %>%
        mutate(td_start = as.integer(td + days_before),
               td_end = as.integer(td + days_after)) %>%
        select(-td) %>%
        inner_join(trading_dates, by=c("td_start"="td")) %>%
        rename(date_start = date) %>%
        inner_join(trading_dates, by=c("td_end"="td")) %>%
        rename(date_end = date) %>%
        compute()

    ret_data <-
        permnos_plus %>%
        inner_join(rets) %>%
        filter(between(date, date_start, date_end)) %>%
        group_by(permno, event_date, end_event_date) %>%
        summarize(ret = product(1 + ret) - 1,
                  ret_mkt = product(1+ret)-product(1+vwretd),
                  ret_sz = product(1+ret)-product(1+decret)) %>%
        mutate(ret = if_else(end_event_date > max_date, NA_real_, ret),
               ret_mkt = if_else(end_event_date > max_date, NA_real_, ret_mkt),
               ret_sz = if_else(end_event_date > max_date, NA_real_, ret_sz)) %>%
        ungroup() %>%
        compute()

    # Label variables using label given appended to suffixes
    # suffixes <- c("", "_sz", "_mkt")
    # new.names <- paste(label, suffixes, sep="")
    # names(ret.data) <- sub("^ret", label, names(ret.data), perl=TRUE)
    return(ret_data)
}
