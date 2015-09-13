SET work_mem='3GB';

WITH problematic_tickers AS (
    SELECT b.ticker, array_agg(DISTINCT permco) AS permcos,
        count(DISTINCT permco) AS num_permcos
    FROM streetevents.company_link AS a
    INNER JOIN streetevents.calls AS b
    USING (file_name)
    INNER JOIN crsp.stocknames
    USING (permno)
    GROUP BY b.ticker
    HAVING count(DISTINCT permco)>1),

new_names AS (
    SELECT ticker, co_name, call_desc, 
        regexp_replace(co_name, '^(.*?)\s.*$', '\1') AS partial_name,
        regexp_replace(call_desc, 
                       '^Q[1-4] \d{4} (.*) Earnings Conference Call$', '\1') 
            AS original_name,
        regexp_replace(call_desc, 
                       '^Q[1-4] \d{4} (.*?)\s(.*)Earnings Conference Call$', '\1') 
            AS partial_original_name
    FROM streetevents.calls
    WHERE call_desc ~ '^Q[1-4] \d{4} .* Earnings Conference Call$'),

unmatched_names AS (
    SELECT ticker, co_name, original_name
    FROM new_names
    WHERE NOT(call_desc ~* partial_name) OR NOT(partial_original_name ~* co_name)),

missed AS (
    SELECT DISTINCT ticker, co_name, original_name,
        num_permcos, permcos
    FROM unmatched_names
    FULL OUTER JOIN problematic_tickers
    USING (ticker)
    -- WHERE co_name IS NULL
    ORDER BY ticker)

SELECT DISTINCT b.* -- a.*, b.permcos
FROM streetevents.calls AS a
INNER JOIN missed AS b
USING (ticker)
-- WHERE permcos IS NOT NULL
-- WHERE ticker='BCR'
ORDER BY ticker
