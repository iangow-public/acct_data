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
    return sorted([list(s) for s in nx.connected_components(G)], key = len, reverse=True)

$BODY$ LANGUAGE plpythonu;

-- Create match table
DROP TABLE IF EXISTS director.director_matches;

CREATE TABLE director.director_matches AS

WITH

-- Get data on directors from Equilar table
raw_data AS (
    SELECT (director.equilar_id(director_id),
            director.director_id(director_id))::equilar_director_id AS director_id,
        (director.parse_name(director)).*,
        fileyear, director, company, fy_end, age, gender
    FROM director.director),

-- Match *across* firms within fileyear using gender and age (within one year)
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

-- Get BoardEx directorid data
boardex_match AS (
    SELECT DISTINCT director_id, directorid
    FROM director.boardex_match),

-- Create a duplicate copy BoardEx directorid data for matched IDs
other_boardex_match AS (
    SELECT DISTINCT director_id AS matched_id, directorid AS matched_directorid
    FROM director.boardex_match),

-- Merge in BoardEx IDs where available.
-- If an apparent match is associated with two different BoardEx IDs, then
-- it will be dropped at this point
with_boardex AS (
    SELECT a.director_id, a.matched_id,
        COALESCE(b.directorid, c.matched_directorid) AS directorid
    FROM match_within_year AS a
    LEFT JOIN boardex_match AS b
    USING (director_id)
    LEFT JOIN other_boardex_match AS c
    USING (matched_id)
    WHERE b.directorid=c.matched_directorid
        OR b.directorid IS NULL OR c.matched_directorid IS NULL),

-- Matches so far are within fileyear. But BoardEx IDs may allow additional
-- matches, which are created here.
match_using_boardex AS (
    SELECT a.director_id, b.director_id AS matched_id,
        directorid
    FROM director.boardex_match AS a
    INNER JOIN director.boardex_match AS b
    USING (directorid)
    WHERE a.director_id < b.director_id),

-- Combine matches. (Only distinct rows are retained due to use of UNION.)
both_matches AS (
    SELECT director_id, matched_id, directorid
    FROM with_boardex
    UNION
    SELECT director_id, matched_id, directorid
    FROM match_using_boardex),

-- Use networkx to make connected sets
connected_sets AS (
    SELECT
        director.get_connected(
            array_agg(director_id),
            array_agg(matched_id))::equilar_director_id[] AS matched_ids
    FROM both_matches),

-- Connected sets are arrays of director_id values (essentially a tuple of two
-- integers). This step adds a column with values of every director_id
-- in the connected sets.
unnested AS (
    SELECT unnest(matched_ids) AS director_id, matched_ids
    FROM connected_sets),

-- Many director_id values will have no matches.
unmatched AS (
    SELECT director_id, NULL::equilar_director_id[] AS matched_ids, directorid
    FROM boardex_match
    WHERE director_id NOT IN (
        SELECT director_id
        FROM unnested))

SELECT director_id, matched_ids, directorid
FROM unnested
INNER JOIN both_matches
USING (director_id)
UNION
SELECT director_id, matched_ids, directorid
FROM unmatched;

GRANT SELECT ON director.director_matches TO equilar_access;
