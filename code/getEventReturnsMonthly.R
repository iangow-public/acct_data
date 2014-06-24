# The following function takes a list of permnos and event dates, then for each
# calls the function above to get event returns for each PERMNO-event date
# combination.
getEventReturnsMonthly <- function(permno, event.date, start.month=0, end.month=0,
                                  end.event.date=NULL, label="ret") {
  
    require(RPostgreSQL)

    event.date <- as.Date(event.date)
    permno <- as.integer(permno)

    # If there is no end event date, just measure the last date as end.months
    # from the event date.
    if (is.null(end.event.date)) { 
      no.end.date <- TRUE
      end.event.date <- event.date }
    else {
      no.end.date <- FALSE
    }
    end.event.date <- as.Date(end.event.date)

    # Push the data on events up to PostgreSQL
    drv <- dbDriver("PostgreSQL")
    crsp <- dbConnect(drv)
    max_date <- dbGetQuery(crsp, "SELECT max(date) AS date FROM crsp.msf")$date
    
    temp <- data.frame(permno, event_date=event.date, end_event_date=end.event.date)
    
    dbWriteTable(crsp, "permnos",
                 subset(temp, subset=!is.na(permno) & !is.na(event.date)),
                 row.names=FALSE, overwrite=TRUE)

    sql <- paste("
        WITH dates AS (
             SELECT DISTINCT permno, event_date, 
                date_trunc('MONTH', event_date) + ", start.month,
                    " * interval '1 month' AS begin_date, 
                eomonth(end_event_date) + ", end.month, "* interval '1 month' AS end_date 
            FROM permnos)
        SELECT a.permno, a.event_date, a.end_date,
            product(1+ret)-1 AS ret, 
            product(1+ret)-product(1+vwretd) AS ret_mkt,
            product(1+ret)-product(1+decret) AS ret_sz
        FROM dates AS a
        LEFT JOIN crsp.mrets AS b
        ON a.permno=b.permno AND b.date BETWEEN a.begin_date AND a.end_date
        GROUP BY a.permno, a.event_date, a.end_date")
    
    ret.data <- dbGetQuery(crsp, sql)
    
    dbGetQuery(crsp, "DROP TABLE IF EXISTS permnos")
    dbDisconnect(crsp)
    
    # Set returns to zero when CRSP end-date causes (something like) censoring
    after.max.date <- as.Date(ret.data$end_date) > max_date
    for (i in c("ret", "ret_mkt", "ret_sz")) {
        ret.data[after.max.date, i] <- NA
    }
    if (no.end.date) ret.data$end_date <- NULL
    
    # Label variables using label given appended to suffixes
    suffixes <- c("","_sz","_mkt")
    new.names <- paste(label, suffixes, sep="")
    names(ret.data) <- sub("^ret", label, names(ret.data), perl=TRUE)
    return(ret.data)
}

