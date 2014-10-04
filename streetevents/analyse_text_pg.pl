#!/usr/bin/perl
use DBI;
use POSIX qw(strftime);
use XML::LibXML;
use Lingua::Identify qw(:language_identification);
use utf8; # does not enable Unicode output - it enables you to type Unicode in your program.
use File::Basename;

# Add this to the program, before your print() statement:
binmode(STDOUT, ":utf8");

# Connect to my database
$dbname = "crsp";
my $dbh = DBI->connect("dbi:Pg:dbname=$dbname", 'igow')	
	or die "Cannot connect: " . $DBI::errstr;

# Create table to hold the data
$sql = "
  -- CREATE SCHEMA streetevents;

  DROP TABLE IF EXISTS streetevents.speaker_data;
  CREATE TABLE streetevents.speaker_data
(
  file_name text,
  speaker_name text,
  employer text,
  role text, 
  speaker_number integer,
	context text,
	speaker_text text,
  language text
) TABLESPACE hdd;
";

# Run SQL to create the table
$dbh->do($sql);

sub analyse_text {
  # Look for consecutive portions of text in this format:
  # -----------
  #  Something
  # -----------
  #  Something else
  # -----------
  # 
  # The something is the speaker, the something else is what they said.
  # Split using the lines of ---s and then process each portion.
  my %values = split(/---{3,}/, $_[0]);
  foreach my $speaker(keys %values) {
    my $the_text = $values{$speaker};
    
    # Remove carriage returns, double spaces, leading spaces
    # and tabs from speaker
    $speaker =~ s/\n/ /g;
    $speaker =~ s/\s{2,}/ /g;
    $speaker =~ s/^\s+//g;
    $speaker =~ s/\t+//g;
    
    # Remove new line characters, multiple spaces, and leading spaces
    # Escape single-quotes for insertion using SQL
    # (for example, "O'Donnell" becomes "O''Donnell"
    $the_text =~ s/\n/ /g;
    $the_text =~ s/^\s+//g;
    $the_text =~ s/\s{2,}/ /g;
    $the_text =~ s/'/''/g;

    if ($the_text =~ /\?$/) { 
      $context = "qa";
    }
     
    # First, pull out {name, employer, role} and number
    # (number will be digits in square brackets)
    $speaker_name=~ /^(.*)\s+\[(\d+)\]\s+$/;
    $full_name = $1;
    $number = $2;

    # Now parse {name, employer, role} into components
    $full_name =~ /^([^,]*),\s*(.*)\s+-\s+(.*)$/;
    $name = $1;
    $employer = $2;
    $role = $3;

    # Escape single-quotes for insertion using SQL
    # (for example, "O'Donnell" becomes "O''Donnell"
    $role =~ s/'/''/g;

    # Remove leading spaces, multiple spaces and
    # escape single quates
    $employer =~ s/^\s+//g;
    $employer =~ s/\s+$//g;
    $employer =~ s/'/''/g;
   
    # If no number, set to NA
    if ($number eq '') {
      $number="NULL";
    }

    # If we don't have role information, then we
    # don't have employer information either.
    if (!defined $role) {
      $employer= "";
      $role ="";
    }

    # Remove leading spaces, multiple spaces and
    # escape single quates     
    $name =~ s/'/''/g;
    $name =~ s/^\s+//g;
    $name =~ s/\s+$//g;

    # Insert processed data into the PostgreSQL table 
    $sql = "INSERT INTO streetevents.speaker_data VALUES ('$basename','$name','$employer',";
    $sql .= "'$role',$number,'$context','$the_text','$language')";
    $dbh->do($sql);
  }
}

# I have put the files into separate directories based on
# the last digit in the file name. 
for ($i = 0; $i <= 9; $i++) {

  # Get a list of files to parse
  $call_directory = "/Volumes/2TB/data/streetevents2013/";
  $file_list = $call_directory . "dir_" . $i . "/*.xml";
  @file_list = <"$file_list">;


  foreach $gz_file (@file_list) {
    $basename = basename($gz_file,@suffixlist);
    $basename =~ s/\.xml(\.gz)?$//g;
    open($fh, "<", $gz_file) or die;
   
    # initialize the parser
    my $parser = new XML::LibXML;
    
    # open a filehandle and parse
    # my $doc = $parser->parse_string( $temp );
    my $doc = $parser->parse_fh( $fh );
    close $fh;
    foreach my $event ($doc->findnodes('/Event')) {
      my $type = $event->findvalue('./@eventTypeId');
      
      if ($type ne '1') {
        next;
      }
    
      # In this code, we want to extract the ticker and body
      # of the call.
      my $ticker = $event->findnodes('./companyTicker');
      my $lines = $event->findnodes('./EventStory/Body');
      
      # Skip calls without tickers
      if (!defined $ticker or $ticker =~ /^\s*$/) { next; } 
     
      # Fix Windows line endings 
      $lines =~ s/\r\n/\n/g;
      
      # access XML data
      # Look for  the word "Presentation" between a row of ===s a row of ---s and 
      # then text followed by a row of ===s. Capture the latter text.  
      if ($lines =~ /={3,}\n(?:Presentation|Transcript)\n-{3,}(.*?)(?:={3,})/s) {
        $pres = $1;
      }
      
      # Try to guess the language 
      $language = langof($pres); # gives the most probable language

      # First, analyse the presentation
      $context = "pres";
      analyse_text($pres);

      # Next, do the same thing for Q&A as was done for the presentation
      if ($lines =~ /={3,}\nQuestions and Answers\n-{3,}(.*)$/s) {
        $qa = $1;
      }

      $context = "qa";
      analyse_text($qa);
    }
  }
}

# Fix permissions and set up indexes
$sql = "
  SET maintenance_work_mem='10GB';
  CREATE INDEX ON streetevents.speaker_data (file_name);
  -- UPDATE streetevents.speakers SET employer=trim(employer);";
$dbh->do($sql);

$dbh->disconnect();

