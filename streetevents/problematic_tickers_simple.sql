SET work_mem='3GB';

WITH 

new_names AS (
    SELECT ticker, co_name, call_desc, 
        regexp_replace(co_name, '^(.*?)\s.*$', '\1') AS partial_name,
        regexp_replace(call_desc, 
                       '^Q[1-4] \d{4} (.*?) Earnings Conference Call$', '\1') 
            AS original_name,
        regexp_replace(call_desc, 
                       '^Q[1-4] \d{4} (.*?)\s(.*)Earnings Conference Call$', '\1')
            AS partial_original_name
    FROM streetevents.calls
    WHERE call_desc ~ '^Q[1-4] \d{4}.*Earnings Conference Call$' 
        AND regexp_replace(call_desc, 
                       '^Q[1-4] \d{4} (.*?)\s(.*)Earnings Conference Call$', '\1') !~ '(\(|\))')

SELECT *, 
    call_desc ~* partial_name AS match1,
    co_name ~* partial_original_name AS match2
FROM new_names
WHERE NOT (call_desc ~* partial_name) OR NOT (co_name ~* partial_original_name) 
ORDER BY ( call_desc ~* partial_name OR co_name ~* partial_original_name)
