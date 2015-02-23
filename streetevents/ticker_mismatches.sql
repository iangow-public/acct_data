SET work_mem='1GB';

CREATE OR REPLACE FUNCTION streetevents.fix_name (text) 
RETURNS text AS 
$$
    $temp = $_[0];
    
    # Abbreviate where possible
    $temp =~ s/Corporation/Corp/;
    $temp =~ s/\bLimited\b/Ltd/;
    
    # Remove "Inc." completely
    $temp =~ s/\s+Inc\.?$//i;
    
    # Remove multiple spaces
    $temp =~ s/\s{2,}/ /;
    
    # Remove punctuation
    $temp =~ s/[-\.,'`]//g;
    $temp =~ s/\s+&\s+/ and /g;
    return $temp;
$$ LANGUAGE plperl;


WITH 
raw_data AS (
    SELECT file_name, ticker, co_name, call_desc, 
        regexp_replace(call_desc,
                       '^Q[1-4] \d{4} (.*) Earnings Conference Call$',
                       '\1') AS original_name
    FROM streetevents.calls
    WHERE call_type=1 
        AND call_desc ~ '^Q[1-4] \d{4} .* Earnings Conference Call$'
        AND ticker !~ '\.' -- Exclude foreign firms
    ),

clean_names AS (
    SELECT file_name, ticker, call_desc,
        streetevents.fix_name(co_name) AS co_name,
        streetevents.fix_name(original_name) AS original_name
    FROM raw_data)
    
SELECT a.*, c.call_date, b.match_type, b.match_type_desc, 
    d.comnam, d.permno, 
    NOT (a.co_name ~* original_name OR original_name ~* a.co_name) AS diff_name
FROM clean_names AS a
INNER JOIN streetevents.calls AS c
USING (file_name)
LEFT JOIN streetevents.crsp_link AS b
USING (file_name)
LEFT JOIN crsp.stocknames AS d
ON b.permno = d.permno 
    AND c.call_date BETWEEN d.namedt AND d.nameenddt;
