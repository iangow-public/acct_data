-- Create a table that integrates basic returns with delisting returns
SET work_mem='6GB';

DROP TABLE IF EXISTS crsp.rets_alt CASCADE;

CREATE TABLE crsp.rets_alt AS
    WITH 
    dsf_plus AS (
        SELECT 
            coalesce(a.permno,b.permno) as permno,
            coalesce(a.date,b.dlstdt) as date, 
            coalesce(1+a.ret,1) * coalesce(1+b.dlret,1)-1 AS ret 
        FROM crsp.dsf AS a
        FULL OUTER JOIN crsp.dsedelist AS b
        ON a.permno=b.permno and a.date = b.dlstdt
        WHERE a.ret IS NOT NULL OR b.dlret IS NOT NULL),
    
    dsf_w_erdport AS (
        SELECT a.*, b.decret 
        FROM dsf_plus AS a
        LEFT JOIN crsp.erdport1 AS b
        ON a.permno=b.permno AND a.date=b.date)
    
    SELECT c.*, d.vwretd
    FROM dsf_w_erdport AS c
    LEFT JOIN crsp.dsi AS d
    ON c.date=d.date;

-- Create an index/key on PERMNO, DATE
RESET work_mem;

SET maintenance_work_mem='6GB';
CREATE INDEX ON crsp.rets_alt (permno, date);

DROP TABLE IF EXISTS crsp.rets;
DROP VIEW IF EXISTS crsp.rets;
CREATE VIEW crsp.rets AS SELECT * FROM crsp.rets_alt;

ANALYZE crsp.rets_alt;

