dropbox.path <- path.expand("~/Dropbox")
# path.expand("/afs/ir.stanford.edu/data/gsb/corpgov/")

# The locations of the files that will be imported, as well as where the
# files created will be saved.
equilar.path <- file.path(dropbox.path, "data/equilar/executive/",sep="")

# A function to read in text files and clean them up a bit
getTemp <- function(suffix) {
    # Read in the text files with the data
    file.name <-
        paste(equilar.path,"/gzip/equilar_",suffix,"_",i,".csv.gz",sep="")
    cat(paste("Importing", file.name, "\n"))
	    temp <- read.csv(file.name, as.is=TRUE, header=TRUE,
        na.strings="N/A",row.names=NULL)

    # Replace periods (.) with underscores (_) in variable names
    names(temp) <- gsub("\\.+","_",names(temp),perl=TRUE)
    names(temp) <- gsub("_$","",names(temp),perl=TRUE)
    temp$fileyear <- i

    # Only keep the "splits" field on co_fin table
    temp$Splits <- NULL
    return(temp)
}

# Loop through files for each year
# (First, initialize variables for dataframes that will be created)
option <- ltip <- executive <- NULL
for (i in 2000:2008) {
    # Only ND data for 2009, 2010 and 2011
    option <- rbind(option ,getTemp("option") )
	ltip <- rbind(ltip ,getTemp("ltip") )
    executive <- rbind(executive ,getTemp("executive") )
}

# Loop through files for each of "new disclosure" data
equity_nd <- stock_nd <- option_nd <- ip_nd <- executive_nd <- NULL
for (i in 2006:2012) {
  if (i < 2011) {
    for (j in 1:3) {
      # There are 3 files for each year before 2011
      temp <- getTemp(paste("equity_nd_",j,sep=""))
      equity_nd <- rbind(equity_nd, temp)
    }
  } else {
    # Rename variables to match names from prior years
    temp <- getTemp("equity_nd")
    equity_nd <- rbind(equity_nd, temp)
  }

	stock_nd <- rbind(stock_nd, getTemp("stock_nd"))
 	option_nd <- rbind(option_nd, getTemp("option_nd"))
 	ip_nd <- rbind(ip_nd, getTemp("ip_nd"))
  executive_nd <- rbind(executive_nd, getTemp("executive_nd"))
}

# Rename some variables ("option" and "type" are PostgreSQL keywords).
option_od <- option
rm(option)
option_od$option_type <- option_od$type
option_od$type <- NULL
option_nd$option_type <- option_nd$type
option_nd$type <- NULL
stock_nd$security_type <- stock_nd$type
stock_nd$type <- NULL
ip_nd$ip_type <- ip_nd$type
ip_nd$type <- NULL

table.list <- c("option_od", "ltip", "executive", "equity_nd", "stock_nd",
							 "option_nd", "ip_nd", "executive_nd")

# Convert variables to Date format.
option_od$FY_End <- as.Date(option_od$FY_End)
option_od$Grant_Date <- as.Date(option_od$Grant_Date)
option_od$Expiration_Date <- as.Date(option_od$Expiration_Date)
ltip$FY_End <- as.Date(ltip$FY_End)
executive$FY_End <- as.Date(executive$FY_End)
executive$Resignation_Date <- as.Date(executive$Resignation_Date)
executive_nd$FY_End <- as.Date(executive_nd$FY_End)
executive_nd$Resignation_Date <- as.Date(executive_nd$Resignation_Date)
equity_nd$FY_End <- as.Date(equity_nd$FY_End)
stock_nd$FY_End <- as.Date(stock_nd$FY_End)
stock_nd$Grant_Date <- as.Date(stock_nd$Grant_Date)
option_nd$FY_End <- as.Date(option_nd$FY_End)
option_nd$Expiration_Date <- as.Date(option_nd$Expiration_Date)
option_nd$Grant_Date <- as.Date(option_nd$Grant_Date)
ip_nd$FY_End <- as.Date(ip_nd$FY_End)
ip_nd$Grant_Date <- as.Date(ip_nd$Grant_Date)

# Save the files in R's .Rdata format
# save(option_od, ltip, executive, equity_nd, stock_nd, option_nd,
# 		 ip_nd, executive_nd,
# 	file=paste(equilar.path,"executive.Rdata",sep=""))

# Save the files to a PostgreSQL database
library(RPostgreSQL)
drv <- dbDriver("PostgreSQL")
pg <- dbConnect(drv, dbname = "crsp")

# dbGetQuery(pg, "CREATE SCHEMA executive")
for (data.table.name in table.list) {
	data.table <- eval(parse(text=data.table.name))
	names(data.table) <- tolower(names(data.table))
  rs <- dbWriteTable(pg, c("executive",data.table.name),
                     data.table, overwrite=TRUE, row.names=FALSE)
  cat(paste("Created PostgreSQL table ",
              data.table.name,": ",rs, "\n", sep=""))
}

rs <- dbGetQuery(pg, "
  DELETE FROM  executive.executive_nd WHERE fy_end IS NULL;
  DELETE FROM  executive.equity_nd WHERE fy_end IS NULL;
  DELETE FROM  executive.option_nd WHERE fy_end IS NULL;
  DELETE FROM  executive.stock_nd WHERE fy_end IS NULL")

rs <- dbDisconnect(pg)
dbUnloadDriver(drv)
rm(pg)
