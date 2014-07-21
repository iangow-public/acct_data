CREATE OR REPLACE FUNCTION executive.executive_id(text)
  RETURNS integer AS
$BODY$
    SELECT CASE WHEN $1 != ''
    THEN regexp_replace($1, E'^.*\\.(\\d+)$', E'\\1')::integer
    ELSE NULL END
  $BODY$
  LANGUAGE sql VOLATILE
  COST 100;

ALTER FUNCTION executive.executive_id(text) OWNER TO igow;

CREATE OR REPLACE FUNCTION executive.equilar_id(text)
  RETURNS integer AS
$BODY$
        SELECT regexp_replace($1, E'^(\\d+)\\..*$', E'\\1')::integer
    $BODY$
  LANGUAGE sql VOLATILE
  COST 100;

ALTER FUNCTION executive.equilar_id(text) OWNER TO igow;
