#!/usr/bin/env bash
psql -f audit/fix_legal.sql
psql -f audit/get_aa_data.sql