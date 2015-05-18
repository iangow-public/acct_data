SET work_mem='3GB';

DROP TABLE IF EXISTS director.equilar_proxies;

CREATE TABLE director.equilar_proxies AS
WITH

equilar AS(
    SELECT trim(cusip) AS cusip,
        director.equilar_id(company_id) AS equilar_id, fy_end
    FROM director.co_fin),
    
permno_cusip AS (
    SELECT DISTINCT permno, ncusip AS cusip
    FROM crsp.stocknames),
    
-- CUSIP-CIK matches come from two sources:
--  - Scraping 13/D and 13/G filings and
--  - WRDS's Capital IQ database
cusip_cik AS (
    SELECT substr(cusip, 1, 8) AS cusip, cik
    FROM filings.cusip_cik 
    WHERE char_length(trim(cusip))>=8
    GROUP BY substr(cusip, 1, 8), cik 
    HAVING count(*) > 10
    UNION 
    SELECT DISTINCT substr(cusip, 1, 8) AS cusip, cik::integer
    FROM ciq.wrds_cusip
    INNER JOIN ciq.wrds_cik
    USING (companyid)),
    
-- Get all CIKs that match each PERMNO, using CUSIPs as the link
permno_ciks AS (
    SELECT DISTINCT permno, cik -- array_agg(cik) AS ciks
    FROM permno_cusip
    INNER JOIN cusip_cik
    USING (cusip)
    -- GROUP BY permno
    ),

-- Add CIKs to Equilar data, going via PERMNOs to CUSIPs
equilar_w_ciks AS (
    SELECT equilar_id, cusip, fy_end, cik,
        extract(year FROM fy_end)::integer AS year
    FROM equilar AS a
    LEFT JOIN permno_cusip AS b
    USING (cusip)
    LEFT JOIN permno_ciks
    USING (permno)),

proxy_filings AS (
    SELECT cik::integer, 
        extract(year FROM date_filed)::integer AS year, 
        file_name, date_filed
    FROM filings.filings
    WHERE form_type ~ '^DEF 14'),

matched_proxies AS (
    SELECT equilar_id, fy_end, a.cik,
        min(date_filed) AS date_filed
    FROM equilar_w_ciks AS a
    INNER JOIN proxy_filings AS b
    ON b.cik=a.cik -- any(a.ciks)
    WHERE date_filed > fy_end
    GROUP BY equilar_id, fy_end, a.cik),

equilar_w_proxies AS (
    SELECT equilar_id, cusip, fy_end, b.cik,
        file_name, c.date_filed
    FROM equilar_w_ciks AS a
    LEFT JOIN matched_proxies AS b
    USING (equilar_id, fy_end)
    LEFT JOIN proxy_filings AS c
    ON b.cik=c.cik AND b.date_filed=c.date_filed)

SELECT *
FROM equilar_w_proxies; 
