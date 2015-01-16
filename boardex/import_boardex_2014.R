# Set up utility functions ----
fixNames <- function(names) {
    tolower(gsub("([a-z])([A-Z][a-z])", "\\1_\\2", names, perl=TRUE))
}

showTypes <- function(df) {
    for (var in names(df)) cat(var, ":\t", class(df[, var]), "\n")
}

convertDate <- function(vector) {
    
    # Treat 'Current' as missing
    vector[vector=="Current"] <- NA
    
    # Drop years; too far from being dates.
    vector[nchar(vector)==4] <- NA
    
    # Add day to partial dates    
    vector[nchar(vector) %in% c(7,8) ] <- paste("01", vector[nchar(vector) %in% c(7,8) ])
                                                  
    as.Date(vector, format="%d %b %Y")
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

addTableToDatabase <- function(df, table.name) {
    
    library("RPostgreSQL")
    pg <- dbConnect(PostgreSQL())
    # dbGetQuery(pg, "CREATE SCHEMA boardex_2014")
    dbWriteTable(pg, c("boardex_2014", table.name), df, overwrite=TRUE, row.names=FALSE)
    
    for (var in short.date.vars) {
        dbGetQuery(pg, paste0("UPDATE boardex_2014.", table.name,
                              " SET ", var, " = eomonth(", var, ")" ))
    }   
    dbDisconnect(pg)
}

# Read in file list ----
Sys.setenv(PGHOST="iangow.me", PGDATABASE="crsp")

file_list <- sort(list.files("~/Dropbox/data/boardex/2014-10", pattern="*.csv.gz",
                        full.name=TRUE))


# Table 1: board_and_director_announcements ----
file <- file_list[1]

table.name <- gsub("\\s+", "_", gsub("\\d+\\.csv.gz$", "", tolower(basename(file))))
temp <- read.delim(file, fileEncoding="UTF-16LE", sep="|", na.strings="n.a.",
                   stringsAsFactors=FALSE)
names(temp) <- fixNames(names(temp))
showTypes(temp)
head(temp)

# attrition and attrition3yr appear to be a percentages
percent.vars <- NULL
date.vars <- c("effective_date", "announcement_date")
short.date.vars <- NULL

temp1 <- fixVariables(temp)

addTableToDatabase(temp1, table.name)

# Table 2: board_and_director_committees ----
file <- file_list[2]

table.name <- gsub("\\s+", "_", gsub("\\d+\\.csv.gz$", "", tolower(basename(file))))
table.name
temp <- read.delim(file, fileEncoding="UTF-16LE", sep="|", na.strings="n.a.",
                   stringsAsFactors=FALSE)
names(temp) <- fixNames(names(temp))
showTypes(temp)
head(temp)

# annual_report_date appears to be a short date
# While incomplete, generally it is `safe' to convert to the end of the month
percent.vars <- NULL 
date.vars <- NULL
short.date.vars <- c("annual_report_date")
temp1 <- fixVariables(temp)

addTableToDatabase(temp1, table.name)

# Table 3: board_characteristics ----
file <- file_list[3]

table.name <- gsub("\\s+", "_", gsub("\\d+\\.csv.gz$", "", tolower(basename(file))))
temp <- read.delim(file, fileEncoding="UTF-16LE", sep="|", na.strings="n.a.",
                   stringsAsFactors=FALSE)
names(temp) <- fixNames(names(temp))
showTypes(temp)

# attrition and attrition3yr appear to be a percentages
percent.vars <- c("attrition", "attrition3yr", "gender_ratio")
date.vars <- NULL
# If incomplete (e.g., "Dec 2008"), generally it is `safe' to convert dates
# to the end of the month
short.date.vars <- c("annual_report_date")

temp1 <- fixVariables(temp)

addTableToDatabase(temp1, table.name)

# Table 4: company_profile_advisors ----
file <- file_list[4]

table.name <- gsub("\\s+", "_", gsub("\\d+\\.csv.gz$", "", tolower(basename(file))))

# Copy and paste table.name output to "Table: ..." line above
table.name
temp <- read.delim(file, fileEncoding="UTF-16LE", sep="|", na.strings="n.a.",
                   stringsAsFactors=FALSE)
names(temp) <- fixNames(names(temp))
showTypes(temp)
head(temp)

# No conversions needed here.
percent.vars <- NULL
date.vars <- NULL
short.date.vars <- NULL

temp1 <- fixVariables(temp)

addTableToDatabase(temp1, table.name)

# Table 5: company_profile_details ----
file <- file_list[5]

table.name <- gsub("\\s+", "_", gsub("\\d+\\.csv.gz$", "", tolower(basename(file))))

# Copy and paste table.name output to "Table: ..." line above
table.name
temp <- read.delim(file, fileEncoding="UTF-16LE", sep="|", na.strings="n.a.",
                   stringsAsFactors=FALSE)
names(temp) <- fixNames(names(temp))
showTypes(temp)
head(temp)

temp$date_end_role[temp$date_end_role=="Current"] <- NA

# No conversions needed here.
percent.vars <- NULL
date.vars <- NULL
short.date.vars <- NULL

temp1 <- fixVariables(temp)

addTableToDatabase(temp1, table.name)

# Table 6: company_profile_market_cap ----
file <- file_list[6]

table.name <- gsub("\\s+", "_", gsub("\\d+\\.csv.gz$", "", tolower(basename(file))))

# Copy and paste table.name output to "Table: ..." line above
table.name
temp <- read.delim(file, fileEncoding="UTF-16LE", sep="|", na.strings="n.a.",
                   stringsAsFactors=FALSE)
names(temp) <- fixNames(names(temp))
showTypes(temp)
head(temp)

# No conversions needed here.
percent.vars <- NULL
date.vars <- NULL
short.date.vars <- NULL

temp1 <- fixVariables(temp)

addTableToDatabase(temp1, table.name)

# Table 7: company_profile_senior_managers ----
file <- file_list[7]

table.name <- gsub("\\s+", "_", gsub("\\d+\\.csv.gz$", "", tolower(basename(file))))

# Copy and paste table.name output to "Table: ..." line above
table.name
temp <- read.delim(file, fileEncoding="UTF-16LE", sep="|", na.strings="n.a.",
                   stringsAsFactors=FALSE)
names(temp) <- fixNames(names(temp))
showTypes(temp)
head(temp)

percent.vars <- NULL
date.vars <- c("date_start_role", "date_end_role")
short.date.vars <- NULL

# Keep the year as a separate variable if that's all we have
valid.end.dates <- temp$date_end_role!="Current" & !is.na(temp$date_end_role)
temp$year_end_role[valid.end.dates] <- gsub(".*(\\d{4})$", "\\1", temp$date_end_role[valid.end.dates])

valid.start.dates <- temp$date_start_role!="Current" & !is.na(temp$date_start_role)
temp$year_start_role[valid.start.dates] <- 
    gsub(".*(\\d{4})$", "\\1", temp$date_start_role[valid.start.dates])

temp1 <- fixVariables(temp)

addTableToDatabase(temp1, table.name)

# Table 8: company_profile_stocks ----
file <- file_list[8]

table.name <- gsub("\\s+", "_", gsub("\\d+\\.csv.gz$", "", tolower(basename(file))))

# Copy and paste table.name output to "Table: ..." line above
table.name
temp <- read.delim(file, fileEncoding="UTF-16LE", sep="|", na.strings="n.a.",
                   stringsAsFactors=FALSE)
names(temp) <- fixNames(names(temp))
showTypes(temp)
head(temp)

# No conversions needed here.
percent.vars <- NULL
date.vars <- NULL
short.date.vars <- NULL

temp1 <- fixVariables(temp)

addTableToDatabase(temp1, table.name)

# Table 9: director_characteristics ----
file <- file_list[9]

table.name <- gsub("\\s+", "_", gsub("\\d+\\.csv.gz$", "", tolower(basename(file))))

# Copy and paste table.name output to "Table: ..." line above
table.name
temp <- read.delim(file, fileEncoding="UTF-16LE", sep="|", na.strings="n.a.",
                   stringsAsFactors=FALSE)
names(temp) <- fixNames(names(temp))
showTypes(temp)
head(temp)

# No conversions needed here.
percent.vars <- NULL
date.vars <- NULL
short.date.vars <- NULL

temp1 <- fixVariables(temp)

addTableToDatabase(temp1, table.name)

# Table 10: director_profile_achievements ----
file <- file_list[10]

table.name <- gsub("\\s+", "_", gsub("\\d+\\.csv.gz$", "", tolower(basename(file))))

# Copy and paste table.name output to "Table: ..." line above
table.name
temp <- read.delim(file, fileEncoding="UTF-16LE", sep="|", na.strings="n.a.",
                   stringsAsFactors=FALSE)
names(temp) <- fixNames(names(temp))
showTypes(temp)
head(temp)

# No conversions needed here.
percent.vars <- NULL
date.vars <- "achievement_date"
short.date.vars <- NULL

temp1 <- fixVariables(temp)

addTableToDatabase(temp1, table.name)

# Table 11: director_profile_details ----
file <- file_list[11]

table.name <- gsub("\\s+", "_", gsub("\\d+\\.csv\\.gz$", "", tolower(basename(file))))

# Copy and paste table.name output to "Table: ..." line above
table.name
temp <- read.delim(file, fileEncoding="UTF-16LE", sep="|", na.strings="n.a.",
                   stringsAsFactors=FALSE)
names(temp) <- fixNames(names(temp))
showTypes(temp)
head(temp)

# No conversions needed here.
percent.vars <- NULL
date.vars <- c("dob", "dod")
short.date.vars <- NULL

temp1 <- fixVariables(temp)

addTableToDatabase(temp1, table.name)

# Table 12: director_profile_education ----
file <- file_list[12]

table.name <- gsub("\\s+", "_", gsub("\\d+\\.csv\\.gz$", "", tolower(basename(file))))

# Copy and paste table.name output to "Table: ..." line above
table.name
temp <- read.delim(file, fileEncoding="UTF-16LE", sep="|", na.strings="n.a.",
                   stringsAsFactors=FALSE)
names(temp) <- fixNames(names(temp))
showTypes(temp)
head(temp)

# No conversions needed here.
percent.vars <- NULL
date.vars <- c("award_date")
short.date.vars <- NULL

temp1 <- fixVariables(temp)

# Table 13: director_profile_employment ----
file <- file_list[13]

table.name <- gsub("\\s+", "_", gsub("\\d+\\.csv\\.gz$", "", tolower(basename(file))))

# Copy and paste table.name output to "Table: ..." line above
table.name
temp <- read.delim(file, fileEncoding="UTF-16LE", sep="|", na.strings="n.a.",
                   stringsAsFactors=FALSE)
names(temp) <- fixNames(names(temp))
showTypes(temp)
head(temp)

percent.vars <- NULL
date.vars <- c("date_start_role", "date_end_role")
short.date.vars <- NULL

# Keep the year as a separate variable if that's all we have
valid.end.dates <- temp$date_end_role!="Current" & !is.na(temp$date_end_role)
temp$year_end_role[valid.end.dates] <-
    gsub(".*(\\d{4})$", "\\1", temp$date_end_role[valid.end.dates])

valid.start.dates <- temp$date_start_role!="Current" & !is.na(temp$date_start_role)
temp$year_start_role[valid.start.dates] <- 
    gsub(".*(\\d{4})$", "\\1", temp$date_start_role[valid.start.dates])

temp1 <- fixVariables(temp)

addTableToDatabase(temp1, table.name)

# Table 14: director_profile_other_activities ----
file <- file_list[14]

table.name <- gsub("\\s+", "_", gsub("\\d+\\.csv\\.gz$", "", tolower(basename(file))))

# Copy and paste table.name output to "Table: ..." line above
table.name
temp <- read.delim(file, fileEncoding="UTF-16LE", sep="|", na.strings="n.a.",
                   stringsAsFactors=FALSE)
names(temp) <- fixNames(names(temp))
showTypes(temp)
head(temp)

percent.vars <- NULL
date.vars <- c("start_date", "end_date")
short.date.vars <- NULL

# Keep the year as a separate variable if that's all we have
valid.end.dates <- temp$end_date!="Current" & !is.na(temp$end_date)
temp$end_year[valid.end.dates] <-
    gsub(".*(\\d{4})$", "\\1", temp$end_date[valid.end.dates])

valid.start.dates <- temp$start_date!="Current" & !is.na(temp$start_date)
temp$start_year[valid.start.dates] <- 
    gsub(".*(\\d{4})$", "\\1", temp$start_date[valid.start.dates])

temp1 <- fixVariables(temp)

addTableToDatabase(temp1, table.name)

# Table 15: director_standard_remuneration ----
file <- file_list[15]

table.name <- gsub("\\s+", "_", gsub("\\d+\\.csv\\.gz$", "", tolower(basename(file))))

# Copy and paste table.name output to "Table: ..." line above
table.name
temp <- read.delim(file, fileEncoding="UTF-16LE", sep="|", na.strings=c("n.a.", "n.d."),
                   stringsAsFactors=FALSE)
names(temp) <- fixNames(names(temp))
showTypes(temp)
head(temp)

percent.vars <- "rem_chge_last"
date.vars <- NULL
short.date.vars <- "annual_report_date"

temp1 <- fixVariables(temp)

addTableToDatabase(temp1, table.name)

# Table 16: ltip_compensation_drilldown ----
file <- file_list[16]

table.name <- gsub("\\s+", "_", gsub("\\d+\\.csv\\.gz$", "", tolower(basename(file))))

# Copy and paste table.name output to "Table: ..." line above
table.name
temp <- read.delim(file, fileEncoding="UTF-16LE", sep="|", na.strings=c("n.a.", "n.d."),
                   stringsAsFactors=FALSE)
names(temp) <- fixNames(names(temp))
showTypes(temp)
head(temp)

percent.vars <- NULL
date.vars <- c("vesting_date", "expiry_date")
short.date.vars <- "annual_report_date"

temp1 <- fixVariables(temp)

addTableToDatabase(temp1, table.name)

# Table 17: ltip_wealth_drilldown ----
file <- file_list[17]

table.name <- gsub("\\s+", "_", gsub("\\d+\\.csv\\.gz$", "", tolower(basename(file))))

# Copy and paste table.name output to "Table: ..." line above
table.name
temp <- read.delim(file, fileEncoding="UTF-16LE", sep="|", na.strings=c("n.a.", "n.d."),
                   stringsAsFactors=FALSE)
names(temp) <- fixNames(names(temp))
showTypes(temp)
head(temp)

percent.vars <- NULL
date.vars <- c("vesting_date", "expiry_date")
short.date.vars <- "annual_report_date"

temp1 <- fixVariables(temp)

addTableToDatabase(temp1, table.name)

# Table 18: options_compensation_drilldown ----
file <- file_list[18]

table.name <- gsub("\\s+", "_", gsub("\\d+\\.csv\\.gz$", "", tolower(basename(file))))

# Copy and paste table.name output to "Table: ..." line above
table.name
temp <- read.delim(file, fileEncoding="UTF-16LE", sep="|", na.strings=c("n.a.", "n.d."),
                   stringsAsFactors=FALSE)
names(temp) <- fixNames(names(temp))
showTypes(temp)
head(temp)

# exercise_price needs to be fixed!
percent.vars <- NULL
date.vars <- c("vesting_date", "expiry_date")
short.date.vars <- "annual_report_date"

temp1 <- fixVariables(temp)

addTableToDatabase(temp1, table.name)

# Table 19: options_wealth_drilldown ----
file <- file_list[19]

table.name <- gsub("\\s+", "_", gsub("\\d+\\.csv\\.gz$", "", tolower(basename(file))))

# Copy and paste table.name output to "Table: ..." line above
table.name
temp <- read.delim(file, fileEncoding="UTF-16LE", sep="|", na.strings=c("n.a.", "n.d."),
                   stringsAsFactors=FALSE)
names(temp) <- fixNames(names(temp))
showTypes(temp)
head(temp)

# exercise_price needs to be fixed!
percent.vars <- NULL
date.vars <- c("vesting_date", "expiry_date")
short.date.vars <- "annual_report_date"

temp1 <- fixVariables(temp)

addTableToDatabase(temp1, table.name)
