library(dplyr)
pg <- src_postgres()

# Use CRSP to match tickers and CUSIPs to permcos ----
stocknames <- tbl(pg, sql("
    SELECT permco, comnam, namedt, nameenddt, ncusip AS cusip, ticker
    FROM crsp.stocknames"))

crsp_cusips <-
    stocknames %>%
    select(permco, cusip) %>%
    distinct()

crsp_tickers <-
    stocknames %>%
    select(permco, ticker, namedt, nameenddt) %>%
    group_by(permco, ticker) %>%
    summarize(start_date=min(namedt), end_date=max(nameenddt))

# Match Equilar to CRSP permcos where possible ----
director_ciks <- tbl(pg, sql("
    SELECT *
    FROM director.ciks")) %>%
    select(equilar_id, cusip, cik) %>%
    distinct()

co_fin <- tbl(pg, sql("
    SELECT director.equilar_id(company_id),
        substring(cusip from 1 for 8) AS cusip8, *
    FROM director.co_fin")) %>%
    rename(cusip_original=cusip) %>%
    rename(cusip=cusip8)

director_cusip <-
    co_fin %>%
    inner_join(crsp_cusips) %>%
    select(equilar_id, cusip, permco) %>%
    distinct() %>%
    mutate(match_type=sql("'cusip'::text"))

director_ticker <-
    co_fin %>%
    anti_join(director_cusip) %>%
    left_join(crsp_tickers) %>%
    filter((fy_end >= start_date & fy_end <= end_date)
           | is.na(start_date)) %>%
    select(equilar_id, cusip, permco) %>%
    distinct() %>%
    mutate(match_type=sql("'ticker'::text"))

director_permco <-
    director_cusip %>%
    union(director_ticker) %>%
    collect()

director_permco$match_type[is.na(director_permco$permco)] <- "none"
table(director_permco$match_type)

# Match BoardEx to CRSP permcos where possible ----

# BoardEx companies
co_profile <- tbl(pg, sql("
    SELECT DISTINCT boardid, ticker, board_name,
        regexp_replace(isin,
                        '^(?:CA|US)([A-Z0-9]{8}).*$', '\\1') AS cusip
    FROM boardex.company_profile_stocks
    WHERE isin ~ '^(CA|US)'"))

co_profile_cusip <-
    co_profile %>%
    inner_join(crsp_cusips) %>%
    select(boardid, cusip, permco) %>%
    distinct() %>%
    mutate(match_type=sql("'cusip'::text"))

co_profile_ticker <-
    co_profile %>%
    anti_join(co_profile_cusip) %>%
    left_join(crsp_tickers) %>%
    select(boardid, cusip, permco) %>%
    distinct() %>%
    mutate(match_type=sql("'ticker'::text"))

co_profile_permco <-
    co_profile_cusip %>%
    union(co_profile_ticker) %>%
    distinct() %>%
    collect()

co_profile_permco$match_type[is.na(co_profile_permco$permco)] <- "none"
table(co_profile_permco$match_type)

# Combine Equilar and BoardEx using CUSIPs and permcos ----
boardex_merge_cusip <-
    director_permco %>%
    select(equilar_id, cusip) %>%
    inner_join(co_profile_permco %>% select(boardid, cusip),
              by="cusip") %>%
    select(equilar_id, boardid) %>%
    distinct() %>%
    mutate(match_type="cusip")

boardex_merge_permco <-
    director_permco %>%
    select(equilar_id, permco) %>%
    anti_join(boardex_merge_cusip %>% filter(!is.na(boardid))) %>%
    left_join(co_profile_permco %>%
                  select(boardid, permco) %>%
                  filter(!is.na(permco))) %>%
    select(equilar_id, boardid) %>%
    distinct() %>%
    mutate(match_type="permco")

boardex_merge <-
    boardex_merge_cusip %>%
    union(boardex_merge_permco) %>%
    arrange(equilar_id) %>%
    collect()

boardex_merge$match_type[is.na(boardex_merge$boardid)] <- "none"

boardex_merge %>%
    select(equilar_id, match_type) %>%
    distinct() %>%
    group_by(match_type) %>%
    summarize(count=n())

# Potentially bad matches
pot_bad_matches <-
    co_profile_ticker %>%
    collect() %>%
    filter(match_type=="ticker") %>%
    select(boardid) %>%
    inner_join(boardex_merge %>%
                   select(boardid, equilar_id)) %>%
    distinct() %>%
    inner_join(co_fin %>%
                   select(company, equilar_id) %>%
                   distinct() %>%
                   collect()) %>%
    inner_join(co_profile %>%
                   select(board_name, boardid) %>%
                   distinct() %>%
                   collect()) %>%
    as.data.frame()

# Write data to PostgreSQL ----
pg <- dbConnect(PostgreSQL())
rs <- dbWriteTable(pg, c("director", "boardex_merge"), as.data.frame(boardex_merge),
                   overwrite=TRUE, row.names=FALSE)
rs <- dbGetQuery(pg, "CREATE INDEX ON director.boardex_merge (equilar_id)")
rs <- dbGetQuery(pg, "CREATE INDEX ON director.boardex_merge (boardid)")
rs <- dbDisconnect(pg)
