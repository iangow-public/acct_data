#!/opt/local/bin/perl
use DBI;
use POSIX qw(strftime);

$dbname = "crsp";
my $dbh = DBI->connect("dbi:Pg:dbname=$dbname", 'igow')	
	or die "Cannot connect: " . $DBI::errstr;

$sql = "
  DROP TABLE IF EXISTS issvoting.npx;
  CREATE TABLE issvoting.npx
(
  instid integer,
  institutionname text,
  fundid integer,
  fundname text,
  companyid integer,
  companyname text,
  companycountryinc text,
  securityid text,
  securityidtype text,
  version text,
  meetingid integer,
  meetingdate date,
  issagendaitemid text,
  agendageneraldesc text,
  itemonagendaid integer,
  seqnumber integer,
  ballotitemnumber text,
  itemdesc text,
  mgtrec text,
  issrec text,
  fundvote text)";

# Run SQL to create the table
$dbh->do($sql);

# Use PostgreSQL's COPY function to get data into the database
for ($year = 2003; $year <= 2011; $year++) {
  $time = localtime; 
  $now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;
  $filename = "/Users/igow/Dropbox/data/va/";
  $filename .= "ISSRec_VoteAnalysis" . $year . "_" . ($year+1) . ".zip";
  printf "Beginning import of $filename at $now_string\n";  

  # Note that some of the ISS files have empty lines at the end. This stops
  # PostgreSQL's COPY command dead. For some reason, I can't get sed to detect
  # these as empty lines. So, I simply insert \. into any last line that doesn't
  # begin with a number. This \. is an EOF flag for COPY. 
  $cmd  = " unzip -p \"$filename\"  | sed -E '\$ s/^[^0-9]/\\\\\\\./'  ";
  $cmd .=  "| psql -U igow ";
  $cmd .= "-d $dbname -c \"COPY issvoting.npx FROM STDIN CSV HEADER ";
  $cmd .= "DELIMITER '\t' ENCODING 'latin1' \";";
  $result = system($cmd);
  print "Result of system command: $result\n";

  $now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;
  printf "Completed import of $filename at $now_string\n"; 
}

# Fix permissions and set up indexes
$sql = "ALTER TABLE issvoting.npx OWNER TO activism";
$dbh->do($sql);

$sql = "
  SET maintenance_work_mem='10GB';
  CREATE INDEX ON issvoting.npx (itemonagendaid);
  CREATE INDEX ON issvoting.npx (fundid);
  CREATE INDEX ON issvoting.npx (securityid)";
$dbh->do($sql);

$dbh->disconnect();
