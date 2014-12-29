CREATE OR REPLACE FUNCTION director.director_id(text)
  RETURNS integer AS
$BODY$
    SELECT CASE WHEN $1 != ''
    THEN regexp_replace($1, E'^.*\\.(\\d+)$', E'\\1')::integer
    ELSE NULL END
  $BODY$ LANGUAGE sql IMMUTABLE;

COMMENT ON FUNCTION director.director_id(text) 
    IS 'CREATED WITH ~/Dropbox/data/equilar/id_functions.sql';

CREATE OR REPLACE FUNCTION director.equilar_id(text)
  RETURNS integer AS
$BODY$
    SELECT CASE WHEN $1 != ''
    THEN regexp_replace($1, E'^(\\d+)\\..*$', E'\\1')::integer
    ELSE NULL END
$BODY$ LANGUAGE sql IMMUTABLE;

COMMENT ON FUNCTION director.equilar_id(text) 
    IS 'CREATED WITH ~/Dropbox/data/equilar/id_functions.sql';

  

