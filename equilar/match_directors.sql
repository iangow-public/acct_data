SET work_mem='5GB';

-- CREATE TYPE equilar_director_id AS (equilar_id integer, director_id integer);

DROP TABLE IF EXISTS director.director_matches;

CREATE TABLE director.director_matches AS
WITH raw_data AS (
    SELECT (director.equilar_id(director_id), director.director_id(director_id))::equilar_director_id AS director_id,
        (director.parse_name(director)).*, director, company, fy_end, age, gender
    FROM director.director)

SELECT DISTINCT a.director_id, 
    array_agg(DISTINCT b.director_id) AS matched_ids
FROM raw_data AS a
INNER JOIN raw_data AS b
ON a.last_name=b.last_name AND a.first_name=b.first_name AND abs(a.age - b.age) < 3
    AND a.gender=b.gender AND a.director_id != b.director_id
GROUP BY a.director_id;
