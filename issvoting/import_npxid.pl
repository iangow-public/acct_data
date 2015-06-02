#!/opt/local/bin/perl
use DBI;
use POSIX qw(strftime);

$dbname = "crsp";
my $dbh = DBI->connect("dbi:Pg:dbname=$dbname", 'igow')	
	or die "Cannot connect: " . $DBI::errstr;

$sql = "
  DROP TABLE IF EXISTS issvoting.npx_id;
  CREATE TABLE issvoting.npx_id
(
  instid integer,
  meetingid integer,
  fundid integer,
  npx_file_id text)";

# Run SQL to create the table
$dbh->do($sql);

# Use PostgreSQL's COPY function to get data into the database
for ($year = 2003; $year <= 2011; $year++) {
  $time = localtime; 
  $now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;
  $filename = "/Users/igow/Dropbox/data/va/";
  $filename .= "NPX_File_ID_july_01_" . $year . "_June_30_" . ($year+1) . ".txt.gz";
  printf "Beginning import of $filename at $now_string\n";  

  # Note that some of the ISS files have empty lines at the end. This stops
  # PostgreSQL's COPY command dead. For some reason, I can't get sed to detect
  # these as empty lines. So, I simply insert \. into any last line that doesn't
  # begin with a number. This \. is an EOF flag for COPY. 
  $cmd  = "gunzip -c \"$filename\" ";
  $cmd .=  "| psql -U igow ";
  $cmd .= "-d $dbname -c \"SET datestyle=\"ymd\"; COPY issvoting.npx_id FROM STDIN CSV HEADER ";
  $cmd .= "DELIMITER '\t' ENCODING 'latin1' \";";
  $result = system($cmd);
  print "Result of system command: $result\n";

  $now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;
  printf "Completed import of $filename at $now_string\n"; 
}

# Fix permissions and set up indexes
$sql = "
  SET maintenance_work_mem='1GB';
  ALTER TABLE issvoting.npx_id OWNER TO activism;
  CREATE INDEX ON issvoting.npx_id (npx_file_id);
  CREATE INDEX ON issvoting.npx_id (fundid)";
$dbh->do($sql);

$dbh->disconnect();
