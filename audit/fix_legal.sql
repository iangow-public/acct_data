ALTER TABLE audit.feed14case ADD COLUMN case_start_date date;
UPDATE audit.feed14case SET case_start_date=case_start_date_x::date;
ALTER TABLE audit.feed14case DROP COLUMN case_start_date_x;

ALTER TABLE audit.feed14case ADD COLUMN case_end_date date;
UPDATE audit.feed14case SET case_end_date=case_end_date_x::date;
ALTER TABLE audit.feed14case DROP COLUMN case_end_date_x;

ALTER TABLE audit.feed14case ADD COLUMN exp_start_date date;
UPDATE audit.feed14case SET exp_start_date=exp_start_date_x::date WHERE exp_start_date_s IS NOT NULL;
ALTER TABLE audit.feed14case DROP COLUMN exp_start_date_x;

ALTER TABLE audit.feed14case ADD COLUMN exp_end_date date;
UPDATE audit.feed14case SET exp_end_date=exp_end_date_x::date WHERE exp_end_date_s IS NOT NULL;
ALTER TABLE audit.feed14case DROP COLUMN exp_end_date_x;

ALTER TABLE audit.feed14case ALTER COLUMN legal_case_key TYPE integer;
ALTER TABLE audit.feed14case ALTER COLUMN law_court_key TYPE integer;
ALTER TABLE audit.feed14case ALTER COLUMN judge_key TYPE integer;
ALTER TABLE audit.feed14case ALTER COLUMN der_legal_case_fkey TYPE integer;
ALTER TABLE audit.feed14case ALTER COLUMN lcd_ref_id TYPE integer;

ALTER TABLE audit.feed14case ADD COLUMN create_date_temp date;
UPDATE audit.feed14case SET create_date_temp=create_date::date;
ALTER TABLE audit.feed14case DROP COLUMN create_date;
ALTER TABLE audit.feed14case RENAME COLUMN create_date_temp TO create_date;

ALTER TABLE audit.feed14case ADD COLUMN change_date_temp date;
UPDATE audit.feed14case SET change_date_temp=change_date::date;
ALTER TABLE audit.feed14case DROP COLUMN change_date;
ALTER TABLE audit.feed14case RENAME COLUMN change_date_temp TO change_date;

ALTER TABLE audit.feed14case DROP COLUMN case_start_date_s; 
ALTER TABLE audit.feed14case DROP COLUMN case_end_date_s;
ALTER TABLE audit.feed14case DROP COLUMN exp_start_date_s;
ALTER TABLE audit.feed14case DROP COLUMN  exp_end_date_s;

company_fkey text,
  auditor_key double precision,
   double precision,
   double precision,
   double precision,

ALTER TABLE audit.feed14party ADD COLUMN company_fkey_temp  integer;

UPDATE audit.feed14party SET company_fkey_temp=CASE WHEN company_fkey='.' THEN NULL ELSE company_fkey::integer END;
ALTER TABLE audit.feed14party DROP COLUMN company_fkey;
ALTER TABLE audit.feed14party RENAME COLUMN company_fkey_temp TO company_fkey;

ALTER TABLE audit.feed14party ALTER COLUMN auditor_key TYPE integer;
ALTER TABLE audit.feed14party ALTER COLUMN gov_key TYPE integer;
ALTER TABLE audit.feed14party ALTER COLUMN law_firm_key TYPE integer;
ALTER TABLE audit.feed14party ALTER COLUMN legal_case_key TYPE integer;

ALTER TABLE audit.feed14party ALTER COLUMN defendant TYPE boolean USING defendant=1;
ALTER TABLE audit.feed14party ALTER COLUMN plaintiff TYPE boolean USING plaintiff=1;
ALTER TABLE audit.feed14party ALTER COLUMN is_lead TYPE boolean USING is_lead=1;
ALTER TABLE audit.feed14party ALTER COLUMN consol TYPE boolean USING consol=1;
ALTER TABLE audit.feed14party ALTER COLUMN rel_non_party TYPE boolean USING rel_non_party=1;
ALTER TABLE audit.feed14party ALTER COLUMN rel_defendant TYPE boolean USING rel_defendant=1;
ALTER TABLE audit.feed14party ALTER COLUMN third_party TYPE boolean USING third_party=1;
ALTER TABLE audit.feed14party ALTER COLUMN is_debtor TYPE boolean USING is_debtor=1;
ALTER TABLE audit.feed14party ALTER COLUMN is_creditor TYPE boolean USING is_creditor=1;
ALTER TABLE audit.feed14party ALTER COLUMN been_terminated TYPE boolean USING been_terminated=1;



