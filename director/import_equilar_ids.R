library(dplyr)
library(readr)

path <- "~/Dropbox/data/equilar/director_match"

lower_names <- function(df) {
    names(df) <- tolower(names(df))
    return(df)
}

director_ids <-
    read_csv(file.path(path, "director_ids.csv"), na = "#N/A") %>%
    lower_names() %>%
    mutate(director_id =ifelse(director_id==0, NA, director_id))

company_ids <-
    read_csv(file.path(path, "company_ids.csv"), na = "N/A") %>%
    lower_names() %>%
    mutate(cik =ifelse(cik==0, NA, cik))

library(RPostgreSQL)

pg <- dbConnect(PostgreSQL())

rs <- dbWriteTable(pg, c("director", "director_ids"),
                   director_ids %>% as.data.frame(),
                   row.names = FALSE, overwrite = TRUE)
rs <- dbWriteTable(pg, c("director", "company_ids"),
                   company_ids %>% as.data.frame(),
                   row.names = FALSE, overwrite = TRUE)

rs <- dbDisconnect(pg)
