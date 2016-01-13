SET work_mem='2GB';

WITH

ciq_ids AS (
    SELECT companyid, cik::integer, startdate, enddate
    FROM ciq.wrds_cik),

proxy_filings AS (
    SELECT a.cik::integer, file_name, date_filed, companyid
    FROM filings.filings AS a
    LEFT JOIN ciq_ids AS b
    ON a.cik::integer=b.cik
        AND (a.date_filed <= b.enddate OR b.enddate IS NULL)
        AND (a.date_filed >= b.startdate OR b.startdate IS NULL)
    WHERE form_type ~ '^DEF 14'),
    
proxy_filings_gvkey AS (
    SELECT a.*, b.gvkey
    FROM proxy_filings AS a
    LEFT JOIN ciq.wrds_gvkey AS b
    ON a.companyid=b.companyid
        AND (a.date_filed <= b.enddate OR b.enddate IS NULL)
        AND (a.date_filed >= b.startdate OR b.startdate IS NULL)),

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
    file_name, date_filed, gvkey
FROM director.ciks AS a
LEFT JOIN matched_fyears AS b
USING (equilar_id, cik, fy_end)
LEFT JOIN proxy_filings_gvkey AS c
USING (cik, date_filed)
WHERE cik=943820;