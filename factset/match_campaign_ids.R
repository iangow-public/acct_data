# Get corrected data on board-related activism from Google Sheets document ----

# Function to retrieve a Google Sheets document
getSheetData = function(key, gid=NULL) {
    library(RCurl)
    url <- paste0("https://docs.google.com/spreadsheets/d/", key,
                  "/export?format=csv&id=", key, if (is.null(gid)) "" else paste0("&gid=", gid),
                  "&single=true")
    csv_file <- getURL(url, verbose=FALSE)
    the_data <- read.csv(textConnection(csv_file), as.is=TRUE)
    return( the_data )
}


# Get PERMNO-CIK data
key='1EwA6xCOPV2DgUNc5REasufqtczvmJo4vX77dbgT83kk'

#### Sharkwatch 50 ####
# Import Dataset from Google Drive ----
manual_matched <- getSheetData(key, gid=1213453107)

manual_matched <- subset(manual_matched, !is.na(campaign_id), 
                     select=c(cusip_9_digit, dissident_group, announce_date,
                              campaign_id))
manual_matched$announce_date <- as.Date(manual_matched$announce_date)

library(RPostgreSQL)
pg <- dbConnect(PostgreSQL())

sql <- "
    WITH unique_old AS (
        SELECT announce_date, cusip_9_digit
        FROM factset.sharkwatch_old
        GROUP BY announce_date, cusip_9_digit
        HAVING COUNT(DISTINCT dissident_group)=1),
    old_events AS (
        SELECT announce_date, cusip_9_digit, 
            regexp_split_to_array(regexp_replace(dissident_group_with_sharkwatch50, 
                '\\s+SharkWatch50\\?:\\s+(Yes|No)', '', 'g'), E'Dissident Group: ') AS dissidents_old
        FROM factset.sharkwatch_old
        INNER JOIN unique_old
        USING (announce_date, cusip_9_digit)),
    
    unique_new AS (
        SELECT announce_date, cusip_9_digit
        FROM factset.sharkwatch_new
        GROUP BY announce_date, cusip_9_digit
        HAVING COUNT(DISTINCT dissident_group)=1),
    
    new_events AS (
        SELECT announce_date, cusip_9_digit, 
            regexp_split_to_array(regexp_replace(dissident_group_with_sharkwatch50, 
                '\\s+SharkWatch50\\?:\\s+(Yes|No)', '', 'g'), E'Dissident Group: ') AS dissidents_new
        FROM factset.sharkwatch_new
        INNER JOIN unique_new
        USING (announce_date, cusip_9_digit)),
    
    dissident_name_changes AS (
        SELECT DISTINCT 
            unnest(dissidents_old) AS dissident_old, 
            unnest(dissidents_new) AS dissident_new
        FROM old_events
        INNER JOIN new_events
        USING (announce_date, cusip_9_digit)
        WHERE NOT (dissidents_new @> dissidents_old) 
            AND array_length(dissidents_old, 1)=2
            AND array_length(dissidents_new, 1)=2),
    
    sharkwatch_old AS (
        SELECT cusip_9_digit, COALESCE(dissident_new, dissident_group) AS dissident_group,
                dissident_group AS dissident_group_old,
                announce_date, company_name
        FROM factset.sharkwatch_old AS a
        INNER JOIN dissident_name_changes AS b
        ON a.dissident_group=b.dissident_old)

    SELECT cusip_9_digit, dissident_group_old AS dissident_group, 
        announce_date, campaign_id
    FROM factset.sharkwatch_new AS a
    RIGHT JOIN sharkwatch_old AS b
    USING (cusip_9_digit, dissident_group, announce_date)
    WHERE cusip_9_digit IS NOT NULL AND campaign_id IS NOT NULL
    ORDER BY cusip_9_digit, dissident_group, announce_date"

auto_matched <- dbGetQuery(pg, sql)

sql <- "
    SELECT DISTINCT b.cusip_9_digit, dissident_group, announce_date, campaign_id
    FROM factset.sharkwatch_new AS a
    INNER JOIN factset.sharkwatch_old AS b
    USING (company_name, dissident_group, announce_date)
    WHERE a.cusip_9_digit != b.cusip_9_digit AND campaign_id IS NOT NULL
    ORDER BY dissident_group, announce_date"

cusip_changes <- dbGetQuery(pg, sql)

