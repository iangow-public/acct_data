
library(dplyr, warn.conflicts = FALSE)
Sys.setenv(PGHOST = "iangow.me", PGDATABASE = "crsp")

pg <- src_postgres()

dsf <- tbl(pg, sql("SELECT * FROM crsp.dsf"))

stocknames <- tbl(pg, sql("SELECT * FROM crsp.stocknames"))

# Create a sample of 10,000 "events"
events <-
    stocknames %>%
    select(permno, nameenddt) %>%
    distinct() %>%
    mutate(event_date = sql("nameenddt - interval '10 days'")) %>%
    semi_join(dsf) %>%
    select(permno, event_date) %>%
    top_n(10000) %>%
    distinct() %>%
    compute()

events %>% count()

events

code_url <- file.path("https://raw.githubusercontent.com",
                      "iangow/acct_data",
                      "master/code/getEventReturnsDB.R")

source(code_url)

system.time({
    event_rets <- getEventReturnsDB(events, days_before = -2, days_after = 2)
})

event_rets
