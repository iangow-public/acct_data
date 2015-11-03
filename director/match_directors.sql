SET work_mem='5GB';

-- CREATE TYPE equilar_director_id AS (equilar_id integer, director_id integer);

-- Add PL/Python function using networkX to generate connected sets.
CREATE OR REPLACE FUNCTION director.get_connected(
    lhs equilar_director_id[],
    rhs equilar_director_id[])
  RETURNS SETOF text[] AS
$BODY$
    pairs = zip(lhs, rhs)

    import networkx as nx
    G=nx.Graph()
    G.add_edges_from(pairs)
    return sorted(nx.connected_components(G), key = len, reverse=True)

$BODY$ LANGUAGE plpythonu;

-- Create match table
DROP TABLE IF EXISTS director.director_matches;

CREATE TABLE director.director_matches AS
WITH raw_data AS (
    SELECT (director.equilar_id(director_id),
            director.director_id(director_id))::equilar_director_id AS director_id,
        (director.parse_name(director)).*,
        fileyear, director, company, fy_end, age, gender
    FROM director.director),

match_within_year AS (
    SELECT DISTINCT a.director_id, b.director_id AS matched_id
    FROM raw_data AS a
    INNER JOIN raw_data AS b
    ON a.last_name=b.last_name
    AND a.first_name=b.first_name AND abs(a.age - b.age) <= 1
        AND a.fileyear=b.fileyear
        AND a.gender=b.gender
        AND ((b.director_id).equilar_id > (a.director_id).equilar_id OR
        ((b.director_id).equilar_id = (a.director_id).equilar_id AND
         (b.director_id).equilar_id > (a.director_id).equilar_id))),

with_boardex AS (
    SELECT a.director_id, a.matched_id,
        COALESCE(b.directorid, c.directorid) AS directorid
    FROM match_within_year AS a
    LEFT JOIN director.boardex_match AS b
    ON a.director_id=b.director_id
    LEFT JOIN director.boardex_match AS c
    ON a.director_id=c.director_id
    WHERE b.directorid=c.directorid
        OR b.directorid IS NULL OR c.directorid IS NULL),

connected_sets AS (
    SELECT
        director.get_connected(array_agg(director_id),
        array_agg(matched_id))::equilar_director_id[] AS matched_ids
    FROM with_boardex),

unnested AS (
    SELECT unnest(matched_ids) AS director_id, matched_ids
    FROM connected_sets)

SELECT director_id, matched_ids, directorid
FROM unnested
INNER JOIN with_boardex
USING (director_id);

GRANT SELECT ON director.director_matches TO equilar_access;
