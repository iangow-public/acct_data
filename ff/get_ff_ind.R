########################################################################
# Small program to fetch and organize Fama-French industry data.
# The idea is to make a table that could be used for SQL merges.
########################################################################

# The URL for the data.
ff.url <- paste("http://mba.tuck.dartmouth.edu", 
                "pages/faculty/ken.french/ftp",
                "Industry_Definitions.zip", sep="/")

# Download the data and unzip it
f <- tempfile() 
download.file(ff.url, f) 
file.list <- unzip(f,list=TRUE)

trim <- function(string) {
  # Remove leading and trailing spaces from a string
  ifelse(grepl("^\\s*$", string, perl=TRUE),"", 
         gsub("^\\s*(.*?)\\s*$","\\1",string,perl=TRUE))
}

# Function to do the heavy lifting
extract_ff_ind_data <- function (file) {
  
  # Read in the data in a plain form
  ff_ind <- as.vector(read.delim(unzip(f, files=file), header=FALSE, 
                                 stringsAsFactors=FALSE))
  
  # The first 10 characters of each line are the industry data, but only the first
  # row of the data for the SIC codes in an industry are filled in;
  # so fill in the rest.
  ind_num <- trim(substr(ff_ind[,1],1,10))
  for (i in 2:length(ind_num)) { 
    if (ind_num[i]=="") ind_num[i] <- ind_num[i-1]
  }
  
  # The rest of each line is either detail on an industry or details about the
  # range of SIC codes that fit in each industry with a label for each group
  # of SIC codes.
  sic_detail <- trim(substr(ff_ind[,1],11,100))
  
  # If the line doesn't start with a number, it's an industry description
  is.desc <- grepl("^\\D",sic_detail,perl=TRUE)
  
  # Pull out information from rows about industries
  regex.ind <- "^(\\d+)\\s+(\\w+).*$"
  ind_num <- gsub(regex.ind,"\\1",ind_num,perl=TRUE)
  ind_abbrev <- gsub(regex.ind,"\\2",ind_num[is.desc],perl=TRUE)
  ind_list <- data.frame(ind_num=ind_num[is.desc],ind_abbrev, 
                         ind_desc=sic_detail[is.desc])
  
  # Pull out information rows about ranges of SIC codes
  regex.sic <- "^(\\d+)-(\\d+)\\s*(.*)$"
  ind_num <- ind_num[!is.desc]
  sic_detail <- sic_detail[!is.desc]
  sic_low  <- as.integer(gsub(regex.sic,"\\1",sic_detail,perl=TRUE))
  sic_high <- as.integer(gsub(regex.sic,"\\2",sic_detail,perl=TRUE))
  sic_desc <- gsub(regex.sic,"\\3",sic_detail,perl=TRUE)
  sic_list <- data.frame(ind_num, sic_low, sic_high, sic_desc)
  
  return(merge(ind_list,sic_list,by="ind_num",all=TRUE))
}

# Load the data into my database
library(RPostgreSQL)
pg <- dbConnect(PostgreSQL())
# Extract the data of interest
for (i in c(12, 17, 48, 49)) {
  temp <- extract_ff_ind_data(paste0("Siccodes", i , ".txt"))
  rs <- dbWriteTable(pg,c("ff",paste0("ind_", i)), temp,
                     overwrite=TRUE, row.names=FALSE)
  
  rs <- dbGetQuery(pg, paste0("VACUUM ff.ind_", i))
  
  sql <- paste0("
    COMMENT ON TABLE ff.ind_", i, " IS
    'CREATED USING get_ff_ind.R ON ", Sys.time() , "';")
  rs <- dbGetQuery(pg, paste(sql, collapse="\n"))
}

rs <- dbDisconnect(pg)
