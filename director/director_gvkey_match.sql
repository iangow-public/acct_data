SET work_mem='2GB';

DROP TABLE IF EXISTS director.director_gvkeys;

CREATE TABLE director.director_gvkeys AS
WITH

director AS (
    SELECT (director.equilar_id(director_id),
        director.director_id(director_id))::equilar_director_id AS director_id,
        director.equilar_id(director_id), fy_end
    FROM director.director),

director_w_ciks AS (
    SELECT *
    FROM director
    INNER JOIN director.company_ids
    USING (equilar_id)),

term_dates AS (
    SELECT director_id,
        start_date,
        COALESCE(end_date, boardex_term_end_date,
                 implied_end_date, last_fy_end) AS end_date,
        CASE
            WHEN end_date IS NOT NULL THEN 'Equilar'
            WHEN boardex_term_end_date IS NOT NULL THEN 'BoardEx'
            WHEN implied_end_date IS NOT NULL THEN 'Implied'
            WHEN implied_end_date IS NULL THEN 'Last Year'
        END AS end_date_source
    FROM director.term_end_dates),

ciq_ids AS (
    SELECT companyid, cik::integer, startdate, enddate
    FROM ciq.wrds_cik),

director_w_dates AS (
    SELECT director_id, cik, fy_end AS test_date,
        'fy_end'::text AS test_date_type
    FROM director_w_ciks
    INNER JOIN term_dates
    USING (director_id)
    WHERE fy_end >= start_date
        AND (fy_end < end_date OR end_date IS NULL)
    UNION
    SELECT director_id, cik, end_date AS test_date,
        'end_date'::text AS test_date_type
    FROM director_w_ciks
    INNER JOIN term_dates
    USING (director_id)),

add_companyid AS (
    SELECT a.*, b.companyid,
        (a.test_date <= b.enddate OR b.enddate IS NULL)
        AND (a.test_date >= b.startdate OR b.startdate IS NULL)
            AS valid_date_cik
    FROM director_w_dates AS a
    LEFT JOIN ciq_ids AS b
    ON a.cik=b.cik)

SELECT a.*, b.gvkey,
    COALESCE(valid_date_cik AND (a.test_date < b.enddate OR b.enddate IS NULL)
        AND (a.test_date >= b.startdate OR b.startdate IS NULL), FALSE)
        AS valid_date
FROM add_companyid AS a
LEFT JOIN ciq.wrds_gvkey AS b
ON a.companyid=b.companyid
ORDER BY director_id, test_date;

CREATE INDEX ON director.director_gvkeys (director_id);

GRANT SELECT ON director.director_gvkeys TO equilar_access;
