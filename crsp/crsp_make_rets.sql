-- Create a table that integrates basic returns with delisting returns
DROP TABLE IF EXISTS crsp.rets CASCADE;

CREATE TABLE crsp.rets AS
    SELECT coalesce(a.permno,b.permno) as permno, coalesce(a.date,b.dlstdt) as date, 
    	coalesce(1+a.ret,1)* coalesce(1+b.dlret,1)-1 AS ret 
    FROM crsp.dsf AS a
    FULL OUTER JOIN crsp.dsedelist AS b
    ON a.permno=b.permno and a.date = b.dlstdt
    WHERE a.ret IS NOT NULL OR b.dlret IS NOT NULL;

-- Add column for VWRETD
ALTER TABLE crsp.rets ADD COLUMN vwretd double precision;

-- Add column for DECRET
ALTER TABLE crsp.rets ADD COLUMN decret double precision;

-- Bring in data for DECRET
UPDATE crsp.rets AS a
	SET decret = (SELECT decret FROM crsp.erdport1 AS b 
                  WHERE a.permno=b.permno AND a.date=b.date);

-- Bring in data for VWRETD
UPDATE crsp.rets AS a
	SET vwretd = (SELECT vwretd FROM crsp.dsi AS b WHERE a.date=b.date);

-- Create an index/key on PERMNO, DATE
CREATE INDEX rets_idx ON crsp.rets (permno, date);
