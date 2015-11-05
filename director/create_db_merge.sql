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

companies AS (
    SELECT equilar_id, array_agg(DISTINCT company) AS companies
    FROM firm_ids
    GROUP BY equilar_id)

-- Merge it all.
SELECT DISTINCT equilar_id, fy_end, cusip,
    array_agg(DISTINCT cik) AS ciks,
    array_agg(DISTINCT gvkey) AS gvkeys,
    companies
FROM firm_ids
LEFT JOIN cusip_ciks
USING (cusip)
LEFT JOIN gvkey_cik
USING (cik)
INNER JOIN companies
USING (equilar_id)
GROUP BY equilar_id, fy_end, cusip, companies;

GRANT SELECT ON director.db_merge TO equilar_access;
