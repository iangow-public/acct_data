library(dplyr)
library(readr)

path <- "~/Dropbox/data/equilar/director_match"

director_ids <-
    read_csv(file.path(path, "director_ids.csv"), na = "#N/A") %>%
    as.data.frame()

names(director_ids) <- tolower(names(director_ids))
company_ids <- read_csv(file.path(path, "company_ids.csv"), na = "N/A") %>%
        as.data.frame()
names(company_ids) <- tolower(names(company_ids))

library(RPostgreSQL)

pg <- dbConnect(PostgreSQL())

rs <- dbWriteTable(pg, c("director", "director_ids"), director_ids,
                   row.names = FALSE, overwrite = TRUE)
rs <- dbWriteTable(pg, c("director", "company_ids"), company_ids,
                   row.names = FALSE, overwrite = TRUE)

rs <- dbDisconnect(pg)
