
library(dplyr)
library(googlesheets)
# Use gs_auth() or gs_auth(new_user = TRUE)
# before running this code the first time on a given computer.
gs <- gs_key("1U0K3FjhHIbqRbB4VVWVJxktsJj7NsTl7B_cckQ4h3Lo")

gvkey_matches <-
    gs_read(gs) %>%
    select(cik, fy_end, gvkey) %>%
    mutate(gvkey=sprintf("%06d", gvkey), fy_end=as.Date(fy_end))

library(RPostgreSQL)

pg <- dbConnect(PostgreSQL())
rs <- dbWriteTable(pg, c("director", "gvkey_matches"),
                         gvkey_matches %>% as.data.frame(),
                   row.names = FALSE, overwrite = TRUE)

rs <- dbGetQuery(pg, "
    UPDATE director.equilar_proxies AS a
    SET gvkey=b.gvkey
    FROM director.gvkey_matches AS b
    WHERE b.cik=a.cik AND b.fy_end=a.fy_end")

rs <- dbGetQuery(pg, "
    UPDATE director.director_gvkeys AS a
    SET gvkey=b.gvkey
    FROM director.gvkey_matches AS b
    WHERE b.cik=a.cik AND b.fy_end=a.test_date")

rs <- dbGetQuery(pg, "
    UPDATE director.director_gvkeys AS a
    SET gvkey=b.gvkey
    FROM (
        SELECT cik, gvkey, fy_end, lead(fy_end) OVER w AS next_fy_end
        FROM director.gvkey_matches
        WINDOW w AS (PARTITION BY cik, gvkey ORDER BY fy_end)) AS b
    WHERE b.cik=a.cik
        AND a.test_date BETWEEN b.fy_end AND b.next_fy_end")


# rs should be a data frame with 0 rows
rs <- dbGetQuery(pg, "
    WITH raw_data AS (
        SELECT equilar_id, fy_end, count(DISTINCT gvkey) AS num_gvkeys
        FROM director.equilar_proxies
        WHERE valid_date
        GROUP BY 1, 2)

    SELECT DISTINCT a.*
    FROM director.equilar_proxies AS a
    INNER JOIN raw_data
    USING (equilar_id, fy_end)
    WHERE num_gvkeys > 1")

# rs should be a data frame with 0 rows
rs <- dbGetQuery(pg, "
    WITH raw_data AS (
        SELECT director_id, test_date, count(DISTINCT gvkey) AS num_gvkeys
        FROM director.director_gvkeys
        WHERE valid_date
        GROUP BY 1, 2)

    SELECT DISTINCT a.*
    FROM director.director_gvkeys AS a
    INNER JOIN raw_data
    USING (director_id, test_date)
    WHERE num_gvkeys > 1 AND valid_date")
