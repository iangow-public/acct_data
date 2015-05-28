/*******************************
LAST UPDATED: January 2, 2015
OBJECTIVE: Merge streetevents.calls with PERMNOs from crsp.stocknames

WARNING: IGNORE StreetEvents backdates permnos >> crsp_link is dirty liking(!) use xpf_link instead
*******************************/

/* '.' in tickers for streetevents specifies the stock exhange
(see: http://www.sirca.org.au/2010/12/tick-history-exchange-identifiers/)
KEEP U.S.:
    .N  -> NYSE    (2 tickers for bank of cyprus with .N but is not in NYSE, thus incorrectly labelled?)
    .OQ -> NASDAQ  (0 tickers with .OQ)
    .A  -> AMEX       (4 tickers with .A -> BRK.A, FCE.A, JW.A, MOG.A)
REMOVE FOREIGN (EXAMPLES):
    .TW -> Taiwan
    .TO -> Toronto
    .T  -> Tokyo (Nikkei)
    .L  -> London (FTSE)
--remove foreign firms and obtain unmatched obs.*/

/*Some tickers in streetevents have '**' in front of the ticker. Not certain why.

    Examples:
        ticker    | co_name         | call_date
        **ADAM    | ADAM Inc        | 2008-11-06 15:00:00
        **GEH     | GE Healthcare   | 2005-04-05 08:00:00
        **DRD     | Duane Reade     | 2006-05-11 14:00:00

   Remove Asterix
*/

--DROP EXTENSION plperl CASCADE;
-- CREATE EXTENSION plperl; --postgresql-plperl not installable

CREATE OR REPLACE FUNCTION streetevents.clean_tickers (ticker text) RETURNS text AS
$BODY$
  # Remove any asterisks
  $_[0] =~ s/\*//g;

  # Remove trailing .A
  $_[0] =~ s/\.A$//g;

  return $_[0];
$BODY$ LANGUAGE plperl;

ALTER FUNCTION streetevents.clean_tickers(text) OWNER TO personality_access;

/* Some tickers with ending Q causes non-matches. Examples:
    streetevents          --->  crsp.stocknames
    _______________________     _______________________________________
    ticker  co_name             ticker  comnam
    ATRNQ   Atrinsic Inc        ATRN    ATRINSIC INC
    CPICQ   CPI CORP            CPIC    C P I CORP
    DDMGQ   Digital Domain      DDMG    DIGITAL DOMAIN MEDIA GROUP INC
            Media Group Inc
*/
SET work_mem='15GB';

CREATE OR REPLACE FUNCTION streetevents.remove_trailing_q (ticker text)
RETURNS text AS
$BODY$
  # Remove trailing Qs
  $_[0] =~ s/Q$//g;

  return $_[0];
$BODY$ LANGUAGE plperl;

ALTER FUNCTION streetevents.remove_trailing_q(text) OWNER TO personality_access;

DROP TABLE IF EXISTS streetevents.crsp_link;

CREATE TABLE streetevents.crsp_link AS
WITH

calls AS (
    SELECT streetevents.clean_tickers(ticker) AS ticker, file_name,
        co_name, call_date::date
    FROM streetevents.calls
    WHERE (ticker ~ '\.A$' OR ticker !~ '\.[A-Z]+$')
        AND ticker IS NOT NULL -- AND call_type = 1
),

match0 AS (
    SELECT DISTINCT a.file_name, a.ticker, COALESCE(b.co_name, a.co_name) AS co_name,
        a.call_date, b.permno,
        '0. Manual matches'::text AS match_type_desc
    FROM calls AS a
    LEFT JOIN streetevents.manual_permno_matches AS b
    ON a.file_name=b.file_name),

match1 AS (
    SELECT DISTINCT file_name, a.ticker, co_name, call_date, b.permno,
        '1. Match on ticker & exact Soundex between ticker dates'::text AS match_type_desc
    FROM match0 AS a
    LEFT JOIN crsp.stocknames AS b
    ON a.ticker=b.ticker
        AND (a.call_date BETWEEN b.namedt AND b.nameenddt)
        -- The difference function converts two strings to their Soundex codes and
        -- then reports the number of matching code positions. Since Soundex codes
        -- have four characters, four is an exact match.
        -- Note: lower() has no impact.
        AND difference(a.co_name,b.comnam) = 4
    WHERE a.permno IS NULL),

/* Roll back and forward permno for companies that changed tickers at some point. Example:
    permno   namedt         nameenddt       ticker    st_date         end_date
    91029    "2005-12-16"   "2009-05-06"    "SPSN"    "2005-12-30"    "2009-05-29"
    93387    "2010-05-18"   "2010-06-22"    "CODE"    "2010-05-28"    "2013-06-28"
    93387    "2010-06-23"   "2013-06-28"    "CODE"    "2010-05-28"    "2013-06-28"

    In StreetEvents, SPANSION ticker is only CODE from 2006-2013
*/

match2 AS (
    SELECT DISTINCT a.file_name, a.ticker, a.co_name, a.call_date, b.permno,
        '2. Roll matches back & forward in StreetEvents'::text AS match_type_desc
    FROM match1 AS a
    LEFT JOIN match1 AS b
    ON a.ticker=b.ticker
        AND a.co_name=b.co_name AND b.permno IS NOT NULL
    WHERE a.permno IS NULL),

