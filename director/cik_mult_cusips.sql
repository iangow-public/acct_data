-- SELECT DISTINCT company_name
-- FROM filings.filings
-- WHERE cik::integer=895648;

WITH mult_cusips AS (
        SELECT cik
        FROM director.ciks
        GROUP BY cik
        HAVING count(DISTINCT cusip)>1),

equilar_names AS (
    SELECT director.equilar_id(company_id), fy_end, company
    FROM director.co_fin),

filings AS (
    SELECT cik::integer, array_agg(DISTINCT company_name) AS company_names
    FROM filings.filings
    GROUP BY cik)

SELECT DISTINCT cik, equilar_id, cusip, company, company_names
FROM director.ciks
INNER JOIN mult_cusips
USING (cik)
INNER JOIN equilar_names
USING (equilar_id, fy_end)
INNER JOIN filings
USING (cik)
ORDER BY cik
