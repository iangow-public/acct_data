DROP VIEW IF EXISTS crsp.erdport1;

CREATE VIEW crsp.erdport1 AS
WITH c AS (
	SELECT a.permno, a.ret, a.date, b.capn
	FROM crsp.dsf AS a
	INNER JOIN crsp.dport1 AS b
	ON a.permno=b.permno AND extract (year FROM a.date)=b.year)
SELECT c.*, d.decret 
FROM c
INNER JOIN crsp.erdport AS d
ON c.date=d.date AND c.capn=d.capn;

-- SELECT * FROM crsp.erdport1 WHERE permno=10001 AND date BETWEEN '1986-01-09' AND '1986-01-16';

DROP VIEW IF EXISTS crsp.ermport1;

CREATE VIEW crsp.ermport1 AS
SELECT c.*, d.decret FROM 
	(SELECT a.permno, a.ret, a.date, b.capn
	FROM crsp.dsf AS a
	INNER JOIN crsp.mport1 AS b
	ON a.permno=b.permno AND extract (year FROM a.date)=b.year) AS c
INNER JOIN crsp.ermport AS d
ON c.date=d.date AND c.capn=d.capn;
