#!/usr/bin/env perl

# Script to import StreetEvents conference call data into my
# PostgreSQL database
# Author: Ian Gow
# Last modified: 2013-06-25

# use various modules module
use DBI;
use POSIX qw(strftime);
use XML::LibXML;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use Lingua::Identify qw(:language_identification);
use utf8; # does not enable Unicode output - it enables you to type Unicode in your program.
use File::Basename;
use HTML::Entities;

# Add this to the program, before your print() statement:
binmode(STDOUT, ":utf8");

# Connect to my database
$dbname = "crsp";
my $dbh = DBI->connect("dbi:Pg:dbname=$dbname", 'igow')	
	or die "Cannot connect: " . $DBI::errstr;

# Create the table to store the data.
$sql = "
  -- CREATE SCHEMA streetevents;

  DROP TABLE IF EXISTS streetevents.speaker_test;
  CREATE TABLE streetevents.speaker_test
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
  foreach my $speaker (keys %values) {
    my $the_text = $values{$speaker};
    $speaker =~ s/\n/ /g;
    $speaker =~ s/\s{2,}/ /g;
    $speaker =~ s/^\s+//g;
    $speaker =~ s/\t+//g;
    
    $the_text =~ s/\n/ /g;
    $the_text =~ s/^\s+//g;
    $the_text =~ s/\s{2,}/ /g;
    $the_text =~ s/'/''/g;

    if ($the_text =~ /\?$/) { 
      $context = "qa";
    }
     
    $speaker =~ /^(.*)\s+\[(\d+)\]\s+$/;
    $full_name = $1;
    $number = $2;
    $full_name =~ /^([^,]*),\s*(.*)\s+-\s+(.*)$/;
    $name = $1;
    $employer = $2;
    $role = $3;

    $role =~ s/'/''/g;

    $employer =~ s/^\s+//g;
    $employer =~ s/\s+$//g;
    $employer =~ s/'/''/g;
   
    if ($number eq '') {
      $number="NULL";
    } #=~ s/^$/NULL/;
     
    $name =~ s/'/''/g;
    $name =~ s/^\s+//g;
    $name =~ s/\s+$//g;

    if (!defined $role) {
      $employer= "";
      $role ="";
    }
    
    # Output results num_sentences
    $sql = "INSERT INTO streetevents.speaker_test VALUES ('$basename', '$name', '$employer', ";
    $sql .= "'$role',$number, '$context', '$the_text', '$language')";
    $dbh->do($sql);
  }
}

for ($i = 0; $i <= 9; $i++) {
  # Get a list of files to parse
  $call_directory = "/Volumes/2TB/data/streetevents2013/";
  $file_list = $call_directory . "dir_" . $i . "/*.xml";
  # print "$file_list\n";
  @file_list = <"$file_list">;
  # @file_list = @file_list[0..10];

  foreach $gz_file (@file_list) {
    $basename = basename($gz_file,@suffixlist);
    $basename =~ s/\.xml(\.gz)?$//g;
    # $basename =~ s/\.xml$//g;
    open($fh, "<", $gz_file) or die;
   
    # initialize the parser
    my $parser = new XML::LibXML;
    
    # open a filehandle and parse
    # my $doc = $parser->parse_string( $temp );
    my $doc = $parser->parse_fh( $fh );
    close $fh;
    foreach my $event ($doc->findnodes('/Event')) {
      my $type = $event->findvalue('./@eventTypeId');
      
      # if ($type ne '1') {
      #  next;
      # }
    
      my $ticker = $event->findnodes('./companyTicker');
      my $lines = decode_entities($event->findnodes('./EventStory/Body'));
      
      # Skip calls without tickers
      if (!defined $ticker or $ticker =~ /^\s*$/) { next; } 
      
      $lines =~ s/\r\n/\n/g;
      
      # access XML data
      # Look for  the word "Presentation" between a row of ===s a row of ---s and 
      # then text followed by a row of ===s. Capture the latter text.  
      if ($lines =~ /={3,}\n(?:Presentation|Transcript)\n-{3,}(.*?)(?:={3,})/s) {
        $pres = $1;
      }
      
      # Skip file if language isn't English 
      $language = langof($pres); # gives the most probable language
      # if ($language ne "en") { next; }

      $context = "pres";
      analyse_text($pres);

      # Now do the same thing for Q&A as was done for the presentation
      if ($lines =~ /={3,}\nQuestions and Answers\n-{3,}(.*)$/s) {
        $qa = $1;
      }

      $context = "qa";
      analyse_text($qa);
    }
  }
}

# Fix permissions and set up indexes
#$sql = "ALTER TABLE issvoting.npx OWNER TO activism";
# $dbh->do($sql);

$sql = "
  SET maintenance_work_mem='10GB';
  CREATE INDEX ON streetevents.speaker_test (file_name);
  -- UPDATE streetevents.speakers SET employer=trim(employer);

  GRANT ALL ON streetevents.speaker_test TO aaz";
$dbh->do($sql);

$dbh->disconnect();
# Open each file and extract the contents into a string $lines

