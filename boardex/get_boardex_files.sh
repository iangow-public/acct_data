#!/usr/bin/env bash
export DROPBOX_DIR=~/Dropbox/data/
rm -rf $DROPBOX_DIR/boardex
rsync -avz researchgrid.hbs.edu:/nas-vol/projects/data_vol3/jzeitler_project/Boardex/201507/CSV/ \
    $DROPBOX_DIR/boardex/ --include=*20150717.csv --exclude=*.zip  --exclude=Lookup*.csv
gzip $DROPBOX_DIR/boardex/*.csv

