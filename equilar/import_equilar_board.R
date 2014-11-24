#    user  system elapsed
#  60.678   2.379 303.467
dropbox.path <- path.expand("~/Dropbox/")

# library(gdata)
# The locations of the files that will be imported, as well as where the
# files created will be saved.

equilar.path <- paste(dropbox.path, "data/equilar/board/",sep="")

# A function to read in text files and clean them up a bit
getTemp <- function(suffix) {
  # Read in the text files with the data
  file.name <- paste(equilar.path,"gzip/equilar_",suffix,"_",i,".csv.gz",sep="")
  temp <- read.csv(file.name, as.is=TRUE, header=TRUE,
    na.strings=c("N/A","N/M"))

  # Replace periods (.) with underscores (_) in variable names
  names(temp) <- gsub("\\.+","_",names(temp),perl=TRUE)
  names(temp) <- gsub("_$","",names(temp),perl=TRUE)
  names(temp) <- gsub("123_R","123R",names(temp),perl=TRUE)
  names(temp) <- gsub("^Discloure_Flag$","Disclosure_Flag",names(temp),perl=TRUE)

  # Some earlier years are missing fields supplied in later years.
  # This code adds these fields, and makes them NA in earlier years
  temp$fileyear <- as.integer(i)
  if (suffix=="director") {
      temp[,setdiff(names(director),names(temp))] <- NA
  }

  if (suffix=="co_fin") {
    temp[,setdiff(names(co_fin),names(temp))] <- NA
  }
  return(temp)
}

# Loop through files for each year
# Initialize the variables
director <- committee <- board <- co_fin <-NULL
for (i in 2012:2000) { # I go backwards, as later years have more variables.
    cat(paste("Year ",i,": Director,", sep=""))
    director <- rbind(director, getTemp("director") )
    cat(" Board,")
	board <- rbind(board, getTemp("board"))
	cat(" Committee,")
	committee <- rbind(committee, getTemp("committee"))
    cat(" Co_fin\n")
	co_fin <- rbind(co_fin, getTemp("co_fin"))
}

# There are some data issues evident in the original Excel files
# for one year. This codes these as NAs
director$Term_Expiration[director$Term_Expiration=="01/01/0001"] <- NA

# Rename some variables for clarity
director$Percent_Shares_Owned <- director$X_Shares_Owned
director$Options_Exable_in_60_Days <- director$Options_Execisable_within_60_Days
director$X_Shares_Owned <- NULL
director$Options_Execisable_within_60_Days <- NULL

# Fix CUSIPs
trim <- function(str) {
  str <- gsub("^\\s+", "", str)
  str <- gsub("\\s+$", "", str)
  return(str)
}

source(paste(dropbox.path,"data/equilar/fix.cusips.R",sep=""))
co_fin$CUSIP <- fix.cusips(co_fin$CUSIP)
# co_fin[co_fin$CUSIP=="92861LACA",] seems to be a dud CUSIP, but I couldn't
# find a match on Compustat for the issuer (which checks out on the CUSIP file)
# in any case.

# source(paste(dropbox.path,"research/AGL/Code/R/get.gvkey.permno.R",sep=""))
# co_fin[c("permno","gvkey")] <-
#    get.gvkey.permno(co_fin$CUSIP, co_fin$FY_End)

# Generate indicator variables for committee memberships
director$Comp_Chair <- grepl("Compensation\\*",director$Committees)
director$Comp_Committee <- grepl("Compensation",director$Committees)
director$Audit_Chair <- grepl("Audit\\*",director$Committees)
director$Audit_Committee <- grepl("Audit",director$Committees)

board$FY_End <- as.Date(board$FY_End)
committee$FY_End <- as.Date(committee$FY_End)
director$FY_End <- as.Date(director$FY_End)
director$Year_Joined_Board <- as.Date(director$Year_Joined_Board)
director$Term_Expiration <- as.Date(director$Term_Expiration)
co_fin$FY_End <- as.Date(co_fin$FY_End)
co_fin$Shares_Outstanding_Date <- as.Date(co_fin$Shares_Outstanding_Date)
names(co_fin) <- tolower(names(co_fin))
names(director) <- tolower(names(director))
names(board) <- tolower(names(board))
names(committee) <- tolower(names(committee))
# co_fin$permno <- as.integer(co_fin$permno)

# Save the files in R's .Rdata format
# save(co_fin, director, board, committee,
#		 file=paste(equilar.path,"board.Rdata",sep=""))

# Save the files to a PostgreSQL database
# load(paste(equilar.path,"board.Rdata",sep=""))
library(RPostgreSQL)
drv <- dbDriver("PostgreSQL")
pg <- dbConnect(drv, dbname = "crsp")

# dbGetQuery(pg, "CREATE SCHEMA board")
dbWriteTable(pg, c("board", "board"), board,row.names=FALSE, overwrite=TRUE)
dbWriteTable(pg, c("board","committee"), committee, row.names=FALSE, overwrite=TRUE)
dbWriteTable(pg, c("board","director"), director, row.names=FALSE, overwrite=TRUE)
dbWriteTable(pg, c("board","co_fin"), co_fin, row.names=FALSE, overwrite=TRUE)

dbGetQuery(pg, "SET maintenance_work_mem='1GB'")
dbGetQuery(pg,"CREATE INDEX ON board.board (company_id)")
dbGetQuery(pg,"CREATE INDEX ON board.committee (company_id)")
dbGetQuery(pg,"CREATE INDEX ON board.director (company_id)")
dbGetQuery(pg,"CREATE INDEX ON board.co_fin (company_id)")

dbGetQuery(pg, "DELETE FROM board.co_fin WHERE company_id =''");
# dbGetQuery(pg,"SELECT * FROM board.director WHERE company_id='';")
# dbGetQuery(pg,"DELETE FROM board.director WHERE company_id='';")
# dbGetQuery(pg,"SELECT * FROM board.board WHERE company_id='';")
# dbGetQuery(pg,"DELETE FROM board.board WHERE company_id='';")

rs <- dbDisconnect(pg)
rs <- dbUnloadDriver(drv)
system("~/Dropbox/data/equilar/process_names.pl")
