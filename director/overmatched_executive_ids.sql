WITH

-- Get data on directors from Equilar table
raw_data AS (
    SELECT equilar_id, director_id, executive_id
    FROM director.director_ids),

-- Match using Equilar's executive_id field
equilar_match AS (
    SELECT DISTINCT a.equilar_id, a.director_id,
        b.equilar_id AS matched_equilar_id, b.director_id AS matched_director_id,
        executive_id
    FROM raw_data AS a
    INNER JOIN raw_data AS b
    USING (executive_id)),

-- Get BoardEx directorid data
boardex_match AS (
    SELECT DISTINCT (director_id).*, directorid
    FROM director.boardex_match),

-- Create a duplicate copy BoardEx directorid data for matched IDs
other_boardex_match AS (
    SELECT DISTINCT equilar_id AS matched_equilar_id, director_id AS matched_director_id,
        directorid AS matched_directorid
    FROM boardex_match)

-- Merge in BoardEx IDs where available.
-- Keep observations if an apparent match is associated with two different BoardEx IDs
SELECT a.*
FROM equilar_match AS a
LEFT JOIN boardex_match AS b
USING (equilar_id, director_id)
LEFT JOIN other_boardex_match AS c
USING (matched_equilar_id, matched_director_id)
WHERE b.directorid !=c.matched_directorid
    AND a.equilar_id < a.matched_equilar_id
