ANALYZE crsp.rets_alt;

-- Create an index/key on PERMNO, DATE
RESET work_mem;

SET maintenance_work_mem='10GB';
CREATE INDEX ON crsp.rets_alt (permno, date);

CREATE VIEW crsp.rets AS SELECT * FROM crsp.rets_alt;