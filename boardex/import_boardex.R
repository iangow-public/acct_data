# Set up utility functions ----

showTypes <- function(df) {
    for (var in names(df)) cat(var, ":\t", class(df[, var]), "\n")
}

convertDate <- function(vec) {

    # Treat 'Current' as missing
    vec[vec=="Current"] <- NA

    # Drop years; too far from being dates.
    vec[nchar(vec)==4] <- NA

    # Add day to partial dates
    vec[nchar(vec) %in% c(7,8) ] <-
        paste("01", vec[nchar(vec) %in% c(7,8) ])

    as.Date(vec, format="%d %b %Y")
}

convertShortDate <- function(vector) {
    as.Date(paste("1", vector), format="%d %b %Y")
}

# convertDate <- function(vector) {
#     library("RcppBDT"); library("dplyr")
#     ldply(as.Date(paste("1", vector), format="%d %b %Y"), .fun="getEndOfMonth",
#           .parallel=TRUE)
# }

convertPercentage <- function(vector) {
    as.numeric(gsub("%", "", vector))/100
}

fixVariables <- function(df) {
    df <- as.data.frame(df)
    if (!is.null(short.date.vars)) {
        for (var in short.date.vars) {
            df[, var] <-  convertShortDate(df[, var])
        }
    }
    if (!is.null(date.vars)) {
        for (var in date.vars) {
            df[, var] <-  convertDate(df[, var])
        }
    }

    if (!is.null(percent.vars)) {
            for (var in percent.vars) {
            df[, var] <- convertPercentage(df[, var])
        }
    }
    df
}

addTableToDatabase <- function(df, table.name, comment=NULL) {

    library("dplyr")
    library("RPostgreSQL")
    pg <- dbConnect(PostgreSQL())
    # dbGetQuery(pg, "CREATE SCHEMA boardex")
    dbWriteTable(pg, c("boardex", table.name),
                 df %>% as.data.frame(),
                 overwrite=TRUE, row.names=FALSE)

    for (var in short.date.vars) {
        dbGetQuery(pg, paste0("UPDATE boardex.", table.name,
                              " SET ", var, " = eomonth(", var, ")" ))
    }

    if (!is.null(comment)) {
        sql <- paste0("COMMENT ON TABLE boardex.", table.name, " IS '", comment, "'")
        dbGetQuery(pg, sql)
    }
    dbDisconnect(pg)
}

read_boardex <- function(file, fixExercisePrice = FALSE) {

    fixNames <- function(names) {
        tolower(gsub("([a-z])([A-Z][a-z])", "\\1_\\2", names, perl=TRUE))
    }

    library(readr)

    tf <- tempfile()

    # Convert to UTF-8 encoding
    cmd <- paste0("gunzip -c \"", file, "\" | iconv -f UTF-16 -t UTF-8 | ")

    # Remove carriage returns embedded in fields
    cmd <- paste0(cmd, "tr -d '\\015' ")

    # Save to temp file
    cmd <- paste0(cmd, " > ", tf)

    # cat(cmd)
    system(cmd)

    if (fixExercisePrice) {
        temp <- read_delim(tf, na=c("", "n.a."), delim="|",
                           col_types=cols(ExercisePrice = "c"))
        temp$ExercisePrice <- as.numeric(gsub("#$", "", temp$ExercisePrice))
    } else {
        temp <- read_delim(tf, na=c("", "n.a."), delim="|")
    }
    names(temp) <- fixNames(names(temp))
    return(temp)
}

addFileToDatabase <- function(file) {
    library(dplyr)
    table.name <- gsub("\\s+", "_", gsub("\\d+\\.csv.gz$", "",
                                     tolower(basename(file))))
    cat("Processing table:", table.name, "\n")
    comment <- paste0("Created using data in ", basename(file))
    read_boardex(file) %>%
        fixVariables() %>%
        addTableToDatabase(table.name, comment=comment)
}

# Read in file list ----
file_list <- sort(list.files(file.path(Sys.getenv("DROPBOX_DIR"),
                                       "boardex"),
                             pattern="*.csv.gz", full.name=TRUE))

# Table 1: board_and_director_announcements ----
file <- file_list[grepl("Board and Director Announcements", file_list)]

