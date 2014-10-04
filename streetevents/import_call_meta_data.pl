#!/usr/bin/perl
use DBI;
use POSIX qw(strftime);


# Connect to my database
$dbname = "crsp";
my $dbh = DBI->connect("dbi:Pg:dbname=$dbname", 'igow')	
	or die "Cannot connect: " . $DBI::errstr;

# Create a table
$sql = "
  DROP TABLE IF EXISTS streetevents.calls;
  CREATE TABLE streetevents.calls
(
  file_name text,
  ticker text,
  co_name text,
  call_desc text,
  call_date timestamp without time zone,
  city text,
  call_type integer);
";

# Run SQL to create the table
$dbh->do($sql);

# Use PostgreSQL's COPY function to get data into the database
$time = localtime; 
$now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;
$filename = "call_meta_data.txt.gz";
printf "Beginning import of $filename at $now_string\n";  

# Note that some of the ISS files have empty lines at the end. This stops
# PostgreSQL's COPY command dead. For some reason, I can't get sed to detect
# these as empty lines. So, I simply insert \. into any last line that doesn't
# begin with a number. This \. is an EOF flag for COPY. 
$cmd  = "gunzip -c \"$filename\" | sed 's/\\\"//g'  ";
$cmd .=  "| /usr/local/pgsql/bin/psql -U igow ";
$cmd .= "-d $dbname -c \"COPY streetevents.calls FROM STDIN CSV HEADER ";
$cmd .= "DELIMITER '\t' \";";
print "$cmd\n";
$result = system($cmd);
print "Result of system command: $result\n";

$now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;
printf "Completed import of $filename at $now_string\n"; 

# Fix permissions and set up indexes
#$sql = "ALTER TABLE issvoting.npx OWNER TO activism";
# $dbh->do($sql);

$sql = "
  SET maintenance_work_mem='10GB';
  CREATE INDEX ON streetevents.calls (file_name)";
$dbh->do($sql);

$dbh->disconnect();