match3 AS (
    SELECT DISTINCT file_name, streetevents.remove_trailing_q(a.ticker) AS ticker,
        co_name, call_date, b.permno,
        '3. #1 with trailing Q removed'::text AS match_type_desc
    FROM match2 AS a
    LEFT JOIN crsp.stocknames AS b
    ON streetevents.remove_trailing_q(a.ticker)=b.ticker
        AND (a.call_date BETWEEN b.namedt AND b.nameenddt)
        AND difference(a.co_name, b.comnam) = 4
    WHERE a.permno IS NULL),

match4 AS (
    SELECT DISTINCT a.file_name, a.ticker, a.co_name, a.call_date, b.permno,
        '4. Roll matches back & forward on #3'::text AS match_type_desc
    FROM match3 AS a
    LEFT JOIN match3 as b
    ON a.ticker = b.ticker
        AND a.co_name = b.co_name
    WHERE a.permno IS NULL),

match5 AS (
    SELECT DISTINCT file_name, a.ticker, co_name, call_date, b.permno,
        '5. Match on ticker and exact name Soundex between company dates'::text AS match_type_desc
    FROM match4 AS a
    LEFT JOIN crsp.stocknames AS b
    ON a.ticker=b.ticker
        AND (a.call_date BETWEEN b.st_date AND b.end_date)
        AND DIFFERENCE(a.co_name, b.comnam) = 4
    WHERE a.permno IS NULL),

match6 AS (
    SELECT DISTINCT a.file_name, a.ticker, a.co_name, a.call_date, b.permno,
        '6. Roll matches back and forward on #5'::text AS match_type_desc
    FROM match5 AS a
    LEFT JOIN match5 as b
    ON a.ticker = b.ticker
        AND a.co_name = b.co_name AND b.permno IS NOT NULL
    WHERE a.permno IS NULL),

match7 AS (
    SELECT DISTINCT file_name, a.ticker, co_name, call_date, b.permno,
        '7. Match ticker & fuzzy name Soundex between company dates'::text AS match_type_desc
    FROM match6 AS a
    LEFT JOIN crsp.stocknames AS b
    ON a.ticker=b.ticker
        AND (a.call_date BETWEEN b.st_date AND b.end_date)
        AND difference(a.co_name, b.comnam) >= 2
    WHERE a.permno IS NULL),

match8 AS (
    SELECT DISTINCT a.file_name, a.ticker, a.co_name, a.call_date, b.permno,
        '8. Roll matches back & forward on #7'::text AS match_type_desc
    FROM match7 AS a
    LEFT JOIN match7 as b
    ON a.ticker = b.ticker
        AND a.co_name = b.co_name AND b.permno IS NOT NULL
    WHERE a.permno IS NULL),

match9 AS (
    SELECT DISTINCT file_name, a.ticker, co_name, call_date, b.permno,
        '9. Match ticker w/diff of 2 & exact name between ticker dates'::text AS match_type_desc
    FROM match8 AS a
    LEFT JOIN crsp.stocknames AS b
        ON levenshtein(a.ticker, b.ticker) <= 2
        AND (a.call_date BETWEEN b.namedt AND b.nameenddt)
        AND lower(co_name) = lower(comnam)
    WHERE a.permno IS NULL),

match10 AS (
    SELECT DISTINCT a.file_name, a.ticker, a.co_name, a.call_date, b.permno,
        CASE WHEN b.permno IS NOT NULL
            THEN '10. Roll matches back & forward on #9'
            ELSE '11. No match'
        END AS match_type_desc
    FROM match9 AS a
    LEFT JOIN match9 as b
    ON a.ticker = b.ticker
        AND a.co_name = b.co_name AND b.permno IS NOT NULL
    WHERE a.permno IS NULL),

all_matches AS (
    SELECT file_name, ticker, co_name, call_date, permno, match_type_desc
    FROM match0
    WHERE permno IS NOT NULL
    UNION ALL
    SELECT file_name, ticker, co_name, call_date, permno, match_type_desc
    FROM match1
    WHERE permno IS NOT NULL
    UNION ALL
    SELECT file_name, ticker, co_name, call_date, permno, match_type_desc
    FROM match2
    WHERE permno IS NOT NULL
    UNION ALL
    SELECT file_name, ticker, co_name, call_date, permno, match_type_desc
    FROM match3
    WHERE permno IS NOT NULL
    UNION ALL
    SELECT file_name, ticker, co_name, call_date, permno, match_type_desc
    FROM match4
    WHERE permno IS NOT NULL
    UNION ALL
    SELECT file_name, ticker, co_name, call_date, permno, match_type_desc
    FROM match5
    WHERE permno IS NOT NULL
    UNION ALL
    SELECT file_name, ticker, co_name, call_date, permno, match_type_desc
    FROM match6
    WHERE permno IS NOT NULL
    UNION ALL
    SELECT file_name, ticker, co_name, call_date, permno, match_type_desc
    FROM match7
    WHERE permno IS NOT NULL
    UNION ALL
    SELECT file_name, ticker, co_name, call_date, permno, match_type_desc
    FROM match8
    WHERE permno IS NOT NULL
    UNION ALL
    SELECT file_name, ticker, co_name, call_date, permno, match_type_desc
    FROM match9
    WHERE permno IS NOT NULL
    UNION ALL
    SELECT file_name, ticker, co_name, call_date, permno, match_type_desc
    FROM match10)
SELECT file_name, permno,
    regexp_replace(match_type_desc, '^([0-9]+).*', '\1')::int AS match_type,
    match_type_desc
FROM all_matches
ORDER BY file_name;

ALTER TABLE streetevents.crsp_link OWNER TO personality_access;

CREATE INDEX ON streetevents.crsp_link (file_name);
