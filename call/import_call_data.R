# Use StatTransfer to convert to CSV, then compress the resulting file
# localhost:~ igow$ st ~/Downloads/call0706.sas7bdat ~/Downloads/call0706.csv
# localhost:~ igow$ gzip ~/Downloads/call0706.csv

# Load file into R
temp <- read.csv("~/Downloads/call0706.csv.gz", stringsAsFactors=FALSE)

# Identify data types
getType <- function(variable) {
    if (variable=="Last_Date_Time_Submission_Update") {
        return("POSIXct")
    } else if (variable=="RCON9999") {
        return("Date")
    } else if (is.numeric(temp[, variable])) {
        return("numeric")
    } else if (length(setdiff(unique(temp[, variable]), c("true", "false", "")))==0) {
        return("boolean")
    } else {
        return("character")
    }
}

id.vars <- c("FDIC_Certificate_Number", "RCON9999")

temp <- subset(temp, !is.na(FDIC_Certificate_Number))

data_type <- data.frame(variable=names(temp), stringsAsFactors=FALSE)
data_type$type <- unlist(lapply(names(temp), getType))
num.vars <- setdiff(subset(data_type, type=="numeric")$variable, id.vars)
non.num.vars <- setdiff(subset(data_type, type!="numeric")$variable, id.vars)

# Split data into numeric and non-numeric data.
# "Melt" numeric data into a "long" format.
library(reshape2)
numeric_data <- temp[, c(id.vars, num.vars)]
non_numeric_data <- temp[, c(id.vars, non.num.vars)]
numeric_data_melted <- melt(numeric_data, id.vars=id.vars, na.rm=TRUE)
names(numeric_data_melted) <- tolower(names(numeric_data_melted))
names(non_numeric_data) <- tolower(names(non_numeric_data))

rm(temp)

# Put data into database
library(RPostgreSQL)
pg <- dbConnect(PostgreSQL())

rs <- dbGetQuery(pg, "
    CREATE SCHEMA IF NOT EXISTS call;
    DROP TABLE IF EXISTS call.numeric_data;
    DROP TABLE IF EXISTS call.non_numeric_data;")

rs <- dbWriteTable(pg, c("call", "numeric_data"), numeric_data_melted, append=TRUE, row.names=FALSE)
rs <- dbWriteTable(pg, c("call", "non_numeric_data"), non_numeric_data, append=TRUE, row.names=FALSE)

rs <- dbGetQuery(pg, "ALTER TABLE call.numeric_data ADD PRIMARY KEY (fdic_certificate_number, rcon9999, variable)")
rs <- dbGetQuery(pg, "ALTER TABLE call.non_numeric_data ADD PRIMARY KEY (fdic_certificate_number, rcon9999)")

rs <- dbDisconnect(pg)
