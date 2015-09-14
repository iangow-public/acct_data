SET work_mem='3GB';

DROP TABLE IF EXISTS director.equilar_proxies;

CREATE TABLE director.equilar_proxies AS
WITH

proxy_filings AS (
    SELECT cik::integer, file_name, date_filed
    FROM filings.filings
    WHERE form_type ~ '^DEF 14'),

-- Get the first proxy after the fy_end
matched_proxies AS (
    SELECT equilar_id, cik, fy_end,
        min(date_filed) AS date_filed
    FROM director.ciks AS a
    INNER JOIN proxy_filings AS b
    USING (cik)
    WHERE date_filed > fy_end
    GROUP BY equilar_id, cik, fy_end),

-- Only match a given filing to the latest fy_end
matched_fyears AS (
    SELECT equilar_id, cik, date_filed, max(fy_end) AS fy_end
    FROM matched_proxies
    GROUP BY equilar_id, cik, date_filed)

SELECT equilar_id, cusip, fy_end, cik,
    file_name, date_filed
FROM director.ciks AS a
LEFT JOIN matched_fyears AS b
USING (equilar_id, cik, fy_end)
LEFT JOIN proxy_filings AS c
USING (cik, date_filed)
