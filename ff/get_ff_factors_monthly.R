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
ff.url <- paste(ff.url.partial, "F-F_Research_Data_Factors_TXT.zip", sep="/")
f <- tempfile()
download.file(ff.url, f)
file.list <- unzip(f, list=TRUE)
z <-unzip(f, files=as.character(file.list[1,1]))
# Parse the data
ff_monthly_factors <-
    read.fwf(z,
             widths=c(4,2,8,8,8,8), header=FALSE,
             stringsAsFactors=FALSE, skip=4)
unlink(z)
last.line <- grep("Ann", ff_monthly_factors[,1])-2
ff_monthly_factors <- ff_monthly_factors[1:last.line,]

# Clean the data
names(ff_monthly_factors) <- c("year", "month", "mktrf", "smb", "hml", "rf")
ff_monthly_factors$date <- as.Date(paste0(ff_monthly_factors$year, "-",
                                          ff_monthly_factors$month,"-01"))
for (i in 1:6) ff_monthly_factors[,i] <- as.numeric(trim(ff_monthly_factors[,i]))
for (i in 3:5) ff_monthly_factors[,i] <- ff_monthly_factors[,i]/100

################################################################################
#               Now download UMD (momentum) factor data                        #
################################################################################


# Download the data and unzip it
ff.url <- paste(ff.url.partial, "F-F_Momentum_Factor_TXT.zip", sep="/")
f <- tempfile()
download.file(ff.url, f)
file.list <- unzip(f, list=TRUE)
z <- unzip(f, files=as.character(file.list[1,1]))
# Parse the data
temp <- readLines(z)
unlink(z)
first.line <- grep("^Missing", temp)+3
last.line <- grep("^Annual", temp)-2
z <- unzip(f, files=as.character(file.list[1,1]))
ff_mom_factor <-read.fwf(z, widths=c(4,2,8), header=FALSE,
                         stringsAsFactors=FALSE, skip=first.line-1)
unlink(z)
ff_mom_factor <- ff_mom_factor[1:(last.line-first.line+1),]

# Clean the data
names(ff_mom_factor) <- c("year", "month", "umd")
ff_mom_factor$date <- as.Date(paste0(ff_mom_factor$year, "-",
                                     ff_mom_factor$month,"-01"))
for (i in 1:2) {
  ff_mom_factor[,i] <- as.integer(ff_mom_factor[,i])
}
ff_mom_factor$umd <- as.numeric(trim(ff_mom_factor$umd))/100

################################################################################
#                        Merge all the factor data                             #
################################################################################
ff_monthly_factors <-
    merge(ff_monthly_factors, subset(ff_mom_factor, select=-date),
          by=c("year", "month"), all.x=TRUE)
ff_monthly_factors <- subset(ff_monthly_factors, subset=!is.na(date))

################################################################################
#                      Load the data into my database                          #
################################################################################
library(RPostgreSQL)
pg <- dbConnect(PostgreSQL())
rs <- dbWriteTable(pg,c("ff","factors_monthly"), ff_monthly_factors,
                   overwrite=TRUE, row.names=FALSE)

sql <- paste0("
    COMMENT ON TABLE ff.factors_monthly IS
    'CREATED USING get_ff_factors_monthly.R ON ", Sys.time() , "';")
rs <- dbGetQuery(pg, paste(sql, collapse="\n"))

rs <- dbGetQuery(pg, "VACUUM ff.factors_monthly")
rs <- dbDisconnect(pg)
