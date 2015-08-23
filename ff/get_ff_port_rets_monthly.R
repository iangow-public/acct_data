# Download Fama-French BEME portfolio returns ----
# The URL for the data.
ff.url.partial <- paste("http://mba.tuck.dartmouth.edu",
                        "pages/faculty/ken.french/ftp", sep="/")
ff.url <- paste(ff.url.partial, "25_Portfolios_5x5_TXT.zip", sep="/")
f <- tempfile()
download.file(ff.url, f)
file.list <- unzip(f) #, list=TRUE)

raw.data <- readLines(as.character(file.list))
unlink(file.list)

read.fwd <- function(text, widths) {
  # Function mimicks read.fwf, but on a vector of strings
  # rather than a file.
  
  end.col <- cumsum(widths)
  start.col <- c(0, end.col[1:(length(end.col)-1)])+1
  
  # Read substrings into columns
  temp <- NULL 
  for (i in 1:length(widths)) {
    temp <- cbind(temp, substr(text, start.col[i], end.col[i]))
  }
  
  # Return the resulting data frame
  return(data.frame(temp, stringsAsFactors=FALSE))
}

# Construct portfolio names
library(plyr)
d <-expand.grid(paste0("s",1:5), paste0("b", 1:5))
d <- mdply(d, 'paste0')
port_names <- d[,3]

# Extract value-weighted returns ----
first.line <- grep("Average Value Weighted Returns -- Monthly", raw.data)+3
last.line <- grep("Average Equal Weighted Returns -- Monthly", raw.data)-1

vwret.raw <- raw.data[first.line:last.line]
vwret <- read.fwd(vwret.raw, widths=c(6,rep(7,25)))

names(vwret) <- c("month", port_names)
vwret$year <- as.integer(substr(vwret$month,1,4))
vwret$month <- as.integer(substr(vwret$month,5,6))
for (i in 2:(dim(vwret)[2]-1)) {
  vwret[,i] <- as.numeric(vwret[,i])/100
}

# Extract equal-weighted returns ----
first.line <- grep("Average Equal Weighted Returns -- Monthly", raw.data)+3
last.line <- grep("Average Value Weighted Returns -- Annual", raw.data)-1

ewret.raw <- raw.data[first.line:last.line]
ewret <- read.fwd(ewret.raw, widths=c(6,rep(7,25)))

names(ewret) <- c("month", port_names)
ewret$year <- as.integer(substr(ewret$month,1,4))
ewret$month <- as.integer(substr(ewret$month,5,6))
for (i in 2:(dim(ewret)[2]-1)) {
  ewret[,i] <- as.numeric(ewret[,i])/100
}

# Rearrange and merge the data ----
library(reshape)

ewret_alt <- melt(subset(ewret, !is.na(month)), id.vars=c("year", "month"))
ewret_alt$me <- gsub("s([1-5]).*", "\\1", ewret_alt$variable )
ewret_alt$beme <- gsub(".*b([1-5])", "\\1", ewret_alt$variable )
ewret_alt$variable <- NULL
names(ewret_alt)[3] <- "ewret"

vwret_alt <- melt(subset(vwret, !is.na(month)),id.vars=c("year", "month"))
vwret_alt$me <- gsub("s([1-5]).*", "\\1", vwret_alt$variable )
vwret_alt$beme <- gsub(".*b([1-5])", "\\1", vwret_alt$variable )
vwret_alt$variable <- NULL
names(vwret_alt)[3] <- "vwret"

ff25 <- merge(vwret_alt, ewret_alt, by=c("year", "month", "me", "beme"))
ff25$beme <- as.integer(ff25$beme)
ff25$me <- as.integer(ff25$me)
ff25 <- ff25[order(ff25$year, ff25$month), ]
# Put data into the database ----
library(RPostgreSQL)
drv <- dbDriver("PostgreSQL")
pg <- dbConnect(drv, dbname = "crsp") # , port=5433, host="localhost")
rs <- dbWriteTable(pg,c("ff","ff25_mo"), ff25, 
                   overwrite=TRUE, row.names=FALSE)
rs <- dbGetQuery(pg, "ALTER TABLE ff.ff25_mo OWNER TO activism")

sql <- paste0("
    COMMENT ON TABLE ff.ff25_mo IS
    'CREATED USING get_ff_port_rets_monthly.R ON ", Sys.time() , "';")
rs <- dbGetQuery(pg, paste(sql, collapse="\n"))

rs <- dbGetQuery(pg, "VACUUM ff.ff25_mo")

# dbGetQuery(pg, "CREATE SCHEMA ff")
dbDisconnect(pg)
