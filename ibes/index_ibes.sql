SET maintenance_work_mem='10GB';
CREATE INDEX ON ibes.detu_epsus (ticker, revdats);
CREATE INDEX ON ibes.statsumu_epsus (ticker, statpers);