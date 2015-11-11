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

-- This is the list of other_director_ids we have.
firm_ids AS (
    SELECT DISTINCT equilar_id, fy_end, cusip, company, cik
    FROM director.ciks),

-- Merge it all.
SELECT DISTINCT equilar_id, fy_end, cusip, cik,
    array_agg(DISTINCT gvkey) AS gvkeys,
    array_agg(DISTINCT company) AS companies
FROM director.ciks AS a
USING (equilar_id, fy_end)
LEFT JOIN gvkey_cik
USING (cik)
GROUP BY equilar_id, fy_end, a.cusip);

GRANT SELECT ON director.db_merge TO equilar_access;
