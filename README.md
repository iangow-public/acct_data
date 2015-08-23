Data for accounting research
=========

This repository contains code to pull together data from various sources including:
- [WRDS](https://wrds-web.wharton.upenn.edu/wrds/)
- SEC EDGAR
- Ken French's website
- [Whalewisdom](whalewisdom/README.md)

Note that some of these data sets are proprietary, so the code will only work if you have access to the data in some form.

## Requirements

### 1. Perl

Many of the scripts rely on Perl. 
In addition, the Perl scripts generally interact with PostgreSQL using the Perl
module `DBD::Pg` (see [here](http://search.cpan.org/dist/DBD-Pg/Pg.pm). 
I use MacPorts to install this `sudo port install p5-dbd-pg`.

### 2. R

A number of scripts rely on R.
This can be obtained [here](https://cran.rstudio.com/).
I recommend [RStudio](https://www.rstudio.com/products/RStudio/);
in fact, this repository is set up as an RStudio project (open the file [acct_data.Rproj](blob/master/acct_data.Rproj) in RStudio).

### 3. PostgreSQL

You should have a PostgreSQL database to store the data.
There are also some data dependencies in that some scripts assume the existence of other data in the database.
For example, scripts that download filings generally refer to the PostgreSQL table `filings.filings` created by the script [get_filings.R](blob/master/filings/get_filings.R).

- [] TODO: Document data dependencies

### 4. Bash

A number of scripts here are Bash shell scripts.
These should work on Linux or OS X, but not on Windows (unless you have Cygwin or something like it; see [here](http://stackoverflow.com/questions/6413377/is-there-a-way-to-run-bash-scripts-on-windows)).

### 5. Environment variables

I am migrating the scripts, etc., from using hard-coded values (e.g., my WRDS ID `iangow`) to using environment variales. 
Environment variables that I use include:

- `PGDATABASE`: The name of the PostgreSQL database you use.
- `PGUSER`: Your username on the PostgreSQL database.
- `PGHOST`: Where the PostgreSQL database is to be found (this will be `localhost` if its on the same machine as you're running the code on)
- `WRDS_ID`: Your [WRDS](https://wrds-web.wharton.upenn.edu/wrds/) ID.
- `EDGAR_DIR`: The local location of a partial mirror of EDGAR.

I set these environment variables in `~/.profile`:

```
export PGHOST="localhost"
export PGDATABASE="crsp"
export EDGAR_DIR="/Volumes/2TB/data"
export WRDS_ID="iangow"
export PGUSER="igow"
```

I also set them in `~/.Rprofile`, as RStudio doesn't seem to pick up the settings in `~/.profile` in recent versions of OS X:

```
Sys.setenv(EDGAR_DIR="/Volumes/2TB/data")
Sys.setenv(PGHOST="localhost")
Sys.setenv(PGDATABASE="crsp")
```

### 6. A WRDS ID

Note that I use public-key authentication to access WRDS. Following hints taken from [here](http://www.debian-administration.org/articles/152), I set up a public key. I then copied that key to the WRDS server from the terminal on my computer. (Note that this code assumes you have a directory `.ssh` in your home directory. If not, log into WRDS via SSH, then type `mkdir ~/.ssh` to create this.) Here's code to create the key and send it to WRDS (for me):

```
ssh-keygen -t rsa
cat ~/.ssh/id_rsa.pub | ssh iangow@wrds.wharton.upenn.edu "cat >> ~/.ssh/authorized_keys"
```

## Illustration of use of scripts

- `wrds_to_pg.pl`: This Perl script takes the following arguments:
    - `--fix-missing`: SAS's `PROC EXPORT` converts special missing values (e.g., `.B`) to strings. So my code converts these to "regular" missing values so that PostgreSQL can handle them as missing values of the correct type.
    - `--wrds-id=wrds_id`: Specify your WRDS ID here. My WRDS ID is `iangow`, so I say `--wrds-id=iangow` here.
    - `--dbname=dbname`: My database is called `crsp`, so I say `--dbname=crsp` here.
    - `--updated=some_string`: This is used by the script `wrds_to_pg_v2` to check if the table on WRDS has been updated since it was last pulled into the database.
    - `--obs=obs`: Optional argument to limit the number of observations imported from WRDS. For example, `--obs=1000` will limit the data to 1000 observations.

- `wrds_to_pg_v2.pl`: Except for `updated` this has all the options that `wrds_to_pg.pl` has. But this script compares the local and WRDS versions of the data and only updates if it needs to do so. Additionally, `wrds_to_pg_v2.pl` accepts a command-line argument `--force`, which forces update regardless of whether an update has occurred (this is useful for debugging).

So 
```
wrds_to_pg_v2.pl crsp.msi --wrds_id=iangow --dbname=crsp
```
updates the monthly stock index file from CRSP and 
```
wrds_to_pg_v2.pl crsp.msf --wrds_id=iangow --dbname=crsp --fix-missing
```
updates the monthly stock file from CRSP (this file has special missing values, hence the additional flag).





