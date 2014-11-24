#!/usr/bin/env bash
pg_dump --host localhost --username "igow" --format custom --no-tablespaces --verbose --file ~/Dropbox/pg_backup/board.backup --schema "board" "crsp" --no-owner

pg_dump --host localhost --username "igow" --format custom --no-tablespaces --verbose --file ~/Dropbox/pg_backup/director.backup --schema "director" "crsp" --no-owner

pg_dump --host localhost --username "igow" --format custom --no-tablespaces --verbose --file ~/Dropbox/pg_backup/executive.backup --schema "executive" "crsp" --no-owner
