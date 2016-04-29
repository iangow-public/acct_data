library(haven)

data_path <- "~/Dropbox/data/va"
# File obtained from /export/projects/jzeitler_project/VotingAnalytics/201503
# on HBS Research Grid:
va <- read_dta(file.path(data_path, "VA_CompanyVotes_2001_2014.dta"))

va$recorddate <- as.Date(va$recorddate, origin='1960-01-01')
va$meetingdate <- as.Date(va$meetingdate, origin='1960-01-01')
va$recorddatec <- as.Date(va$recorddatec, format="%m/%d/%Y")
va$meetingdatec <- as.Date(va$meetingdatec, format="%m/%d/%Y")
table(va$recorddate==va$recorddatec)
table(va$meetingdatec==va$meetingdate)
va$meetingdatec <- NULL
va$recorddatec <- NULL
va$companyid <- as.integer(va$companyid)
table(va$companyid==va$companyid_n)
va$companyid_n <- NULL
va$base[va$base %in% c('[]', '', 'NA')] <- NA

# Would need to check this one
va$voterequirement[va$voterequirement=="5.5"] <- NA
va$voterequirement[va$voterequirement=="66.67"] <- "0.6667"
va$voterequirement <- as.numeric(va$voterequirement)

# Fix gremlins in va$base field
va$base[va$base=="F A"] <- "F+A"
va$base[va$base=="F A AB" | va$base=="F+A+B"] <- "F+A+AB"

va$itemonagendaid <- as.integer(va$itemonagendaid)

#### Following is old code
library(dplyr)
library(RPostgreSQL)
pg <- dbConnect(PostgreSQL())
rs <- dbWriteTable(pg, c("issvoting", "compvote"), va %>% as.data.frame(),
  row.names=FALSE, overwrite=TRUE)
rs <- dbGetQuery(pg,"

    UPDATE issvoting.compvote SET
      (votedfor, votedagainst ,votedabstain)=(2224433656,93561790,34814753)
        WHERE itemonagendaid=6019529;
    UPDATE issvoting.compvote SET
      (votedfor, votedagainst, votedabstain, ticker)=(10540862,1329889,790539,'KIDE')
        WHERE itemonagendaid=6039421;
    UPDATE issvoting.compvote SET
      (votedfor, votedagainst ,votedabstain)=(NULL, NULL, NULL)
        WHERE itemonagendaid=5761302;
    UPDATE issvoting.compvote SET voteresult='Pass' WHERE itemonagendaid=7495200;
    UPDATE issvoting.compvote SET (votedfor, voteresult)=(66787860, 'Pass')
        WHERE itemonagendaid=5890579;
    UPDATE issvoting.compvote
        SET (votedfor, voteresult)=(14830551, 'Pass')
        WHERE itemonagendaid=6049938;

    -- Fix some more data issues based on information in SEC filings
    -- Note: .. = http://www.sec.gov/Archives/edgar/data
    --  Source: ../1085653/000108565302000041/eclg10qq3final.htm
    UPDATE issvoting.compvote
        SET (votedfor, voteresult)=(11613263, 'Pass') WHERE itemonagendaid=5930886;

    -- Source: ../912463/000110465904022325/a04-8530_110q.htm
    UPDATE issvoting.compvote
        SET (votedfor, voteresult)=(30136926, 'Pass') WHERE itemonagendaid=6251118;

    -- # Source: ../1012140/000091205701528693/a2056633z10-q.htm
    UPDATE issvoting.compvote
        SET (votedfor, voteresult)=(6237837, 'Pass') WHERE itemonagendaid=5755512;


    -- Source: ../931015/000095013701502878/c63972e10-q.htm
    UPDATE issvoting.compvote
        SET (votedfor, voteresult)=(17592647, 'Pass') WHERE itemonagendaid=5733709;

    --  Source: ../1050606/000105060603000027/form10q6302003.htm
    UPDATE issvoting.compvote
        SET (votedfor, voteresult)=(70548942, 'Pass') WHERE itemonagendaid=6049746;

    UPDATE issvoting.compvote
        SET voterequirement=0.6667 WHERE voterequirement=66.67
")

dbGetQuery(pg, "VACUUM ANALYZE issvoting.compvote")

dbGetQuery(pg, "CREATE INDEX ON issvoting.compvote (cusip)")
dbDisconnect(pg)
