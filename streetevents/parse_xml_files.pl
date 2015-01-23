#!/usr/bin/env perl
use DBI;

## TODO(igow): I need to fix "HTML entities" (e.g., &amp;) before putting the data
##             into my database

# use module
use XML::LibXML;
use utf8; # just enables Unicode in the program.
use File::Basename;

# Add this to the program, before your print() statement to
# enable UTF-8 printing.
binmode(STDOUT, ":utf8");

$gz_file = @ARGV[0];

# Connect to my database
$dbname = "crsp";
my $dbh = DBI->connect("dbi:Pg:dbname=$dbname", 'igow')    
	or die "Cannot connect: " . $DBI::errstr;

# Run SQL to create the table
$dbh->do($sql);

# Create a reduce file_name (lose path and suffix)
$basename = basename($gz_file, @suffixlist);
$basename =~ s/\.xml(\.gz)?$//g;

print "$gz_file\n"; 
open($fh, "<", $gz_file) or die;
# Read in the compresszed file.
# my $fh = new IO::Uncompress::Gunzip $gz_file 
#      or die "IO::Uncompress::Gunzip failed: $GunzipError\n";

# initialize the parser
my $parser = new XML::LibXML;

# open a filehandle and parse
my $doc = $parser->parse_fh( $fh );
close $fh;

# I think in practice, there is only one event per file.
# But as the XML structure seems to allow for more than one,
# I do the same in my code.
foreach my $event ($doc->findnodes('/Event')) {
  my $type = $event->findvalue('./@eventTypeId');
  my $last_update = $event->findvalue('./@lastUpdate'); 

  # Pull out key fields.
  my $city = $event->findnodes('./city');
  my $co_name = $event->findnodes('./companyName');
  my $ticker = $event->findnodes('./companyTicker');
  my $desc = $event->findnodes('./eventTitle');
  my $date = $event->findnodes('./startDate');
  my $lines = $event->findnodes('./EventStory/Body');
  
  $city =~ s/\n//;
  # Skip calls without tickers
  if (!defined $ticker or $ticker =~ /^\s*$/) { next; } 
  
  # Remove leading spaces, multiple spaces and
  # escape single quates 
  $co_name =~ s/'/''/g;
  $co_name =~ s/^\s+//g;
  $co_name =~ s/\s+$//g;

  $desc =~ s/'/''/g;
  $desc =~ s/^\s+//g;
  $desc =~ s/\s+$//g;

  $city =~ s/'/''/g;
  $city =~ s/^\s+//g;
  $city =~ s/\s+$//g;

  # Output results num_sentences
  $sql = "INSERT INTO streetevents.calls_test 
            (file_path, file_name, ticker, co_name, call_desc, call_date,
             city, call_type, last_update ) ";
  $sql .= " VALUES ('$gz_file', '$basename', '$ticker', '$co_name', ";
  $sql .= "'$desc', '$date', '$city', '$type', '$last_update')";
  # print "$sql\n";
  $dbh->do($sql);

}

$dbh->disconnect();
