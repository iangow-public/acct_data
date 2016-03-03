# Script to read Sharkwatch data from "Excel" file, clean it up, and place it in
# a PostgreSQL database.

# Read in the data
library(XML)

tablename = "sharkwatch_new"
filename = "sharkwatch_2016-03-02.xls"
tables = readHTMLTable(file.path("~/Dropbox/data/factset", filename),
                       header=TRUE, stringsAsFactors=FALSE)
sharkwatch=tables[[1]]
rm(tables)
sharkwatch <- sharkwatch[, !duplicated(names(sharkwatch))]

# Fix variable names
names(sharkwatch) <- gsub("[\\s+]","_", names(sharkwatch), perl=TRUE)
names(sharkwatch) <- gsub("%","_percent", names(sharkwatch), perl=TRUE)
names(sharkwatch) <- gsub("\\$_thousands","", names(sharkwatch), perl=TRUE)
names(sharkwatch) <- gsub("[&:(),'\\/]","", names(sharkwatch), perl=TRUE)
names(sharkwatch) <- gsub("\\$_mil","", names(sharkwatch), perl=TRUE)
names(sharkwatch) <- gsub("\\$","", names(sharkwatch), perl=TRUE)
names(sharkwatch) <- gsub("__+","_", names(sharkwatch), perl=TRUE)
names(sharkwatch) <- gsub("-","", names(sharkwatch), perl=TRUE)
names(sharkwatch) <- gsub("_$","", names(sharkwatch), perl=TRUE)
names(sharkwatch) <- tolower(names(sharkwatch))
names(sharkwatch) <- gsub("^5","five", names(sharkwatch), perl=TRUE)
names(sharkwatch) <- gsub("^13d","s13d", names(sharkwatch), perl=TRUE)
names(sharkwatch)

# Convert numeric variables to either double precision or integers
numeric.vars <- c("bullet_proof_rating",
                  "market_capitalization_at_time_of_campaign",
                  "primary_sic_code", "company_proxy_solicitor_fee",
                  "company_estimated_fight_costs",
                  "dissident_proxy_solicitor_fee",
                  "director_officer_ownership_percent",
                  "dissident_group_ownership_percent",
                  "dissident_group_ownership_percent_at_announcement")
for (i in numeric.vars) {
    sharkwatch[, i] <- as.numeric(sharkwatch[, i])
}
numeric.vars <- NULL
integer.vars <- c("fortune_500_rank", "campaign_id",
                  "primary_sic_code", "board_seats_up",
                  "dissident_board_seats_sought", "dissident_board_seats_won",
                  "number_of_members_in_dissident_group_excluding_individuals",
                  "number_of_members_in_dissident_group_including_individuals")
for (i in integer.vars) {
    sharkwatch[, i] <- as.integer(sharkwatch[, i])
}
integer.vars <- NULL

# Convert certain values to NA
for (i in 1:(dim(sharkwatch)[2])) {
    sharkwatch[, i][grep("\302\240", sharkwatch[, i])] <- NA
}

# Convert dates
for (i in grep("date", names(sharkwatch), value=TRUE)) {
    cat(i, "\n")
    to.clear <- !is.na(sharkwatch[,i]) & sharkwatch[,i]==""
    sharkwatch[to.clear, i] <- NA
    sharkwatch[, i] <- as.Date(sharkwatch[, i])
}

trim <- function(string) {
    string <- gsub("^\\s+","", string, perl=TRUE)
    string <- gsub("\\s+$","", string, perl=TRUE)
    string
}
sharkwatch$dissident_group <- trim(sharkwatch$dissident_group)
sharkwatch$holder_type <-
    trim(gsub("^.*Holder Type: (.*)$", "\\1",
              sharkwatch$dissident_group_with_sharkwatch50_and_holder_type))
sharkwatch$sharkwatch50 <-
    trim(gsub("^.*SharkWatch50\\?: (.*?) Holder Type: .*$", "\\1",
              sharkwatch$dissident_group_with_sharkwatch50_and_holder_type))

fixCUSIPs <- function(cusips) {
    to.fix <- nchar(cusips) < 9 & nchar(cusips) > 0
    cusips[to.fix] <- sprintf("%09d", as.integer(cusips[to.fix]))
    return(cusips)
}

sharkwatch$cusip_9_digit <- fixCUSIPs(sharkwatch$cusip_9_digit)

# Put data into PostgreSQL
library(RPostgreSQL)
pg <- dbConnect(PostgreSQL())

rs <- dbGetQuery(pg, paste("DELETE FROM factset.", tablename, sep=""))

rs <- dbWriteTable(pg, c("factset", tablename), sharkwatch,
                   overwrite=TRUE, row.names=FALSE)
rs <- dbGetQuery(pg, paste("ALTER TABLE factset.", tablename,
                           " OWNER TO activism", sep=""))
rs <- dbGetQuery(pg, paste("VACUUM factset.", tablename, sep=""))

sql <- paste("COMMENT ON TABLE factset.", tablename, " IS
    'CREATED USING DATA FROM ", filename,
             " AND CODE IN import_sharkwatch.R ON ", Sys.time() , "';", sep="")

rs <- dbGetQuery(pg, sql)
rs <- dbDisconnect(pg)

sharkwatch <- NULL
