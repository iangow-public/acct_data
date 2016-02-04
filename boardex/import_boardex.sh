#!/usr/bin/env bash
rsync -avz researchgrid.hbs.edu:/nas-vol/projects/data_vol3/jzeitler_project/Boardex/201507/CSV/ \
    $EDGAR_DIR/boardex/ --include=*.csv --exclude=*.zip

gzip $EDGAR_DIR/boardex/*.csv