# attrition and attrition3yr appear to be a percentages
percent.vars <- NULL
date.vars <- c("effective_date", "announcement_date")
short.date.vars <- NULL

addFileToDatabase(file)

# Table 2: board_and_director_committees ----
file <- file_list[grepl("Board and Director Committees", file_list)]

# annual_report_date appears to be a short date
# While incomplete, generally it is `safe' to convert to the end of the month
percent.vars <- NULL
date.vars <- NULL
short.date.vars <- c("annual_report_date")

addFileToDatabase(file)

# Table 3: board_characteristics ----
file <- file_list[grepl("Board Characteristics", file_list)]


# attrition and attrition3yr appear to be a percentages
percent.vars <- c("attrition", "attrition3yr", "gender_ratio")
date.vars <- NULL
# If incomplete (e.g., "Dec 2008"), generally it is `safe' to convert dates
# to the end of the month
short.date.vars <- c("annual_report_date")

addFileToDatabase(file)

# Table 4: company_profile_advisors ----
file <- file_list[grepl("Company Profile Advisors", file_list)]

# No conversions needed here.
percent.vars <- NULL
date.vars <- NULL
short.date.vars <- NULL

addFileToDatabase(file)

# Table 5: company_profile_details ----
file <- file_list[grepl("Company Profile Details", file_list)]
# No conversions needed here.
percent.vars <- NULL
date.vars <- NULL
short.date.vars <- NULL

addFileToDatabase(file)

# Table 6: company_profile_market_cap ----
file <- file_list[grepl("Company Profile Market Cap", file_list)]

# No conversions needed here.
percent.vars <- NULL
date.vars <- NULL
short.date.vars <- NULL

addFileToDatabase(file)

# Table 7: company_profile_senior_managers ----
file <- file_list[grepl("Company Profile Senior Managers", file_list)]

table.name <- gsub("\\s+", "_", gsub("\\d+\\.csv\\.gz$", "",
                                     tolower(basename(file))))
temp <- read_boardex(file)

percent.vars <- NULL
date.vars <- c("date_start_role", "date_end_role")
short.date.vars <- NULL

temp1 <- fixVariables(temp)

# Keep the year as a separate variable if that's all we have
valid.end.dates <- temp$date_end_role!="Current" & !is.na(temp$date_end_role)
temp$year_end_role <- NA
temp$year_end_role[valid.end.dates] <- gsub(".*(\\d{4})$", "\\1", temp$date_end_role[valid.end.dates])

valid.start.dates <- temp$date_start_role!="Current" &
    !is.na(temp$date_start_role)
temp$year_start_role <- NA
temp$year_start_role[valid.start.dates] <-
    gsub(".*(\\d{4})$", "\\1", temp$date_start_role[valid.start.dates])

comment <- paste0("Created using data in ", basename(file))

addTableToDatabase(temp1, table.name, comment = comment)

# Table 8: company_profile_stocks ----
file <- file_list[grepl("Company Profile Stocks", file_list)]

# No conversions needed here.
percent.vars <- NULL
date.vars <- NULL
short.date.vars <- NULL

addFileToDatabase(file)

# Table 9: director_characteristics ----
file <- file_list[grepl("Director Characteristics", file_list)]

# No conversions needed here.
percent.vars <- NULL
date.vars <- NULL
short.date.vars <- NULL

addFileToDatabase(file)

# Table 10: director_profile_achievements ----
file <- file_list[grepl("Director Profile Achievements", file_list)]

# No conversions needed here.
percent.vars <- NULL
date.vars <- "achievement_date"
short.date.vars <- NULL

addFileToDatabase(file)

# Table 11: director_profile_details ----
file <- file_list[grepl("Director Profile Details", file_list)]

# No conversions needed here.
percent.vars <- NULL
date.vars <- c("dob", "dod")
short.date.vars <- NULL

addFileToDatabase(file)

# Table 12: director_profile_education ----
file <- file_list[grepl("Director Profile Education", file_list)]

# No conversions needed here.
percent.vars <- NULL
date.vars <- c("award_date")
short.date.vars <- NULL

addFileToDatabase(file)

# Table 13: director_profile_employment ----
file <- file_list[grepl("Director Profile Employment", file_list)]

table.name <- gsub("\\s+", "_", gsub("\\d+\\.csv\\.gz$", "",
                                     tolower(basename(file))))