sql <- "
    WITH unmatched AS (
        SELECT cusip_9_digit, dissident_group, announce_date
        FROM factset.sharkwatch_old AS b
        LEFT JOIN factset.campaign_ids AS c
        USING (dissident_group, cusip_9_digit, announce_date)
        WHERE campaign_id IS NULL)
    SELECT DISTINCT cusip_9_digit, b.dissident_group, announce_date, campaign_id,
        a.dissident_group AS dissident_group_new
    FROM factset.sharkwatch_new AS a
    INNER JOIN unmatched AS b
    USING (cusip_9_digit, announce_date)
    WHERE a.dissident_group != b.dissident_group AND a.campaign_id IS NOT NULL
    ORDER BY cusip_9_digit, announce_date"

dissident_changes <- dbGetQuery(pg, sql)


write.csv(dissident_changes, 
          file="~/Google Drive/activism/data/dissident_changes.csv")

csv_file <- getURL(paste0("https://docs.google.com/spreadsheet/pub?",
                          "key=0AvP4wvS7Nk-QdGRjNFdtZ1dUbTRNS0FIQnhCLXZobWc", 
                          "&single=true&gid=2&output=csv"),
                   verbose=FALSE)
dissident_changes_checked <- read.csv(textConnection(csv_file), as.is=TRUE)
dissident_changes_checked$announce_date <-
    as.Date(dissident_changes_checked$announce_date)
dissident_changes_checked$announce_date <- as.Date(dissident_changes_checked$announce_date)
dissident_changes_checked <- subset(dissident_changes_checked,
                                    subset=match,
                                    select=c(cusip_9_digit, dissident_group, announce_date, campaign_id))

sql <- "
    WITH unmatched AS (
        SELECT cusip_9_digit, dissident_group, announce_date
        FROM factset.sharkwatch_old AS b
        LEFT JOIN factset.campaign_ids AS c
        USING (dissident_group, cusip_9_digit, announce_date)
        WHERE campaign_id IS NULL)
    SELECT DISTINCT cusip_9_digit, dissident_group, b.announce_date, campaign_id,
        a.announce_date AS announce_date_new
    FROM factset.sharkwatch_new AS a
    INNER JOIN unmatched AS b
    USING (cusip_9_digit, dissident_group)
    WHERE a.announce_date != b.announce_date AND a.campaign_id IS NOT NULL
    ORDER BY cusip_9_digit, dissident_group"

date_changes <- dbGetQuery(pg, sql)

sql <- "
    SELECT cusip_9_digit, dissident_group, announce_date, campaign_id
    FROM factset.sharkwatch_new AS a
    INNER JOIN factset.sharkwatch_old AS b
    USING (cusip_9_digit, dissident_group, announce_date)
    WHERE cusip_9_digit IS NOT NULL AND campaign_id IS NOT NULL
    ORDER BY cusip_9_digit, dissident_group, announce_date"

still_matched <- dbGetQuery(pg, sql)


other_unmatched <- getSheetData(key, gid=834461479)
other_unmatched$announce_date <- as.Date(other_unmatched$announce_date)

all_matches <- rbind(other_unmatched, still_matched, auto_matched, 
                     manual_matched, cusip_changes, dissident_changes_checked)

all_matches <- unique(all_matches)
rs <- dbWriteTable(pg, name=c("factset", "campaign_ids"), all_matches,
                   overwrite=TRUE, row.names=FALSE)

rs <- dbGetQuery(pg, "ALTER TABLE factset.campaign_ids OWNER TO activism")

match_check <- dbGetQuery(pg, "
    SELECT DISTINCT cusip_9_digit, dissident_group, announce_date, campaign_id
    FROM activist_director.activism_events
    -- FROM factset.sharkwatch_old AS a
    LEFT JOIN factset.campaign_ids
    USING (cusip_9_digit, dissident_group, announce_date)
    WHERE campaign_id IS NULL AND cusip_9_digit IS NOT NULL
    -- UNION
    -- SELECT DISTINCT cusip_9_digit, dissident_group, announce_date, campaign_id
    -- FROM targeted.activism_events
    -- FROM factset.sharkwatch_old AS a
    -- LEFT JOIN factset.campaign_ids
    -- USING (cusip_9_digit, dissident_group, announce_date)
    -- WHERE campaign_id IS NULL AND cusip_9_digit IS NOT NULL
")

# write.csv(match_check,
#           file="~/Google Drive/activism/data/other_unmatched.csv", row.names=FALSE)
dbDisconnect(pg)


