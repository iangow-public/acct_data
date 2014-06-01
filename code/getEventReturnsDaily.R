# Load up the PostgreSQL driver, create a connection to the database
library(RPostgreSQL)

# The following function takes a list of permnos and event dates, then for each
# calls the function above to get event returns for each PERMNO-event date
# combination.
getEventReturns <- function(permno, event.date, days.before=0, days.after=0, 
                            end.event.date=NULL, label="ret") {
    event.date <- as.Date(event.date)
    if (is.null(end.event.date)) { end.event.date <- event.date }
    end.event.date <- as.Date(end.event.date)
    
    permno <- as.integer(permno)
    drv <- dbDriver("PostgreSQL")
    crsp <- dbConnect(drv)

    max_date <- dbGetQuery(crsp, "SELECT max(date) AS date FROM crsp.dsf")$date
    
    temp <- data.frame(permno, event_date=event.date, end_event_date=end.event.date)

    dbWriteTable(crsp,"permnos",
                 subset(temp, subset=!is.na(permno) & !is.na(event.date)),
                 row.names=FALSE, overwrite=TRUE)
    
    sql <- paste("
        WITH permnos_mem AS 
          (SELECT DISTINCT * FROM permnos)
        SELECT a.permno, a.event_date, a.end_event_date, 
            product(1+ret)-1 AS ret, 
            product(1+ret)-product(1+vwretd) AS ret_mkt,
            product(1+ret)-product(1+decret) AS ret_sz
        FROM (
            SELECT a.permno, a.event_date, a.end_event_date,
              c.date AS begin_date, d.date AS end_date
            FROM permnos_mem AS a, crsp.anncdates AS b, crsp.trading_dates AS c, 
                crsp.trading_dates AS d, crsp.anncdates AS e
            WHERE a.event_date=b.anncdate AND b.td + ", days.before, "= c.td AND
                a.end_event_date=e.anncdate AND e.td + ", days.after,"=d.td
                AND c.date IS NOT NULL AND d.date IS NOT NULL) AS a
        INNER JOIN crsp.rets AS b
        USING (permno) 
        WHERE b.date BETWEEN a.begin_date AND a.end_date
        GROUP BY a.permno, event_date, end_event_date")
    # cat(sql)
    ret.data <- dbGetQuery(crsp, sql)
    dbGetQuery(crsp, "DROP TABLE IF EXISTS permnos")

    after.max.date <- ret.data$end_event_date > max_date
    # print(max_date)
    if (length(after.max.date) > 0) {
        for (i in c("ret", "ret_mkt", "ret_sz")) {
            ret.data[after.max.date, i] <- NA
        }
    }
    dbDisconnect(crsp)
    
    # Label variables using label given appended to suffixes
    suffixes <- c("", "_sz", "_mkt")
    new.names <- paste(label, suffixes, sep="")
    names(ret.data) <- sub("^ret", label, names(ret.data), perl=TRUE)
    return(ret.data)
}
