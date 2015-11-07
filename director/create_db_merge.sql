SET work_mem='2GB';

DROP TABLE IF EXISTS director.db_merge;

CREATE TABLE director.db_merge AS
WITH

-- I scraped 13G and 13F filings for CUSIP-CIK matches.
-- There are occasional errors, so I require at least 10 filings
-- before considering the match useful.
cusip_ciks AS (
    SELECT substr(trim(cusip), 1, 8) AS cusip, cik
    FROM filings.cusip_cik
    WHERE cusip IS NOT NULL
    GROUP BY 1, 2
    HAVING count(*) > 10),

-- This is data from WRDS.
gvkey_cik AS (
    SELECT DISTINCT gvkey, cik::integer
    FROM ciq.wrds_gvkey
    INNER JOIN ciq.wrds_cik
    USING (companyid)),

-- This is the list of other_director_ids we have.
firm_ids AS (
    SELECT DISTINCT director.equilar_id(company_id) AS equilar_id,
        fy_end, cusip, company
    FROM director.co_fin),

-- Merge it all.
firm_matches AS (
    SELECT DISTINCT equilar_id,
        array_agg(DISTINCT cusip) AS cusips,
        array_agg(DISTINCT cik) AS ciks,
        array_agg(DISTINCT gvkey) AS gvkeys,
        array_agg(DISTINCT company) AS companies
    FROM firm_ids
    LEFT JOIN cusip_ciks
    USING (cusip)
    LEFT JOIN gvkey_cik
    USING (cik)
    GROUP BY equilar_id)

SELECT a.*, b.fy_end
FROM firm_matches AS a
INNER JOIN firm_ids AS b
USING (equilar_id);

GRANT SELECT ON director.db_merge TO equilar_access;
