CREATE OR REPLACE FUNCTION array_diff(
    anyarray,
    anyelement)
  RETURNS anyelement AS
$BODY$ 
    -- Function returns an array with the second element omitted
    SELECT array(SELECT x from unnest($1) AS x 
    WHERE x != $2)
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
  
ALTER FUNCTION array_diff(anyarray, anyelement)
  OWNER TO igow;

CREATE OR REPLACE FUNCTION array_max(anyarray)
  RETURNS anyelement AS
$BODY$ 
    -- Function returns maximum value of array
    SELECT max(x) from unnest($1) AS x 
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
  
ALTER FUNCTION array_max(anyarray)
  OWNER TO igow;
