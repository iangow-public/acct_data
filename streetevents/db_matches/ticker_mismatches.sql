SET work_mem='1GB';

CREATE OR REPLACE FUNCTION streetevents.fix_name (text) 
RETURNS text AS 
$$
    my $temp = $_[0];
    
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

CREATE OR REPLACE FUNCTION streetevents.extract_name (text) 
RETURNS text AS 
$$
    my $call_desc = $_[0];
    my $temp;
    
    # The vast majority of cases fit this format
    if ($call_desc =~ /^Q[1-4] \d{4} (.*) Earnings.*Conference Call$/) {
        $temp = $1;
    }

    if ($call_desc =~ /^.+ Q[1-4] \d{4} Earnings.*Conference Call$/) {
        $temp = $1;
    }

    $pattern = '^(?:First|Second|Third|Fourth) Quarter (?:FY)?\d{4} (.*) ';
    $pattern .= 'Earnings.*Conference Call$';
    my $regex = qr/$pattern/;
    if ($call_desc =~ $regex) {
        $temp = $1;
    }

    return $temp;
$$ LANGUAGE plperl;

WITH 
raw_data AS (
    SELECT file_name, ticker, co_name, call_desc, 
        streetevents.extract_name(call_desc) AS original_name,
        call_desc ~ '^Q[1-4] \d{4} .* Earnings.*Conference Call$' AS call_desc_std
    FROM streetevents.calls
    WHERE call_type=1 AND ticker !~ '\.' -- Exclude foreign firms
    ),

clean_names AS (
    SELECT file_name, ticker, call_desc, call_desc_std,
        streetevents.fix_name(co_name) AS co_name,
        streetevents.fix_name(original_name) AS original_name
    FROM raw_data)
    
SELECT a.*, c.call_date, b.match_type, b.match_type_desc, 
    d.comnam, d.permno, 
    CASE WHEN call_desc_std 
        THEN a.co_name ~* original_name OR original_name ~* a.co_name
    END AS diff_name
FROM clean_names AS a
INNER JOIN streetevents.calls AS c
USING (file_name)
LEFT JOIN streetevents.crsp_link AS b
USING (file_name)
LEFT JOIN crsp.stocknames AS d
ON b.permno = d.permno 
    AND c.call_date BETWEEN d.namedt AND d.nameenddt;
