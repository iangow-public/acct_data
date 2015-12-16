SET work_mem='2GB';

DROP TABLE IF EXISTS director.db_merge;

CREATE TABLE director.db_merge AS
WITH

companies AS (
    SELECT DISTINCT director.equilar_id(company_id),
        company
    FROM director.co_fin)

-- Merge it all.
SELECT DISTINCT equilar_id, fy_end, cusip, cik,
    array_agg(DISTINCT company) AS companies
FROM director.ciks AS a
INNER JOIN companies
USING (equilar_id)
GROUP BY equilar_id, fy_end, cusip, a.cik;

GRANT SELECT ON director.db_merge TO equilar_access;
