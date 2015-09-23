
-- Access scheme for basic users with WRDS access
GRANT USAGE ON SCHEMA public TO crsp_basic;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO crsp_basic;
GRANT USAGE ON SCHEMA comp TO crsp_basic;
GRANT SELECT ON ALL TABLES IN SCHEMA comp TO crsp_basic;
GRANT USAGE ON SCHEMA crsp TO crsp_basic;
GRANT SELECT ON ALL TABLES IN SCHEMA crsp TO crsp_basic;
GRANT USAGE ON SCHEMA filings TO crsp_basic;
GRANT SELECT ON ALL TABLES IN SCHEMA filings TO crsp_basic;
GRANT USAGE ON SCHEMA whalewisdom TO crsp_basic;
GRANT SELECT ON ALL TABLES IN SCHEMA whalewisdom TO crsp_basic;
GRANT USAGE ON SCHEMA ibes TO crsp_basic;
GRANT SELECT ON ALL TABLES IN SCHEMA ibes TO crsp_basic;
GRANT USAGE ON SCHEMA tfn TO crsp_basic;
GRANT SELECT ON ALL TABLES IN SCHEMA tfn TO crsp_basic;
GRANT USAGE ON SCHEMA boardex TO crsp_plus;
GRANT SELECT ON ALL TABLES IN SCHEMA boardex TO crsp_plus;
GRANT USAGE ON SCHEMA boardex_2014 TO crsp_plus;
GRANT SELECT ON ALL TABLES IN SCHEMA boardex_2014 TO crsp_plus;
GRANT USAGE ON SCHEMA ff TO crsp_basic;
GRANT SELECT ON ALL TABLES IN SCHEMA ff TO crsp_basic;

-- A little higher access
GRANT SELECT ON ALL TABLES IN SCHEMA boardex TO crsp_plus;
GRANT USAGE ON SCHEMA issvoting TO crsp_plus;
GRANT SELECT ON ALL TABLES IN SCHEMA issvoting TO crsp_plus;
GRANT USAGE ON SCHEMA irrc TO crsp_plus;
GRANT SELECT ON ALL TABLES IN SCHEMA irrc TO crsp_plus;
GRANT USAGE ON SCHEMA audit TO crsp_plus;
GRANT SELECT ON ALL TABLES IN SCHEMA audit TO crsp_plus;
GRANT USAGE ON SCHEMA boardex TO crsp_plus;
GRANT SELECT ON ALL TABLES IN SCHEMA boardex TO crsp_plus;
GRANT USAGE ON SCHEMA ciq TO crsp_plus;
GRANT SELECT ON ALL TABLES IN SCHEMA ciq TO crsp_plus;

-- Equilar access
GRANT ALL ON SCHEMA director TO equilar_access;
GRANT SELECT ON ALL TABLES IN SCHEMA director TO equilar_access;
GRANT ALL ON SCHEMA executive TO equilar_access;
GRANT SELECT ON ALL TABLES IN SCHEMA executive TO equilar_access;
GRANT ALL ON SCHEMA board TO equilar_access;
GRANT SELECT ON ALL TABLES IN SCHEMA board TO equilar_access;

-- Personality
GRANT USAGE ON SCHEMA streetevents TO personality_access;
GRANT SELECT ON ALL TABLES IN SCHEMA streetevents TO personality_access;
GRANT USAGE ON SCHEMA boardex TO personality_access;
GRANT SELECT ON ALL TABLES IN SCHEMA boardex TO personality_access;

--HBA
GRANT USAGE ON SCHEMA streetevents TO crsp_plus;
GRANT SELECT ON ALL TABLES IN SCHEMA streetevents TO crsp_plus;
GRANT USAGE ON SCHEMA boardex TO crsp_plus;
GRANT SELECT ON ALL TABLES IN SCHEMA boardex TO crsp_plus;




