SET work_mem='10GB';

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
    SELECT DISTINCT (equilar_id,director_id)::equilar_director_id AS director_id,
        executive_id
    FROM director.director_ids
    -- WHERE executive_id=593849
),

-- Match using Equilar's executive_id field
equilar_match AS (
    SELECT DISTINCT a.director_id, b.director_id AS matched_id, executive_id
    FROM raw_data AS a
    INNER JOIN raw_data AS b
    USING (executive_id)),

-- Get BoardEx directorid data
boardex_match AS (
    SELECT DISTINCT director_id, directorid
    FROM director.boardex_match),

-- Create a duplicate copy BoardEx directorid data for matched IDs
other_boardex_match AS (
    SELECT DISTINCT director_id AS matched_id, directorid AS matched_directorid
    FROM director.boardex_match),

-- Merge in BoardEx IDs where available.
-- Keep observations if an apparent match is associated with two different BoardEx IDs
problematic_exec_ids AS (
    SELECT DISTINCT executive_id
    FROM equilar_match AS a
    LEFT JOIN boardex_match AS b
    USING (director_id)
    LEFT JOIN other_boardex_match AS c
    USING (matched_id)
    WHERE b.directorid !=c.matched_directorid),

-- Merge in BoardEx IDs where available.
-- If an apparent match is associated with two different BoardEx IDs, then
-- it will be dropped at this point.
with_boardex AS (
    SELECT a.director_id, a.matched_id, a.executive_id,
        COALESCE(b.directorid, c.matched_directorid) AS directorid
    FROM equilar_match AS a
    LEFT JOIN boardex_match AS b
    USING (director_id)
    LEFT JOIN other_boardex_match AS c
    USING (matched_id)
    WHERE b.directorid=c.matched_directorid
        OR ((b.directorid IS NULL OR c.matched_id IS NULL) AND
             a.executive_id NOT IN (SELECT executive_id FROM problematic_exec_ids))),

-- Matches so far done by Equilar. But BoardEx IDs may allow additional
-- matches, which are created here.
match_using_boardex AS (
    SELECT a.director_id, b.director_id AS matched_id,
        directorid
    FROM raw_data
    INNER JOIN director.boardex_match AS a
    USING (director_id)
    INNER JOIN director.boardex_match AS b
    USING (directorid)
    WHERE a.director_id < b.director_id),

-- Combine matches. (Only distinct rows are retained due to use of UNION.)
both_matches AS (
    SELECT DISTINCT director_id, matched_id, directorid
    FROM with_boardex
    UNION
    SELECT director_id, matched_id, directorid
    FROM match_using_boardex
),

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
    SELECT DISTINCT unnest(matched_ids) AS director_id, matched_ids
    FROM connected_sets),

-- Now bring in directorid matches where available and line them
-- up with the connected sets.
directorids AS (
    SELECT director_id, directorid, matched_ids
    FROM both_matches
    INNER JOIN unnested
    USING (director_id)
    WHERE directorid IS NOT NULL),

-- Aggregate the directorids using the matches we have
directorids_array AS (
    SELECT matched_ids, array_agg(DISTINCT directorid) AS directorids
    FROM directorids
    GROUP BY matched_ids),

-- Now bring in executive_id matches where available and line them
-- up with the connected sets.
executive_ids AS (
    SELECT DISTINCT director_id, executive_id, matched_ids
    FROM raw_data
    INNER JOIN unnested
    USING (director_id)
    WHERE executive_id IS NOT NULL),

-- Aggregate the executive_ids using the matches we have
executive_ids_array AS (
    SELECT DISTINCT matched_ids, array_agg(DISTINCT executive_id) AS executive_ids
    FROM executive_ids
    GROUP BY matched_ids)

SELECT DISTINCT a.director_id, matched_ids, UNNEST(directorids) AS directorid, executive_ids
FROM raw_data AS a
LEFT JOIN unnested
USING (director_id)
INNER JOIN both_matches
USING (director_id)
INNER JOIN executive_ids_array
USING (matched_ids)
INNER JOIN directorids_array
USING (matched_ids);

GRANT SELECT ON director.director_matches TO equilar_access;
