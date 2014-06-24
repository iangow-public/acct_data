#!/usr/bin/env perl
use DBI;
use POSIX qw(strftime);

$dbname = "crsp";
$user = "igow";

my $dbh = DBI->connect("dbi:Pg:dbname=$dbname", $user)    
    or die "Cannot connect: " . $DBI::errstr;

$sql = "
    
    CREATE SCHEMA IF NOT EXISTS whalewisdom;
    DROP TABLE IF EXISTS whalewisdom.quarters CASCADE;
    DROP TABLE IF EXISTS whalewisdom.other_managers CASCADE;
    DROP TABLE IF EXISTS whalewisdom.filing_stock_records CASCADE;
    DROP TABLE IF EXISTS whalewisdom.filers CASCADE;
    DROP TABLE IF EXISTS whalewisdom.filings CASCADE;
    DROP TABLE IF EXISTS whalewisdom.stocks CASCADE;

    CREATE TABLE whalewisdom.quarters
(
    quarter_id integer,
    end_of_quarter_date date,
    PRIMARY KEY(quarter_id)
);

    CREATE TABLE whalewisdom.other_managers
(
    id integer NOT NULL,
    filer_id integer,
    name text,
    file_number text,
    manager_number integer,
    quarter_id integer
);

    CREATE TABLE whalewisdom.filing_stock_records
(
    id integer,
    filing_id integer,
    stock_id integer,
    stock_record_name text,
    alt_name text,
    title text,
    cusip_number text,
    alt_cusip text,
    market_value double precision,
    shares int8,
    security_type text,
    manager_number text 
);

CREATE TABLE whalewisdom.filers
(
    filer_id integer NOT NULL,
    filer_name text,
    street_address text,
    city text,
    state text,
    state_incorporation text,
    zip_code text,
    business_phone text,
    cik integer,
    irs_number integer,
    PRIMARY KEY(filer_id)

);

CREATE TABLE whalewisdom.filings
(
    filing_id integer NOT NULL,
    filer_id integer,
    form_type text,
    sec_file_number text,
    period_of_report date,
    filed_as_of_date date,
    mv_multiplier double precision,
    edgar_url text,
    filing_type text,
    created_at timestamp without time zone,
    quarter_id integer,
    PRIMARY KEY(filing_id)
);

CREATE TABLE whalewisdom.stocks
(
    stock_id integer NOT NULL,
    stock_name text,
    ticker text,
    new_stock_id integer,
    is_delisted integer,
    delisting_date date,
    sector text,
    industry text,
    PRIMARY KEY(stock_id)
);    

";

# Run SQL to create the table
$dbh->do($sql);
$filename = "~/Dropbox/data/whalewisdom/whalewisdom_raw_snapshot_2014-5-28.tgz";
# Use PostgreSQL's COPY function to get data into the database
foreach $item ("quarters", "other_managers", "filers", "stocks", "filings", "filing_stock_records")
{
    $time = localtime; 
    $now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;
    # $filename = "" .$item . ".csv";
    
    printf "Beginning import of $item at $now_string\n";    
 
    # Pipe unzipped file ...
    $cmd    = " tar -xf $filename --include=$item.csv --to-stdout";

    # Get rid of double quotes
    $cmd .= "| sed 's/\"\"//g'";
    
    # Get rid of strange values
    $cmd .= "| sed 's/99999999999999999999//'";
    
    # Delete empty lines
    $cmd .= "| sed '/^\\s*\$/d' ";

    # Now send to database
    $cmd .= "| psql -U $user ";
    $cmd .= "-d $dbname -c \"COPY whalewisdom." .$item . " FROM STDIN CSV HEADER \" ";

    # print "$cmd\n";
    $result = system($cmd);
    print "Result of system command: $result\n";

    $now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;
    $sql = "COMMENT ON TABLE whalewisdom.$item IS 'Created using $filename at $now_string'";
    $dbh->do($sql);

    $dbh->do($sql);

    printf "Completed import of $item.csv at $now_string\n"; 
}

# Fix permissions and set up indexes
printf "Making indexes\n";
$sql = "
    SET maintenance_work_mem='10GB';
    CREATE INDEX ON whalewisdom.filing_stock_records (cusip_number);
    CREATE INDEX ON whalewisdom.filing_stock_records (filing_id);";
$dbh->do($sql);

$now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;
printf "Completed making indexes at $now_string\n"; 


# Fix erroneous filings (these duplicate other filings and 
# appear to be under the wrong SEC file number).
# One filing is
# http://www.sec.gov/Archives/edgar/data/1319943/000090445408000057/0000904454-08-000057.txt
# which seems to be a duplicate of
# http://www.sec.gov/Archives/edgar/data/1353180/000090445408000067/0000904454-08-000067.txt
# but has SEC FILE NUMBER: 028-11736 in the header and Form 13F File Number: 28-11722 in the text.
# Similarly,
# http://www.sec.gov/Archives/edgar/data/1129787/000112978707000084/0001129787-07-000084.txt
# seems to be a duplicate of
# http://www.sec.gov/Archives/edgar/data/1351069/000141881208000076/0001418812-08-000076.txt 
$sql = "
    DELETE FROM whalewisdom.filings
    WHERE filing_id IN (10793, 13337);";
$dbh->do($sql);

$dbh->disconnect();
