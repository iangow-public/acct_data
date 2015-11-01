DROP TABLE IF EXISTS director.ciks;

CREATE TABLE director.ciks AS
WITH

equilar AS (
    SELECT trim(cusip) AS cusip,
        director.equilar_id(company_id) AS equilar_id, fy_end,
        upper(company) AS company_name
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
    SELECT DISTINCT permno, cik
    FROM permno_cusip
    INNER JOIN cusip_cik
    USING (cusip)),

-- Add CIKs to Equilar data, going via PERMNOs to CUSIPs
cusip_matches AS (
    SELECT equilar_id, cusip, fy_end, cik,
        extract(year FROM fy_end)::integer AS year,
        'cusip'::text AS matched_on
    FROM equilar AS a
    LEFT JOIN permno_cusip AS b
    USING (cusip)
    LEFT JOIN permno_ciks
    USING (permno)),

sec_names AS (
    SELECT DISTINCT upper(company_name) AS company_name, cik
    FROM filings.filings
    WHERE form_type IN ('6-K', 'DEF 14A', '10-K')),

name_matches AS (
    SELECT equilar_id, a.cusip, a.fy_end, c.cik::integer, year,
        'name'::text AS matched_on
    FROM cusip_matches AS a
    INNER JOIN equilar AS b
    USING (equilar_id)
    LEFT JOIN sec_names AS c
    USING (company_name)
    WHERE a.cik IS NULL),

non_matches AS (
    SELECT equilar_id, cusip, fy_end, NULL::integer AS cik, year,
        'none'::text AS matched_on
    FROM name_matches
    WHERE cik IS NULL)

SELECT *
FROM cusip_matches
WHERE cik IS NOT NULL
UNION
SELECT *
FROM name_matches
WHERE cik IS NOT NULL
UNION
SELECT *
FROM non_matches;
