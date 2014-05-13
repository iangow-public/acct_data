#!/opt/local/bin/perl
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use Text::CSV_XS;
use DBI;

# Get schema and table name from command line. I have set my database
# up so that these line up with the names of the WRDS library and data
# file, respectively.
$table_name = "ermport";
$db_schema = "crsp";

$db = "pwd";

# I call my database "crsp" (for legacy reasons)
$dbname = "crsp";

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


	* Edit the following to refer to the table of interest;
	%let db=$db;
	%let table_name= $table_name;
	%let suffix=_schema;
	%let filetype=.csv;
	%let outcsv=&table_name&suffix&filetype;

	* Use PROC CONTENTS to extract the information desired.;
	proc contents data=pwd.ermport out=schema noprint;
	run;

	* Do some preprocessing of the results;
	data schema(keep=name postgres_type);
		set schema(keep=name format formatl formatd length type);
		format postgres_type \\\$36.;
		if format=\\\"YYMMDDN\\\" then postgres_type=\\\"date\\\";
	  	else if type=1 then do;
			if formatd ^= 0 then postgres_type = \\\"float8\\\";
			if formatd = 0 and formatl ^= 0 then postgres_type = \\\"int8\\\";
			if formatd = 0 and formatl =0 then postgres_type = \\\"float8\\\";
	  	end;
	  	else if type=2 then postgres_type = \\\"text\\\";
	run;

	* Now dump it out to a CSV file;
	proc export data=schema outfile=stdout dbms=csv;
	run;";

# Run the SAS code on the WRDS server and save the result to ./schema.csv
`echo "$sas_code" | ssh -C iangow\@wrds.wharton.upenn.edu 'sas -stdio -noterminal' | cat > schema.csv`;

my $schema_csv = Text::CSV_XS->new ({ binary => 1 });

# Read in schema.csv and parse the data therein.
# (It might be possible to parse this directly from a pipe from WRDS,
#  but there are a lot of messy details in CSV files that I avoid this way.)
$schema = "schema.csv";
open my $io, "<", $schema or die "$schema: $!";
while (my $row = $schema_csv->getline ($io)) {
	my @fields = @$row;
	my $field = @fields[0];
	$field =~ s/^do$/do_/i;
	my $type = @fields[1];
	$hrec{$field} = $type;
#	print "$field, $type\n";
}

# Clean up, etc.
$schema_csv->eof or $schema_csv->error_diag;
close $io or die "$schema: $!";

# Now, get the first row of the SAS data file from WRDS. This is important,
# as we need to put the table together so as to align the fields with the data
# (the "schema" code above doesn't do this for us).
$sas_code = "
    libname pwd '.';

	proc export data=pwd.$table_name(obs=1)
            outfile=stdout
            dbms=csv;
        run;";

# Run the SAS command and put the output into ./data.csv.gz
@result = `echo "$sas_code" | ssh -C iangow\@wrds.wharton.upenn.edu 'sas -stdio -noterminal' | gzip > data.csv.gz`;
$gz_file = "data.csv.gz";

# Get the first row of the text file
my $csv = Text::CSV_XS->new ({ binary => 1 });
my $fh = new IO::Uncompress::Gunzip $gz_file 
        or die "IO::Uncompress::Gunzip failed: $GunzipError\n";

$row = $csv->getline($fh);

# Get table information from the "schema" file
my $dbh = DBI->connect("dbi:Pg:dbname=$dbname", 'igow', 'test')	
	or die "Cannot connect: " . $DBI::errstr;

# $schema = "schema/$table_name" . "_schema.csv";
# $db_schema = "crsp";

$dbh->do("SET search_path TO $db_schema");

$sql = "CREATE TABLE $table_name (";

# Set some default/initial parameters
$first_field = 1;
$sep="";
$has_date = 0;
$has_gvkey = 0;
$i=0;
# Construct SQL fragment associated with each variable for 
# the table creation statement
foreach $field (@$row) {
	# Flag some key fields for indexing. Probably should use the schema file
	# to indicate what fields should be used for indexing. Not sure if
	# WRDS SAS file contains useful information in this regard.
	if ($field =~ /^GVKEY$/i) { $has_gvkey = 1; }
	if ($field =~ /^DATADATE$/i) { $has_datadate = 1; }
	if ($field =~ /^PERMNO$/i) { $has_permno = 1; }
	if ($field =~ /^DATE$/i) { $has_date = 1;}
	$field =~ s/^do$/do_/i;

	# Dates are stored as integers initially, then converted to 
	# dates later on (see below).
	if ($hrec{$field} eq "date") {
		$type = $hrec{$field};
		# $type = "integer";
	} else {
		$type = $hrec{$field};
	}

	# Concatenate the component strings. Note that, apart from the first
	# field a leading comma is inserted to separate fields in the 
	# CREATE TABLE SQL statement.
	$sql = $sql . $sep . $field . " " . $type;
	if ($first_field) { $sep=", "; $first_field=0; }
}
$sql = $sql . ");";
print "$sql\n";

if(TRUE) {
	# Clean up, etc.
	$csv->eof or $csv->error_diag;
	close $fh or die "$gz_file: $!";

	# Drop the table if it exists already, then create the new table
	# using field names taken from the first row
	$dbh->do("DROP TABLE IF EXISTS $table_name CASCADE;");
	$dbh->do($sql);

	# Get the data
	$sas_code = "
        libname pwd '.';

		proc export data=pwd.$table_name outfile=stdout dbms=csv;
        run;";
	# print "$sas_code";

	# Use PostgreSQL's COPY function to get data into the database
	$time = localtime;
	printf "Beginning file import at %d:%02d:%02d\n",@$time[2],@$time[1],@$time[0];
	$cmd = "echo \"$sas_code\" | ssh -C iangow\@wrds.wharton.upenn.edu 'sas -stdio -noterminal'";
	$cmd .= " | psql -U igow ";
	$cmd .= "-d $dbname -c \"COPY $db_schema.$table_name FROM STDIN CSV HEADER ENCODING 'latin1' \"";

	print "$cmd\n";
	$result = system($cmd);
	print "Result of system command: $result\n";

	$time = localtime;
	printf "Completed file import at %d:%02d:%02d\n",@$time[2],@$time[1],@$time[0];
}

$dbh->disconnect();
