#!/usr/bin/perl

## TODO(igow): I need to fix "HTML entities" (e.g., &amp;) before putting the data
##             into my database

# use module
use XML::LibXML;
use utf8; # just enables Unicode in the program.
use File::Basename;

# Add this to the program, before your print() statement to
# enable UTF-8 printing.
binmode(STDOUT, ":utf8");

# Output a header row
print "file\tticker\tco_name\tdesc\tdate\tcity\ttype\n";

# There are ten directories to go through
for ($i = 0; $i <= 9; $i++) {
  # Get a list of files to parse
  $call_directory = "/Volumes/2TB/data/streetevents2013/";
  $file_list = $call_directory . "dir_" . $i . "/*.xml";
  @file_list = <"$file_list">;

  # Open each file and extract the contents into a string $lines
  foreach $gz_file (@file_list) {

    # Create a reduce file_name (lose path and suffix)
    $basename = basename($gz_file,@suffixlist);
    $basename =~ s/\.xml(\.gz)?$//g;
   
    # print "$gz_file\n"; 
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
      
      # I'm only interested in earnings announcements
      #if ($type ne '1') {
      #  next;
      #}
    
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
      
      # Output results
      print "$basename\t$ticker\t$co_name\t$desc\t$date\t$city\t$type\n";
    }
  }
}
# print "\n";
