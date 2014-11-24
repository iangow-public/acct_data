DROP TABLE IF EXISTS director.percent_owned;

CREATE TABLE director.percent_owned AS 

WITH stanford AS (
  SELECT equilar_id(company_id), fy_end, director_name, percent_shares_owned,
    last_name, first_name
  FROM board.director AS a
  INNER JOIN board.director_names AS b
  ON a.director_name=b.original_name
  WHERE percent_shares_owned IS NOT NULL),
	
hbs AS (
  SELECT equilar_id(director_id), fy_end, director_id(director_id) AS director_id, a.director,
    last_name, first_name
  FROM director.director AS a
  INNER JOIN director.director_names AS b
  ON a.director=b.original_name),
	
common_firm_years AS (
  SELECT DISTINCT equilar_id, fy_end
  FROM hbs AS a
  INNER JOIN stanford AS b
  USING (equilar_id, fy_end)),
	
name_matches AS (
  SELECT 
    a.equilar_id, 
    a.fy_end,
    a.director_id,
    a.director, 
    COALESCE(b.director_name, c.director_name) AS director_name,
    COALESCE(b.percent_shares_owned, c.percent_shares_owned)
      AS percent_shares_owned,
    COALESCE(b.equilar_id, c.equilar_id) IS NOT NULL AS on_stanford
  FROM hbs AS a
  LEFT JOIN stanford AS b
  ON a.equilar_id=b.equilar_id AND a.fy_end=b.fy_end AND 
    lower(a.director)=lower(b.director_name)
  LEFT JOIN stanford AS c
  ON a.equilar_id=c.equilar_id AND a.fy_end=c.fy_end AND 
    lower(a.last_name)=lower(c.last_name))

SELECT *
FROM common_firm_years
INNER JOIN name_matches
USING (equilar_id, fy_end)
ORDER BY equilar_id, fy_end, director;  

ALTER TABLE director.percent_owned OWNER TO activism;