# Copy and paste table.name output to "Table: ..." line above
table.name
temp <- read_boardex(file)

percent.vars <- NULL
date.vars <- c("date_start_role", "date_end_role")
short.date.vars <- NULL

# Keep the year as a separate variable if that's all we have
valid.end.dates <- temp$date_end_role!="Current" & !is.na(temp$date_end_role)
temp$year_end_role <- NA
temp$year_end_role[valid.end.dates] <-
    gsub(".*(\\d{4})$", "\\1", temp$date_end_role[valid.end.dates])

valid.start.dates <- temp$date_start_role!="Current" & !is.na(temp$date_start_role)
temp$year_start_role <- NA
temp$year_start_role[valid.start.dates] <-
    gsub(".*(\\d{4})$", "\\1", temp$date_start_role[valid.start.dates])

temp1 <- fixVariables(temp)

comment <- paste0("Created using data in ", basename(file))

addTableToDatabase(temp1, table.name, comment = comment)

# Table 14: director_profile_other_activities ----
file <- file_list[grepl("Director Profile Other Activities", file_list)]

table.name <- gsub("\\s+", "_", gsub("\\d+\\.csv\\.gz$", "",
                                     tolower(basename(file))))

# Copy and paste table.name output to "Table: ..." line above
table.name
temp <- read_boardex(file)

percent.vars <- NULL
date.vars <- c("start_date", "end_date")
short.date.vars <- NULL

# Keep the year as a separate variable if that's all we have
valid.end.dates <- temp$end_date!="Current" & !is.na(temp$end_date)
temp$end_year <- NA
temp$end_year[valid.end.dates] <-
    gsub(".*(\\d{4})$", "\\1", temp$end_date[valid.end.dates])

valid.start.dates <- temp$start_date!="Current" & !is.na(temp$start_date)
temp$start_year <- NA
temp$start_year[valid.start.dates] <-
    gsub(".*(\\d{4})$", "\\1", temp$start_date[valid.start.dates])

temp1 <- fixVariables(temp)

comment <- paste0("Created using data in ", basename(file))

addTableToDatabase(temp1, table.name, comment = comment)

# Table 15: director_standard_remuneration ----
file <- file_list[grepl("Director Standard Remuneration", file_list)]

percent.vars <- "rem_chge_last"
date.vars <- NULL
short.date.vars <- "annual_report_date"

addFileToDatabase(file)

# Table 16: ltip_compensation_drilldown ----
file <- file_list[grepl("LTIP Compensation DrillDown", file_list)]

percent.vars <- NULL
date.vars <- c("vesting_date", "expiry_date")
short.date.vars <- "annual_report_date"

addFileToDatabase(file)

# Table 17: ltip_wealth_drilldown ----
file <- file_list[grepl("LTIP Wealth DrillDown", file_list)]

percent.vars <- NULL
date.vars <- c("vesting_date", "expiry_date")
short.date.vars <- "annual_report_date"

addFileToDatabase(file)

# Table 18: options_compensation_drilldown ----
file <- file_list[grepl("Options Compensation DrillDown", file_list)]

# exercise_price needs to be fixed!
percent.vars <- NULL
date.vars <- c("vesting_date", "expiry_date")
short.date.vars <- "annual_report_date"

addFileToDatabase(file)

# Table 19: options_wealth_drilldown ----
file <- file_list[grepl("Options Wealth DrillDown", file_list)]

# exercise_price needs to be fixed!
percent.vars <- NULL
date.vars <- c("vesting_date", "expiry_date")
short.date.vars <- "annual_report_date"

addFileToDatabase(file)

# Table 20: options_compensation_drilldown ----
file <- file_list[grepl("Options Compensation DrillDown", file_list)]

# exercise_price needs to be fixed!
percent.vars <- NULL
date.vars <- c("vesting_date", "expiry_date")
short.date.vars <- "annual_report_date"

addFileToDatabase(file)

# Fix permissions in database ----
library("RPostgreSQL")
pg <- dbConnect(PostgreSQL())
dbGetQuery(pg, "GRANT USAGE ON SCHEMA boardex TO crsp_plus")
dbGetQuery(pg, "GRANT SELECT ON ALL TABLES IN SCHEMA boardex TO crsp_plus")

dbDisconnect(pg)
