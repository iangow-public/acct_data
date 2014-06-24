Data for accounting research
=========

This repository contains code to pull together data from various sources including:
- WRDS
- SEC EDGAR
- Ken French's website
- [Whalewisdom](whalewisdom/README.md)

Note that some of these data sets are proprietary, so the code will only work if you have access to the data in some form.

- `wrds_to_pg`: This Perl script takes the following options:
    - `--fix-missing`: SAS's `PROC EXPORT` converts special missing values (e.g., `.B`) to strings. So my code converts these to "regular" missing values so that PostgreSQL can handle them as missing values of the correct type.
    - `--wrds-id=wrds_id`: Specify your WRDS ID here
    - `--dbname=dbname`: My database is called `crsp`, so I say `--dbname=crsp` here
    - `--updated=some_string`: This is used by the script `wrds_to_pg_v2` to check if the table on WRDS has been updated since it was last pulled into the database.

- `wrds_to_pg_v2`: Except for `updated` this has the same options as the `wrds_to_pg` script. But this script compares the local and WRDS versions of the data and only updates if it needs to do so.

So 
```
wrds_to_pg_v2 crsp.msi --wrds_id=iangow --dbname=crsp
```
updates the monthly stock index file from CRSP and 
```
wrds_to_pg_v2 crsp.msf --wrds_id=iangow --dbname=crsp --fix-missing
```
updates the monthly stock file from CRSP (this file has special missing values, hence the additional flag).

Note that I use public-key authentication to access WRDS. Following hints taken from [here](http://www.debian-administration.org/articles/152), I set up a public key. I then copied that key to the WRDS server from the terminal on my computer. (Note that this code assumes you have a directory `.ssh` in your home directory. If not, log into WRDS via SSH, then type `mkdir ~/.ssh` to create this.) Here's code to create the key and send it to WRDS (for me):
```
ssh-keygen -t rsa
cat ~/.ssh/id_rsa.pub | ssh iangow@wrds.wharton.upenn.edu "cat >> ~/.ssh/authorized_keys"
```



