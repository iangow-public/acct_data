SET maintenance_work_mem='10GB';

CREATE INDEX ON director.director ( equilar_id(director_id));

CREATE INDEX ON director.director ( director);
-- CREATE INDEX ON  director.director_names ( director);
CREATE INDEX ON director.co_fin  ( equilar_id(company_id));
