# Download Fama-French BEME portfolio returns ----
# The URL for the data.
ff.url.partial <- paste("http://mba.tuck.dartmouth.edu",
                        "pages/faculty/ken.french/ftp", sep="/")

ff.url <- paste(ff.url.partial, "25_Portfolios_5x5_TXT.zip", sep="/")
f <- tempfile()
download.file(ff.url, f)
file.list <- unzip(f, list=TRUE)

raw.data <- readLines(file.list[1,1])
unlist(file.list[1,1])

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
first.line <- grep("Average Value Weighted Returns -- Annual", raw.data)+3
last.line <- grep("Average Equal Weighted Returns -- Annual", raw.data)-1

vwret.raw <- raw.data[first.line:last.line]
vwret <- read.fwd(vwret.raw, widths=c(6,rep(7,25)))

names(vwret) <- c("year", port_names)
vwret$year <- as.integer(vwret$year)
for (i in 2:(dim(vwret)[2])) {
  vwret[,i] <- as.numeric(vwret[,i])/100
}

# Extract equal-weighted returns ----
first.line <- grep("Average Equal Weighted Returns -- Annual", raw.data)+3
last.line <- grep("Number of Firms in Portfolios", raw.data)-1

ewret.raw <- raw.data[first.line:last.line]
ewret <- read.fwd(ewret.raw, widths=c(6,rep(7,25)))

names(ewret) <- c("year", port_names)
ewret$year <- as.integer(ewret$year)
for (i in 2:(dim(ewret)[2])) {
  ewret[,i] <- as.numeric(ewret[,i])/100
}

# Rearrange and merge the data ----
library(reshape)

ewret_alt <- melt(subset(ewret, !is.na(year)), id.vars="year")
ewret_alt$me <- gsub("s([1-5]).*", "\\1", ewret_alt$variable )
ewret_alt$beme <- gsub(".*b([1-5])", "\\1", ewret_alt$variable )
ewret_alt$variable <- NULL
names(ewret_alt)[2] <- "ewret"

vwret_alt <- melt(subset(vwret, !is.na(year)), id.vars="year")
vwret_alt$me <- gsub("s([1-5]).*", "\\1", vwret_alt$variable )
vwret_alt$beme <- gsub(".*b([1-5])", "\\1", vwret_alt$variable )
vwret_alt$variable <- NULL
names(vwret_alt)[2] <- "vwret"

ff25 <- merge(vwret_alt, ewret_alt, by=c("year", "me", "beme"))
ff25$beme <- as.integer(ff25$beme)
ff25$me <- as.integer(ff25$me)

# Put data into the database ----
library(RPostgreSQL)

pg <- dbConnect(PostgreSQL()) 
rs <- dbWriteTable(pg, c("ff", "ff25"), ff25, 
                   overwrite=TRUE, row.names=FALSE)
