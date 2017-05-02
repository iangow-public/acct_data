########################################################################
# Small program to fetch and organize Fama-French factor data.
# The idea is to make a table that could be used for SQL merges.
########################################################################
args<-commandArgs(TRUE)

# The URL for the data.
ff.url.partial <- paste("http://mba.tuck.dartmouth.edu",
                        "pages/faculty/ken.french/ftp", sep="/")

# Function to remove leading and trailing spaces from a string
trim <- function(string) {
    ifelse(grepl("^\\s*$", string, perl=TRUE),"",
           gsub("^\\s*(.*?)\\s*$","\\1", string, perl=TRUE))
}

################################################################################
#                   Download Fama-French BEME portfolio cutoffs                #
################################################################################

# Download the data and unzip it
ff.url <- paste(ff.url.partial, "BE-ME_Breakpoints_TXT.zip", sep="/")
f <- tempfile()
download.file(ff.url, f)
file.list <- unzip(f, list=TRUE)
z <- unzip(f, files=as.character(file.list[1,1]))
# Parse the data
ff_beme <-
    read.fwf(z,
             widths=c(4,5,5,rep(9,20)), header=FALSE,
             stringsAsFactors=FALSE, skip=3)
names(ff_beme) <- c("year", "n_neg", "n_pos", paste("p", seq(5, 100, 5), sep=""))

unlink(z)

# Clean the data
ff_beme$year <- as.integer(ff_beme$year)
ff_beme <- subset(ff_beme, !is.na(year))
for (i in 2:(dim(ff_beme)[2])) ff_beme[,i] <- as.numeric(trim(ff_beme[,i]))

library(RPostgreSQL)

pg <- dbConnect(PostgreSQL())
rs <- dbWriteTable(pg,c("ff","beme"), ff_beme,
                   overwrite=TRUE, row.names=FALSE)
sql <- paste0("
    COMMENT ON TABLE ff.beme IS
    'CREATED USING import_be_beme.R ON ", Sys.time() , "';")
rs <- dbGetQuery(pg, paste(sql, collapse="\n"))

rs <- dbGetQuery(pg, "VACUUM ff.beme")

################################################################################
#                   Download Fama-French BEME portfolio cutoffs                #
################################################################################

# Download the data and unzip it
ff.url <- paste(ff.url.partial, "ME_Breakpoints_TXT.zip", sep="/")
f <- tempfile()
download.file(ff.url, f)
file.list <- unzip(f, list=TRUE)
z <- unzip(f, files=as.character(file.list[1,1]))
# Parse the data
ff_me <-
    read.fwf(z,
             widths=c(4,2,5,rep(10,20)), header=FALSE,
             stringsAsFactors=FALSE, skip=1)
unlink(z)
names(ff_me) <- c("year", "month", "n", paste("p", seq(5, 100, 5), sep=""))

# Clean the data
for (i in 1:3) ff_me[,i] <- as.integer(trim(ff_me[,i]))
ff_me <- subset(ff_me, !is.na(year))
for (i in 4:(dim(ff_me)[2])) ff_me[,i] <- as.numeric(trim(ff_me[,i]))

rs <- dbWriteTable(pg,c("ff","me"), ff_me,
                   overwrite=TRUE, row.names=FALSE)
sql <- paste0("
    COMMENT ON TABLE ff.me IS
    'CREATED USING import_be_beme.R ON ", Sys.time() , "';")
rs <- dbGetQuery(pg, paste(sql, collapse="\n"))

rs <- dbGetQuery(pg, "VACUUM ff.me")

ff_me_quintiles <- ff_me[,c("year", "month", paste("p", seq(2,10,2), "0", sep=""))]
ff_me_quintiles$p0 <- 0

library(reshape)
ff_me_alt <- melt(ff_me_quintiles, id.vars=c("year", "month"))
names(ff_me_alt) <- c("year", "month", "quintile", "me")
ff_me_alt$quintile <- as.integer(gsub("^p", "", ff_me_alt$quintile))/20
ff_me_alt$quintile <- as.integer(ff_me_alt$quintile)
table(ff_me_alt$quintile)

rs <- dbWriteTable(pg,c("ff","me_alt"), ff_me_alt,
                   overwrite=TRUE, row.names=FALSE)
sql <- paste0("
    COMMENT ON TABLE ff.me_alt IS
    'CREATED USING import_be_beme.R ON ", Sys.time() , "';")
rs <- dbGetQuery(pg, paste(sql, collapse="\n"))

rs <- dbGetQuery(pg, "VACUUM ff.me_alt")

# Rearrange the BEME data ----
ff_beme_quintiles <- ff_beme[,c("year", paste("p", seq(2,10,2), "0", sep=""))]
ff_beme_quintiles$p0 <- -Inf

ff_beme_alt <- melt(ff_beme_quintiles, id.vars=c("year"))
names(ff_beme_alt) <- c("year", "quintile", "beme")
ff_beme_alt$quintile <- as.integer(gsub("^p", "", ff_beme_alt$quintile))/20
table(ff_beme_alt$quintile)

rs <- dbWriteTable(pg,c("ff","beme_alt"), ff_beme_alt,
                   overwrite=TRUE, row.names=FALSE)
sql <- paste0("
    COMMENT ON TABLE ff.beme_alt IS
    'CREATED USING import_be_beme.R ON ", Sys.time() , "';")
rs <- dbGetQuery(pg, paste(sql, collapse="\n"))

rs <- dbGetQuery(pg, "VACUUM ff.beme_alt")

rs <- dbDisconnect(pg)
