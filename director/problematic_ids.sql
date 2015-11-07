WITH crsp AS (
    SELECT DISTINCT permno, ncusip AS cusip, st_date, end_date
    FROM crsp.stocknames),

co_fin AS (
    SELECT director.equilar_id(company_id), cusip, company,
        min(fy_end) AS fy_end,
        min(shares_outstanding_date) AS shares_outstanding_date
    FROM director.co_fin
    GROUP BY 1, 2, 3)

SELECT *
FROM co_fin
INNER JOIN crsp AS b
USING (cusip)
WHERE shares_outstanding_date < st_date - interval '1 year'
