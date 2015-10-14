SET work_mem='2GB';

DROP TABLE IF EXISTS director.company_names;

CREATE TABLE director.company_names AS 

WITH

company_names AS (
    SELECT director.equilar_id(company_id) AS equilar_id,
        array_agg(DISTINCT company) AS company_names
    FROM director.co_fin
    GROUP BY 1),

original_names AS (
    SELECT cik::integer, array_agg(DISTINCT upper(original_name_edited)) AS original_names
    FROM filings.original_names_edited
    WHERE original_name_edited IS NOT NULL
    GROUP BY 1)

SELECT DISTINCT equilar_id, array_cat(company_names, original_names) AS original_names
FROM director.equilar_proxies AS a
INNER JOIN company_names AS b
USING (equilar_id)
LEFT JOIN original_names
USING (cik)
ORDER BY 1;
