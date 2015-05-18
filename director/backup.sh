#!/usr/bin/env bash
pg_dump --host localhost --username "igow" --format custom --no-tablespaces --verbose --file ~/Dropbox/pg_backup/director.backup --schema "director" "crsp" --no-owner
