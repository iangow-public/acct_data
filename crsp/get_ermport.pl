#!/usr/bin/env perl
use DBI;

my $dbname = $PGDATABASE;
my $use_st = '';
my $wrds_id = 'iangow';	# option variable with default value
GetOptions('fix-missing' => \$fix_missing,
            'wrds-id=s' => \$wrds_id,
            'dbname=s' => \$dbname); 

# SAS code to extract information about the datatypes of the SAS data.
# Note that there are some date formates that don't work with this code.
$sas_code = "
	
	libname pwd '.';

    PROC SQL;
        CREATE TABLE pwd.ermport AS
        SELECT DISTINCT date, capn, decret
        FROM crsp.ermport1
        ORDER BY date, capn;
    quit;

	* Now dump it out to a CSV file;
	proc export data=pwd.ermport outfile=stdout dbms=csv;
	run;";

# Get table information from the "schema" file
my $dbh = DBI->connect("dbi:Pg:dbname=$dbname")	
	or die "Cannot connect: " . $DBI::errstr;


$sql = "
DROP TABLE IF EXISTS crsp.ermport CASCADE;

CREATE TABLE crsp.ermport
(
  date date,
  capn bigint,
  decret double precision
)";

	# Use PostgreSQL's COPY function to get data into the database
	$time = localtime;
	printf "Beginning file import at %d:%02d:%02d\n",@$time[2],@$time[1],@$time[0];
	$cmd = "echo \"$sas_code\" | ssh -C $wrds_id\@wrds.wharton.upenn.edu 'sas -stdio -noterminal'";
	$cmd .= " | psql -d $dbname -c \"COPY crsp.ermport FROM STDIN CSV HEADER ENCODING 'latin1' \"";

	print "$cmd\n";
	$result = system($cmd);
	print "Result of system command: $result\n";

	$time = localtime;
	printf "Completed file import at %d:%02d:%02d\n",@$time[2],@$time[1],@$time[0];
}

$dbh->disconnect();
