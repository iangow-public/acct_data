Data for accounting research
=========
**UPDATE:** Code related to [WRDS](https://wrds-web.wharton.upenn.edu/wrds/) was moved to a [new repository](https://github.com/iangow/wrds_pg) on 27 September 2015.

This repository contains code to pull together data from various sources including:
- [SEC EDGAR](http://www.sec.gov/edgar/searchedgar/webusers.htm)
- Ken French's [website](http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html)
- [Whalewisdom](whalewisdom/README.md)

Note that some of the data sets I use are proprietary, so the code will only work if you have access to the data in some form.

## Requirements

### 1. Git

While not strictly necessary to use the scripts here, [Git](https://git-scm.com/downloads) likely makes it easier to download and to update.

I keep all Git repositories in `~/git`. So to get this repository, I could do:

```
cd ~/git
git clone https://github.com/iangow/acct_data.git
```

This will create a copy of the repository in `~/git/acct_data`.
Note that one can get updates to the repository by going to the directory and "pulling" the latest code:

```
cd ~/git/acct_data
git pull
```

Alternatively, I think you could fork the repository on GitHub and then clone. 
I think that cloning using the SSH URL (e.g., `git@github.com:iangow/acct_data.git`) is necessary for Git pulling and pushing to work well in RStudio.

### 2. Perl

Many of the scripts rely on Perl (I use MacPorts, which I think currently defaults to v5.16).
In addition, the Perl scripts generally interact with PostgreSQL using the Perl
module `DBD::Pg` (see [here](http://search.cpan.org/dist/DBD-Pg/Pg.pm)). 
I use MacPorts to install this `sudo port install p5-dbd-pg`.
On Ubuntu, `sudo apt-get install libdbi-perl libdbd-pg-perl` would work.

### 3. R

A number of scripts rely on R.
This can be obtained [here](https://cran.rstudio.com/).
I recommend [RStudio](https://www.rstudio.com/products/RStudio/);
in fact, this repository is set up as an RStudio project (open the file [acct_data.Rproj](blob/master/acct_data.Rproj) in RStudio).

### 4. PostgreSQL

You should have a PostgreSQL database to store the data.
There are also some data dependencies in that some scripts assume the existence of other data in the database.
For example, scripts that download filings generally refer to the PostgreSQL table `filings.filings` created by the script [get_filings.R](blob/master/filings/get_filings.R).

### 5. Bash

A number of scripts here are Bash shell scripts.
These should work on Linux or OS X, but not on Windows (unless you have Cygwin or something like it; see [here](http://stackoverflow.com/questions/6413377/is-there-a-way-to-run-bash-scripts-on-windows)).

I also assume that `psql` (command-line interface to PostgreSQL) is on the path.
I have MacPorts on my path (in `~/.profile` I set `export PATH=/opt/local/bin:/opt/local/sbin:$PATH`) and I can ensure that PostgreSQL is on my path by setting `sudo port select postgresql postgresql94` (v9.4 being current at the time of writing).

### 6. Environment variables

I am migrating the scripts, etc., from using hard-coded values (e.g., my WRDS ID `iangow`) to using environment variales. 
Environment variables that I use include:

- `PGDATABASE`: The name of the PostgreSQL database you use.
- `PGUSER`: Your username on the PostgreSQL database.
- `PGHOST`: Where the PostgreSQL database is to be found (this will be `localhost` if its on the same machine as you're running the code on)
- `EDGAR_DIR`: The local location of a partial mirror of EDGAR.
- `PGBACKUP_DIR`: The directory where backups of PostgreSQL data created by `pg_dump` should go.

I set these environment variables in `~/.profile`:

```
export PGHOST="localhost"
export PGDATABASE="crsp"
export EDGAR_DIR="/Volumes/2TB/data"
export PGUSER="igow"
export PGBACKUP_DIR="/Users/igow/Dropbox/pg_backup/"
```

I also set them in `~/.Rprofile`, as RStudio doesn't seem to pick up the settings in `~/.profile` in recent versions of OS X:

```
Sys.setenv(EDGAR_DIR="/Volumes/2TB/data")
Sys.setenv(PGHOST="localhost")
Sys.setenv(PGDATABASE="crsp")
Sys.setenv(PGBACKUP_DIR="/Users/igow/Dropbox/pg_backup/")
```
