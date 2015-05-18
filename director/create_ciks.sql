DROP TABLE IF EXISTS director.ciks;

CREATE TABLE director.ciks AS
WITH equilar AS(
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
    HAVING count(*) > 5
    UNION 
    SELECT DISTINCT substr(cusip, 1, 8) AS cusip, cik::integer
    FROM ciq.wrds_cusip
    INNER JOIN ciq.wrds_cik
    USING (companyid)),

-- Get all CIKs that match each PERMNO, using CUSIPs as the link
permno_ciks AS (
    SELECT permno, array_agg(cik) AS ciks
    FROM permno_cusip
    INNER JOIN cusip_cik
    USING (cusip)
    GROUP BY permno)

-- Add CIKs to Equilar data, going via PERMNOs to CUSIPs
SELECT equilar_id, fy_end, ciks
FROM equilar AS a
LEFT JOIN permno_cusip AS b
USING (cusip)
LEFT JOIN director_bio.permno_ciks
USING (permno)