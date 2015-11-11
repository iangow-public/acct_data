DROP TABLE IF EXISTS director.ciks;

CREATE TABLE director.ciks AS
WITH

co_fin AS (
    SELECT
        director.equilar_id(company_id) AS equilar_id, fy_end, cusip,
        upper(company) AS company_name
    FROM director.co_fin),

equilar AS (
    SELECT *
    FROM co_fin
    INNER JOIN director.company_ids
    USING (equilar_id)),

permno_cusip AS (
    SELECT DISTINCT permno, ncusip AS cusip
    FROM crsp.stocknames),

-- Add CIKs to Equilar data, going via PERMNOs to CUSIPs
cusip_matches AS (
    SELECT equilar_id, cusip, fy_end, cik,
        extract(year FROM fy_end)::integer AS year,
        'equilar'::text AS matched_on
    FROM equilar AS a
    LEFT JOIN permno_cusip AS b
    USING (cusip)),

sec_names AS (
    SELECT DISTINCT upper(company_name) AS company_name, cik
    FROM filings.filings
    WHERE form_type ~ '^(6-K|DEF 14|10-K|10K)'),

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
