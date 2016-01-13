library(dplyr)
library(readr)

pg <- src_postgres()

# This code identifies Equilar firm-years where there are alternative CIKs
# and no matching SEC filing.
sql <- sql("
    WITH co_fin AS (
        SELECT DISTINCT director.equilar_id(company_id) AS equilar_id, company
        FROM director.co_fin),

    director AS (
        SELECT DISTINCT director.equilar_id(director_id) AS equilar_id, fy_end,
            array_agg(director) AS directors
        FROM director.director
        GROUP BY 1, 2),

    problem_ids AS (
        SELECT DISTINCT equilar_id, cik, valid_date,
            unnest(alt_ciks) AS alt_cik, company, fy_end
        FROM director.equilar_proxies
        INNER JOIN co_fin
        USING (equilar_id)
        WHERE array_length(alt_ciks, 1) > 0 AND file_name IS NULL),

    agg_data AS (
        SELECT equilar_id, cik, valid_date,
            array_agg(DISTINCT alt_cik) AS alt_ciks,
            array_agg(DISTINCT company) AS company_names,
            array_agg(DISTINCT fy_end ORDER BY fy_end) AS fy_ends
        FROM problem_ids AS a
        GROUP BY 1, 2, 3)

    SELECT a.*, b.directors,
        'http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK='
        || alt_ciks[1] || '&type=DEF+14&dateb='
        || (array_max(a.fy_ends) + interval '6 months')::date
        || '&owner=exclude&count=10' AS url
    FROM agg_data AS a
    INNER JOIN director AS b
    ON a.equilar_id=b.equilar_id AND array_max(a.fy_ends)=b.fy_end
    ORDER BY company_names")

# Run SQL and save output to Google Drive
tbl(pg, sql) %>%
    collect() %>%
    write_csv("~/Google Drive/data/problem_ciks.csv")
