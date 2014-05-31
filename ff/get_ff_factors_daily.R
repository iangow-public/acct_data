########################################################################
# Small program to fetch and organize Fama-French factor data.
# The idea is to make a table that could be used for SQL merges.
########################################################################

# The URL for the data.
ff.url.partial <- paste("http://mba.tuck.dartmouth.edu",
                        "pages/faculty/ken.french/ftp", sep="/")

# Function to remove leading and trailing spaces from a string
trim <- function(string) {
    ifelse(grepl("^\\s*$", string, perl=TRUE),"",
				gsub("^\\s*(.*?)\\s*$","\\1", string, perl=TRUE))
}

################################################################################
#             First download Fama-French three-factor data                     #
################################################################################

# Download the data and unzip it
ff.url <- paste(ff.url.partial, "F-F_Research_Data_Factors_daily.zip", sep="/")
f <- tempfile()
download.file(ff.url, f)
file.list <- unzip(f, list=TRUE)

# Parse the data
ff_daily_factors <-
    read.fwf(unzip(f, files=as.character(file.list[1,1])),
             widths=c(8,8,8,8,10), header=FALSE,
             stringsAsFactors=FALSE, skip=5)

# Clean the data
for (i in 2:5) ff_daily_factors[,i] <- as.numeric(trim(ff_daily_factors[,i]))
for (i in 2:4) ff_daily_factors[,i] <- ff_daily_factors[,i]/100
names(ff_daily_factors) <- c("date", "mktrf", "smb", "hml", "rf")
ff_daily_factors$date <- as.Date(ff_daily_factors$date, format="%Y%m%d")

################################################################################
#               Now download UMD (momentum) factor data                        #
################################################################################


# Download the data and unzip it
ff.url <- paste(ff.url.partial, "F-F_Momentum_Factor_daily.zip", sep="/")
f <- tempfile()
download.file(ff.url, f)
file.list <- unzip(f, list=TRUE)

# Parse the data
ff_mom_factor <-
    read.fwf(unzip(f, files=as.character(file.list[1,1])),
             widths=c(8,8), header=FALSE,
             stringsAsFactors=FALSE, skip=14)

# Clean the data
ff_mom_factor[,2] <- as.numeric(trim(ff_mom_factor[,2]))/100
names(ff_mom_factor) <- c("date", "umd")
ff_mom_factor$date <- as.Date(ff_mom_factor$date, format="%Y%m%d")

################################################################################
#                        Merge all the factor data                             #
################################################################################
ff_daily_factors <- 
    merge(ff_daily_factors, ff_mom_factor, by="date", all.x=TRUE)
ff_daily_factors <- subset(ff_daily_factors, subset=!is.na(date))

################################################################################
#                      Load the data into my database                          #
################################################################################ 
library(RPostgreSQL)
drv <- dbDriver("PostgreSQL")
pg <- dbConnect(drv, dbname = "crsp")
rs <- dbWriteTable(pg,c("ff","factors_daily"), ff_daily_factors, 
                   overwrite=TRUE, row.names=FALSE)


rs <- dbGetQuery(pg, "ALTER TABLE ff.factors_daily OWNER TO activism")
sql <- paste0("
    COMMENT ON TABLE ff.factors_daily IS
    'CREATED USING get_ff_factors_daily.R ON ", Sys.time() , "';")
rs <- dbGetQuery(pg, paste(sql, collapse="\n"))

rs <- dbGetQuery(pg, "VACUUM ff.factors_daily")
rs <- dbDisconnect(pg)