SET work_mem='2GB';

DROP TABLE IF EXISTS director.db_merge;

CREATE TABLE director.db_merge AS
WITH

-- This is data from WRDS.
gvkey_cik AS (
    SELECT DISTINCT gvkey, cik::integer
    FROM ciq.wrds_gvkey
    INNER JOIN ciq.wrds_cik
    USING (companyid)),

companies AS (
    SELECT DISTINCT director.equilar_id(company_id),
        company
    FROM director.co_fin)

-- Merge it all.
SELECT DISTINCT equilar_id, fy_end, cusip, cik,
    array_agg(DISTINCT gvkey) AS gvkeys,
    array_agg(DISTINCT company) AS companies
FROM director.ciks AS a
INNER JOIN companies
USING (equilar_id)
LEFT JOIN gvkey_cik
USING (cik)
GROUP BY equilar_id, fy_end, cusip, a.cik;

GRANT SELECT ON director.db_merge TO equilar_access;
