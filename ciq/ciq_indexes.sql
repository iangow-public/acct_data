SET maintenance_work_mem='3GB';

CREATE INDEX ON ciq.wrds_keydev (companyid);

CREATE INDEX ON ciq.wrds_keydev (keydeveventtypeid);
