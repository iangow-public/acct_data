ALTER TABLE audit.feed17person ALTER COLUMN do_person_at_company_key TYPE integer;
-- Perhaps start with CEO turnover. What's the coverage like? Ask Sean for CEO turnover in our sample.


ALTER TABLE audit.feed17person ALTER COLUMN cd_personid_fkey TYPE integer;

ALTER TABLE audit.diroffichange ALTER COLUMN is_bdmem_pers TYPE integer;
ALTER TABLE audit.diroffichange ALTER COLUMN is_bdmem_pers TYPE boolean USING (is_bdmem_pers=1);

ALTER TABLE audit.diroffichange ALTER COLUMN is_ceo TYPE integer;
ALTER TABLE audit.diroffichange ALTER COLUMN is_ceo TYPE boolean USING (is_ceo=1);

ALTER TABLE audit.diroffichange ALTER COLUMN do_pers_co_key TYPE integer;
-- ALTER TABLE audit.feed17person ALTER COLUMN company_fkey TYPE integer;

SET maintenance_work_mem='2GB';


CREATE INDEX ON audit.diroffichange (do_pers_co_key);

CREATE INDEX ON audit.feed17person (do_person_at_company_key);
