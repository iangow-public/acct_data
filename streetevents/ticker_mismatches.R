# Function that uses agrep() to determine matches
# I believe agrep() uses Levenshtein distance
amatch <- function(str1, str2) {
    if (str1=="" | str2 =="") return(NA)
    agrepl(str1, str2) | agrepl(str2, str1)
}

# Get data from PostgreSQL
library("RPostgreSQL")
pg <- dbConnect(PostgreSQL())
sql <- paste(readLines("streetevents/ticker_mismatches.sql"),
             collapse="\n")

sample <- dbGetQuery(pg, sql)
dbDisconnect(pg)

# Use Levenshtein distance to code matches
library(parallel)
sample$amatch_diff <- !(unlist(mcMap(amatch, sample$co_name, 
                                     sample$original_name, mc.cores=4)))

# Select cases with potential mismatches
mismatch_sample <- subset(sample, diff_name | amatch_diff)
mismatch_sample <- mismatch_sample[order(mismatch_sample$ticker), ]

# NUmber of distinct tickers
length(unique(mismatch_sample$ticker))

# Save to CSV in Google Drive
write.csv(mismatch_sample, 
          file="~/Google Drive/streetevents_ticker_mismatches.csv")

