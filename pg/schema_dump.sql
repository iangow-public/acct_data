pg_dump --host 192.168.1.2 --username "igow" --format custom --no-tablespaces -O --verbose --schema "activist_director" "crsp" | pg_restore --host localhost --username "igow" --dbname "crsp"   --verbose
pg_dump --host 192.168.1.2 --username "igow" --format custom --no-tablespaces -O --verbose --schema "whalewisdom" "crsp" | pg_restore --host localhost --username "igow" --dbname "crsp"   --verbose
pg_dump --host 192.168.1.2 --username "igow" --format custom --no-tablespaces -O --verbose --schema "comp" "crsp" | pg_restore --host localhost --username "igow" --dbname "crsp"   --verbose

pg_dump --host 192.168.1.2 --username "igow" --format custom --no-tablespaces -O --verbose --schema "ff" "crsp" | pg_restore --host localhost --username "igow" --dbname "crsp"   --verbose

pg_dump --host 192.168.1.2 --username "igow" --format custom --no-tablespaces -O --verbose --schema "director" "crsp" | pg_restore --host localhost --username "igow" --dbname "crsp"   --verbose

pg_dump --host 192.168.1.2 --username "igow" --format custom --no-tablespaces -O --verbose --schema "filings" "crsp" | pg_restore --host localhost --username "igow" --dbname "crsp"   --verbose

pg_dump --host iangow.me --format custom --no-tablespaces -O --verbose --schema "personality" "crsp" | pg_restore --host localhost --dbname "crsp" --verbose
