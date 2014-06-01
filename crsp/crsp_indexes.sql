SET maintenance_work_mem='10GB';

CREATE INDEX ON crsp.anncdates (anncdate);
CREATE INDEX ON crsp.ccmxpf_linktable (lpermno);
CREATE INDEX ON crsp.ccmxpf_linktable (gvkey);
CREATE INDEX ON crsp.ccmxpf_lnkhist (gvkey);
CREATE INDEX ON crsp.dport1 (permno, date);
CREATE INDEX ON crsp.dsedelist (permno);
CREATE INDEX ON crsp.dsedist (permno);
CREATE INDEX ON crsp.dseexchdates (permno);
CREATE INDEX ON crsp.dsf (permno, date);
CREATE INDEX ON crsp.dsi (date);
CREATE INDEX ON crsp.msf (permno, date);
CREATE INDEX ON crsp.msi (date);
CREATE INDEX ON crsp.dseexchdates (permno);
