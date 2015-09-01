

read.fwd <- function(text, widths, na.strings) {
  # Function mimicks read.fwf, but on a vector of strings
  # rather than a file.
  
  end.col <- cumsum(widths)
  start.col <- c(0, end.col[1:(length(end.col)-1)])+1
  
  # Read substrings into columns
  temp <- NULL 
  for (i in 1:length(widths)) {
      val <- substr(text, start.col[i], end.col[i])
      val[grepl(na.strings, val) ] <- NA
      temp <- cbind(temp, val)
  }
  
  # Return the resulting data frame
  return(data.frame(temp, stringsAsFactors=FALSE))
}

get_ind_return_data <- function(ind) {
    # Download Fama-French industry returns ----
    # The URL for the data.
    ff.url.partial <- paste("http://mba.tuck.dartmouth.edu",
                            "pages/faculty/ken.french/ftp", sep="/")
    ff.url <- paste0(ff.url.partial, "/", ind, "_Industry_Portfolios_TXT.zip")
    f <- tempfile()
    download.file(ff.url, f)
    file.list <- unzip(f) #, list=TRUE)
    
    raw.data <- readLines(as.character(file.list))
    unlink(file.list)
    # return(raw.data)
    # Construct portfolio names
    library(plyr)
    port_names <- 1:ind
    
    # Extract value-weighted returns ----
    first.line <- grep("Average Value Weighted Returns -- Monthly", raw.data)+3
    last.line <- grep("Average Equal Weighted Returns -- Monthly", raw.data)-1
    
    vwret.raw <- raw.data[first.line:last.line]
    vwret <- read.fwd(vwret.raw, widths=c(6,rep(7, ind)),
                      na.strings ="\\s*-99.99")
    
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
    ewret <- read.fwd(ewret.raw, widths=c(6,rep(7, ind)),
                      na.strings ="\\s*-99.99")
    
    names(ewret) <- c("month", port_names)
    ewret$year <- as.integer(substr(ewret$month,1,4))
    ewret$month <- as.integer(substr(ewret$month,5,6))
    for (i in 2:(dim(ewret)[2]-1)) {
      ewret[,i] <- as.numeric(ewret[,i])/100
    }
    
    # Rearrange and merge the data ----
    library(reshape2)
    
    ewret_alt <- melt(subset(ewret, !is.na(month)), 
                      id.vars=c("year", "month"))
    names(ewret_alt)[3] <- "ind_num"
    names(ewret_alt)[4] <- "ewret"
    
    vwret_alt <- melt(subset(vwret, !is.na(month)),
                      id.vars=c("year", "month"))
    names(vwret_alt)[3] <- "ind_num"
    names(vwret_alt)[4] <- "vwret"
    
    ff_ind <- merge(vwret_alt, ewret_alt, by=c("year", "month", "ind_num"))
    ff_ind <- ff_ind[order(ff_ind$year, ff_ind$month, ff_ind$ind_num), ]

    # Put data into the database ----
    library(RPostgreSQL)
    pg <- dbConnect(PostgreSQL())
    tab_nam <- paste0("ff_ind", ind, "_mo")
    rs <- dbWriteTable(pg, c("ff", tab_nam), ff_ind, 
                       overwrite=TRUE, row.names=FALSE)
    rs <- dbGetQuery(pg, paste0("GRANT SELECT ON ff.", tab_nam, " TO crsp_basic"))
    
    sql <- paste0("
        COMMENT ON TABLE ff.", tab_nam, " IS
        'CREATED USING get_ff_ind_rets_monthly.R ON ", Sys.time() , "';")
    rs <- dbGetQuery(pg, paste(sql, collapse="\n"))
    
    rs <- dbGetQuery(pg, paste0("CREATE INDEX ON ff.", tab_nam, " (ind_num)"))
    rs <- dbGetQuery(pg, paste0("VACUUM ff.", tab_nam))
    
    dbDisconnect(pg)
}

lapply(c(12, 17, 48, 49),  get_ind_return_data)


