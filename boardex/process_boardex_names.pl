#!/usr/bin/env perl

#######################################################################
# This module goes through directors in the BoardEx database          #
# and parses names of directors  into first names and last names.     #
#  This facilitates matching with data from other sources             #
#######################################################################
#use warnings "all"
use DBI; # Database interface package
use utf8; # does not enable Unicode output - it enables you to type Unicode in your program.
binmode STDOUT, ":encoding(utf8)";
$ENV{'PERL_UNICODE'}=1;
use Env qw($PGDATABASE $PGUSER $PGUSER $PGHOST);

# Set up database connection
$PGDATABASE = $PGDATABASE ? $PGDATABASE : "crsp";
$PGUSER = $PGUSER ? $PGUSER : "igow";
#!/usr/bin/env perl
$PGHOST= $PGHOST ? $PGHOST : "localhost";

my $dbh = DBI->connect("dbi:Pg:dbname=$PGDATABASE;host=$PGHOST", "$PGUSER")
	or die "Cannot connect: " . $DBI::errstr;
$dbh->{pg_enable_utf8} = 1;

# Make a table to store data. Delete the existing version of the table.
$sql = "SET client_encoding TO 'UTF8'; DROP TABLE IF EXISTS boardex.director_names";
$dbh->do($sql);
$sql = "CREATE TABLE boardex.director_names (directorname text, ";
$sql .= "prefix text, last_name text, first_name text, ";
$sql .= "suffix text)";
$dbh->do($sql);

# Pull out unique director names from BoardEx
my $sth = $dbh->prepare(
    "SELECT DISTINCT director_name FROM
		(SELECT * FROM boardex.director_characteristics) AS a");
$sth->execute();

# For each director name...
while (my @row = $sth->fetchrow_array) {

    $row[0] =~ s/'/''/g;        # Escape single-quotes (for SQL)
    $temp = $row[0];
    $temp    =~ s/\*//g;        # Remove asterisks
    $temp =~ s/\s{2,}/ /g;      # Remove any multiple spaces
    $temp =~ s/The Duke Of/Duke/i;
    $temp =~ s/(The (Right|Rt\.)? )?Hon(ou?rable|\.) /Rt. Hon. /i;

    print "$temp\n";

    $name = $temp; # Text identified as name

    if ($name =~ ",") {
        # If there's a comma, put the part after the first comma into a suffix
        ($first_name, $last_name, $suffix) = $name =~ /^\s?(.*?)\s+([\w']*?)\s?,\s?(.*)\s?$/;
    } elsif (($first_name, $last_name, $suffix) =
        # Some suffixes are not always separated by a comma, but we can be confident that
        # they're suffixes. Pull these out too.
		$name =~ /^(.*)\s+(.*?)\s+(JR\s?\.?|SR\s?\.?|PH\.?D\.?|II|III|IV|V|VI|M\.?D\.?|\(RET(\.|ired)?\)|3D|CBE)$/i) {
    } else {
		$name =~ s/\s+$//;
		# If there's no suffix...
		($first_name, $last_name) = $name =~ /^(.*)\s+(.*?)$/;
		$suffix="";
    }

	# Pull out prefixes like Mr, Dr, etc.
	($prefix, $first_name) = $first_name =~
		/^((?:Amb\.|Ambassador|(?:Rear|Vice )?(?:Adm\.|Admiral)|RADM|(?:Maj\. |Major )?Gen\.)\.? )?(.*)$/i;
	if ($prefix eq "") {    ($prefix, $first_name) = $first_name =~
							 /^((?:(?:Lieutenant |Major )?General)\.? )?(.*)$/i;
	}
	if ($prefix eq "") { ($prefix, $first_name) = $first_name =~
	 						 /^(Professor Dr |Professor  Dr )?(.*)$/i;
	}
	if ($prefix eq "") { ($prefix, $first_name) = $first_name =~
							 /^((?:Lt Gen|Hon\.|Prof\.|Professor|Doctor|Rev\.|Rt\. Hon\.?|Sir|Dr|Mr|Mrs|Ms)\.? )?(.*)$/i;
	}
	if ($prefix eq "") { ($prefix, $first_name) = $first_name =~
							 /^(Sen\. |Senator )?(.*)$/i;
	}
	if ($prefix eq "") { ($prefix, $first_name) = $first_name =~
							 /^(Air (?:(?:Chief |Vice )?Marshal |Commodore )(?:Sir )?)?(.*)$/i;
	}
	if ($prefix eq "") { ($prefix, $first_name) = $first_name =~
							 /^(Doctor )?(.*)$/i;
	}
	if ($prefix eq "") { ($prefix, $first_name) = $first_name =~
	 						 /^(Shri |Tan Sri Dato |The Hon\. |The Rt\. Hon |Lt\. Gen\. |Major |Madam |General Sir )?(.*)$/i;
	}

	# Put the processed data into the PostgreSQL table
	$sql ="INSERT INTO boardex.director_names  ";
	$sql .="(directorname, prefix, last_name, first_name, suffix) ";
	$sql .= "VALUES('$row[0]', '$prefix','$last_name', '$first_name', '$suffix');";

	eval { $dbh->do($sql); };

}

# Clean things up and then disconnect from the database.
$sth-> finish;

$dbh->disconnect;
print "Disconnected\n";
