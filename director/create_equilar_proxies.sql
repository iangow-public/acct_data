SET work_mem='3GB';

DROP TABLE IF EXISTS director.equilar_proxies;

CREATE TABLE director.equilar_proxies AS

WITH ciks AS (
    SELECT equilar_id, fy_end, lead(fy_end) OVER w AS next_fy_end, cik
    FROM director.ciks
    WINDOW w AS (PARTITION BY equilar_id ORDER BY fy_end)),

proxy_filings AS (
    SELECT a.cik::integer, file_name, date_filed, form_type
    FROM filings.filings AS a
    WHERE form_type ~ '^(DEF 14|20-F)'),

other_filings AS (
    SELECT a.cik::integer, file_name, date_filed, form_type
    FROM filings.filings AS a
    WHERE form_type ~ '^10-?K'),

equilar_proxy_filings AS (
    SELECT a.equilar_id, a.fy_end, a.next_fy_end, a.cik,
        b.file_name, b.date_filed, b.form_type
    FROM ciks AS a
    LEFT JOIN proxy_filings AS b
    ON a.cik=b.cik AND b.date_filed > a.fy_end
        AND (b.date_filed <= a.next_fy_end OR a.next_fy_end IS NULL)),

equilar_next_proxy_filing AS (
    SELECT equilar_id, fy_end, min(date_filed) AS date_filed
    FROM equilar_proxy_filings
    GROUP BY equilar_id, fy_end),

equilar_proxy_filing_filtered AS (
    SELECT *
    FROM equilar_proxy_filings
    INNER JOIN equilar_next_proxy_filing
    USING (equilar_id, fy_end, date_filed)),

equilar_other_filings AS (
    SELECT a.equilar_id, a.fy_end, a.next_fy_end, a.cik,
        b.file_name, b.date_filed, b.form_type
    FROM ciks AS a
    LEFT JOIN other_filings AS b
    ON a.cik=b.cik AND b.date_filed > a.fy_end
        AND (b.date_filed <= a.next_fy_end OR a.next_fy_end IS NULL)),

equilar_next_other_filing AS (
    SELECT equilar_id, fy_end, min(date_filed) AS date_filed
    FROM equilar_other_filings
    GROUP BY equilar_id, fy_end),

equilar_other_filing_filtered AS (
    SELECT *
    FROM equilar_other_filings
    INNER JOIN equilar_next_other_filing
    USING (equilar_id, fy_end, date_filed)),

merged AS (
    SELECT a.*,
        COALESCE(b.form_type, c.form_type) AS form_type,
        COALESCE(b.date_filed, c.date_filed) AS date_filed,
        COALESCE(b.file_name, c.file_name) AS file_name
    FROM ciks AS a
    LEFT JOIN equilar_proxy_filing_filtered AS b
    USING (equilar_id, fy_end)
    LEFT JOIN equilar_other_filing_filtered AS c
    USING (equilar_id, fy_end)),

ciq_ids AS (
    SELECT companyid, cik::integer, startdate, enddate
    FROM ciq.wrds_cik),

add_companyid AS (
    SELECT a.*, b.companyid,
        (a.date_filed <= b.enddate OR b.enddate IS NULL)
        AND (a.date_filed >= b.startdate OR b.startdate IS NULL)
            AS valid_date_cik
    FROM merged AS a
    LEFT JOIN ciq_ids AS b
    ON a.cik=b.cik),

alt_ciks AS (
    SELECT gvkey, array_agg(cik::integer) AS ciks
    FROM ciq.wrds_cik
    INNER JOIN ciq.wrds_gvkey
    USING (companyid)
    GROUP BY gvkey)

SELECT a.*, b.gvkey, array_diff(c.ciks, a.cik::integer) AS alt_ciks,
    COALESCE(valid_date_cik AND (a.date_filed <= b.enddate OR b.enddate IS NULL)
        AND (a.date_filed >= b.startdate OR b.startdate IS NULL), FALSE)
        AS valid_date
FROM add_companyid AS a
LEFT JOIN ciq.wrds_gvkey AS b
ON a.companyid=b.companyid
    LEFT JOIN alt_ciks AS c
USING (gvkey);

GRANT SELECT ON director.equilar_proxies TO equilar_access;
