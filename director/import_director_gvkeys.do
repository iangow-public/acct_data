odbc load, table("director.director_gvkeys") noquote dsn("iangow") clear

compress

destring valid_date valid_date_cik, replace

generate has_gvkey = gvkey !=""

table has_gvkey
