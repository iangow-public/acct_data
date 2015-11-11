WITH mult_ids AS (
    SELECT file_name
    FROM director.equilar_proxies
    GROUP BY file_name
    HAVING COUNT(DISTINCT equilar_id)>1),

equilar_names AS (
    SELECT director.equilar_id(company_id), fy_end, company
    FROM director.co_fin),

filings AS (
    SELECT file_name, company_name
    FROM filings.filings)

SELECT *
FROM director.equilar_proxies
INNER JOIN mult_ids
USING (file_name)
INNER JOIN equilar_names
USING (equilar_id, fy_end)
INNER JOIN filings
USING (file_name)
ORDER BY cik, date_filed
