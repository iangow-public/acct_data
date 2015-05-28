# Audit Analytics (`audit`)

Audit Analytics contains the following data sets.

The Bash script `update_audit.sh` runs the other code to update the schema `audit`.


### "To do" items

- Fix `get_feed09.R`: This should be in the Bash script.
- Fix `get_feed09filing.R`: This could be done more with an updated version of `wrds_to_pg_v2` that allowed the destination table to have a different name from the source table.