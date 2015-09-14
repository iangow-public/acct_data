SET work_mem='1GB';

WITH 

directors AS (
    SELECT director_id, equilar_id(director_id) AS equilar_id,
        director_id(director_id) AS equilar_director_id, start_date, 
        term_end_date, fileyear, director, company
    FROM director.director
    WHERE start_date IS NOT NULL),

mult_starts AS (
    SELECT equilar_id, equilar_director_id, count(DISTINCT start_date)
    FROM directors
    GROUP BY equilar_id, equilar_director_id
    HAVING count(DISTINCT start_date) > 1)

SELECT equilar_id, equilar_director_id, 
    array_agg(DISTINCT director) AS director_names,
    array_agg(DISTINCT start_date) AS start_dates,
    array_agg(DISTINCT term_end_date) AS term_end_dates
FROM directors
INNER JOIN mult_starts
USING (equilar_id, equilar_director_id)
GROUP BY equilar_id, equilar_director_id
ORDER BY equilar_id, equilar_director_id;
