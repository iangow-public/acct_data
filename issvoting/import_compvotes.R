get_path <- function(string) {
  path <- "~/Dropbox/data/va/"
  paste(path, string, ".csv.gz", sep="")
}

compvote1 <- read.csv(get_path("VA_2001_2005"), as.is=TRUE)
compvote2 <- read.csv(get_path("VA_2006_2010"), as.is=TRUE)
compvote3 <- read.csv(get_path("VA_2011_2012"), as.is=TRUE)
compvote4 <- read.csv(get_path("VA_July_Dec_2012"), as.is=TRUE)

# In 2013 files came in Excel format. Converted to CSV as follows:
# /Applications/StatTransfer12/st VA_2013.xls VA_2013.csv
# /Applications/StatTransfer12/st VA_2013_Jan_June.xls VA_2013_Jan_June.csv
# gzip VA_2013*.csv

compvote5 <- read.csv(get_path("VA_2013_Jan_June"), as.is=TRUE)

compvote <- rbind(compvote1, compvote2, compvote3,
                  compvote4, compvote5)
names(compvote) <- tolower(names(compvote))

compvote6 <- read.csv(get_path("VA_2013"), as.is=TRUE)
compvote6$SeqNumber <- NULL
names(compvote6) <- tolower(names(compvote6))
compvote <- rbind(compvote, compvote6)

rm(compvote1, compvote2, compvote3,
   compvote4, compvote5, compvote6)
names(compvote) <- tolower(names(compvote))
compvote$meetingdate <- as.Date(compvote$meetingdate, format="%m/%d/%Y")

trim <- function(string) {
  gsub("^\\s+", "", string, perl=TRUE)
  gsub("\\s+$", "", string, perl=TRUE)
}

compvote$cusip <- trim(compvote$cusip)

# compvotes <- read.csv("~/Dropbox/research/data/VA_2003_2012.csv.gz", stringsAsFactors=FALSE)
# company.votes <- read.dta("~/Dropbox/WRDS/corpgov/CompanyVoteResults_2001_2012.dta")
# http://www.people.hbs.edu/protected/jzeitler/VA/201301/CompanyVoteResults_2001_2012_DTA.zip
library(RPostgreSQL)
drv <- dbDriver("PostgreSQL")
pg <- dbConnect(drv, dbname = "crsp")
rs <- dbWriteTable(pg, c("issvoting", "compvote"), compvote,
  row.names=FALSE, overwrite=TRUE)
rs <- dbGetQuery(pg,"
    UPDATE issvoting.compvote SET base='F+A' WHERE base='F A';
    UPDATE issvoting.compvote SET base='F+A+AB' WHERE base='F A AB';
    UPDATE issvoting.compvote SET base='F+A+AB' WHERE base='F+A+B';
    UPDATE issvoting.compvote SET base=NULL WHERE base='[]' OR base='' or base='NA';
    UPDATE issvoting.compvote SET issagendaitemid='S0810' WHERE issagendaitemid='s0810';
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
dbUnloadDriver(drv)
rm(compvote, get_path, trim)

# # Add PERMNO and GVKEY to a new CUSIPs table (match to CUSIP)
# rs <- dbGetQuery(pg,
#    "ALTER TABLE issvoting.compvote ADD COLUMN cusip text")
# rs <- dbGetQuery(pg,
#     "ALTER TABLE issvoting.compvote ADD COLUMN permno integer")
# rs <- dbGetQuery(pg,"
#     UPDATE issvoting.cusips AS a SET gvkey =
#     (SELECT gvkey FROM comp.cusips AS b WHERE b.cusip=a.cusip)")
# rs <- dbGetQuery(pg,
#     "WITH permnos AS (SELECT DISTINCT permno, ncusip AS cusip FROM crsp.stocknames)
#     UPDATE issvoting.cusips AS a SET permno =
#                  (SELECT permno FROM permnos AS b WHERE b.cusip=substr(a.cusip,1,8))")
#
# rs <- dbGetQuery(pg,
#      "WITH permnos AS (SELECT DISTINCT gvkey, lpermno AS permno,
#             linkdt, linkenddt
#      FROM crsp.ccmxpf_linktable
#      WHERE USEDFLAG='1')
#      UPDATE issvoting.cusips AS a SET gvkey =
#      (SELECT gvkey FROM permnos AS b WHERE b.permno=a.permno AND
#      a.meetingdate >= b.linkdt AND
#      (a.meetingdate <= b.linkenddt OR b.linkenddt IS NULL))
#      WHERE permno IS NOT NULL AND gvkey IS NULL")
