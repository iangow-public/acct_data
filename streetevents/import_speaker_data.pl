#!/usr/bin/env perl

# Script to import StreetEvents conference call data into my
# PostgreSQL database
# Author: Ian Gow
# Last modified: 2015-01-04

# use various modules module
use DBI;
use POSIX qw(strftime);
use XML::LibXML;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use Lingua::Identify qw(:language_identification);
use utf8; # does not enable Unicode output - it enables you to type Unicode in your program.
use File::Basename;
use HTML::Entities;
use Time::localtime;
use Env qw($PGDATABASE);

$gz_file = @ARGV[0];

# Add this to the program, before your print() statement
binmode(STDOUT, ":utf8");

# Connect to my database
$dbname = "crsp";
my $dbh = DBI->connect("dbi:Pg:dbname=$dbname", 'igow')	
	or die "Cannot connect: " . $DBI::errstr;

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
    $speaker =~ /^(.*)\s+\[(\d+)\]\s+$/;
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
   
    if ($number eq '') {
      $number="NULL";
    }
    
    # Remove leading spaces, multiple spaces and
    # escape single quates 
    $name =~ s/'/''/g;
    $name =~ s/^\s+//g;
    $name =~ s/\s+$//g;

    if (!defined $role) {
      $employer= "";
      $role ="";
    }
    print("$sql\n");
     
    # Output results num_sentences
    $sql = "INSERT INTO streetevents.speaker_data VALUES ('$basename', '$name', '$employer', ";
    $sql .= "'$role',$number, '$context', '$the_text', '$language')";
    $dbh->do($sql);
  }
}

# Get a list of files to parse

$basename = basename($gz_file,@suffixlist);
$basename =~ s/\.xml(\.gz)?$//g;
open($fh, "<", $gz_file) or die;

# initialize the parser
my $parser = new XML::LibXML;

# open a filehandle and parse
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
  if ($lines =~ /={3,}\n(?:Presentation|Transcript)\n-{3,}(.*?)(?:={3,}|$)/s) {
    $pres = $1;
  }
  
  # Skip file if language isn't English 
  if (defined $pres) { $language = langof($pres); } # gives the most probable language
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

$dbh->disconnect();

