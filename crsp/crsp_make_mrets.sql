-- #!/usr/local/pgsql/bin/psql -d crsp
-- Create a table that integrates basic returns with delisting returns
DROP TABLE IF EXISTS crsp.mrets CASCADE;

CREATE TABLE crsp.mrets AS
    SELECT c.*, d.vwretd FROM
        (SELECT a.*, b.decret FROM
            (SELECT coalesce(a.permno,b.permno) as permno, coalesce(a.date,b.dlstdt) as date, 
    	        coalesce(1+a.ret,1)* coalesce(1+b.dlret,1)-1 AS ret 
            FROM crsp.msf AS a
            FULL OUTER JOIN crsp.msedelist AS b
            ON a.permno=b.permno and a.date = b.dlstdt
            WHERE a.ret IS NOT NULL OR b.dlret IS NOT NULL) AS a
        LEFT JOIN crsp.ermport1 AS b
        ON a.permno=b.permno AND a.date=b.date) AS c
    LEFT JOIN crsp.msi AS d
    ON eomonth(c.date)=eomonth(d.date);

-- Create an index/key on PERMNO, DATE
CREATE INDEX ON crsp.mrets (permno, date);
