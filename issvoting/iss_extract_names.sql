-- DROP TYPE IF EXISTS parsed_name CASCADE;
--
 CREATE TYPE parsed_name AS
    (prefix text,
    first_name text,
     middle_initial text,
     last_name text,
     suffix text);
--
-- ALTER TYPE parsed_name OWNER TO personality_access;

DROP FUNCTION IF EXISTS issvoting.extract_name(text);

CREATE OR REPLACE FUNCTION issvoting.extract_name(text)
RETURNS parsed_name AS
$CODE$
    use utf8;
    $first_name="";
    $last_name="";
    $name = "";
    $prefix = "";
    $last_name_suffix = "";
    $suffix = "";

    if (defined($_[0])) {

        # Fix misspellings
        $temp = $_[0];
        $misspellings = 'irector|Dirctor|Director Director|Directror|Driector|Directo';
        $temp =~ s/\b($misspellings)\b/Director/;
        $temp =~ s/\bTurstee/Trustee/;

        # Fix other errors
        $temp	=~ s/\*//g;			# Remove asterisks
        $temp =~ s/\s{2,}/ /g;		# Remove any multiple spaces
        $temp =~ s/by (majority|plurality) vote$//i;	# Delete certain phrases
        $temp =~ s/ as .*Director//;
        $temp =~ s/ (as|by Holders of) (Class (A|B) )?(Common )?Stock//i;
        $temp =~ s/ \(Don't Advance\)//i;
        $temp =~ s/ \(DO NOT ADVANCE\)//i;
        $temp =~ s/Philip R, Roth/Philip R. Roth/;
        $temp =~ s/The Duke Of/Duke/i;
        $temp =~ s/Keith A, Meister/Keith A. Meister/;
        $temp =~ s/(The (Right|Rt\.)? )?Hon(ou?rable|\.) /Rt. Hon. /i;
        $temp =~ s/Elect Director Norman S. Edelcup Elect.*/Elect Director Norman S. Edelcup/i;
        $temp =~ s/Require Majority Vote to Elect Directors in an Uncontested Election//i;
        $temp =~ s/Elect Director ohn\s+/Elect Director John /;

        # Change alternative forms
        $temp =~  s/Elect\s+(.*)\sas Director/Elect Director \1/;

        # Look for forms like "Elect Ian D. Gow" (i.e., no words other than "elect" and the name
        if (($temp =~ /^Elect(?! Director)/) && 
          !($temp =~ /\b(Auditors|Trust|Director|Company|Members|Inc\.|of|as|to)\b/)) {
          $temp =~ s/Elect (.*)/Elect Director \1/; 
        }

        # Pull out text after "Elect director";
        # if the word "and" appears, delete the observation
        # as there are multiple names.
        if(!($temp  =~ /\sand\s/i) && $temp =~ /(?:Elect\s+Directors?)\s+(.+)$/i) {
            $name = $1;

            # Remove leading spaces
            $name =~ s/^\s+//;

            if ($name =~ ",") {

                # If there's a comma, put the part after the first comma into a suffix
                if ($name =~ /(.+?)\s+([\w']*?)\s?,\s?(.*)\s?$/) {
                    ($first_name, $last_name, $suffix) = ($1, $2, $3);
                }

            # Some suffixes are not always separated by a comma, but we can be confident that
            # they're suffixes. Pull these out too.
            } elsif ($name =~
                    /^(.*)\s+(.*?)\s+(JR\s?\.?|PH\.?D\.?|II|III|IV|V|VI|M\.?D\.?|\(RET(\.|ired)?\)|3D|CBE)$/i) {
                    ($first_name, $last_name, $suffix) =  ($1, $2, $3);
            } else {
                $name =~ s/\s+$//;
                # If there's no suffix...
                if ($name =~ /^(.+)\s+(.+?)$/) {
                    ($first_name, $last_name) = ($1, $2);
                    $suffix="";
                }
            }

            # Pull out prefixes like Mr, Dr, etc.
            if ($first_name =~
                /^((?:Amb\.|Ambassador|(?:Rear|Vice )?(?:Adm\.|Admiral)|RADM|(?:Maj\. |Major )?Gen\.)\.? )?(.*)$/i) {
                    ($prefix, $first_name) = ($1, $2);
            }
            if ($prefix eq "" & $first_name =~ /^((?:(?:Lieutenant |Major )?General)\.? )?(.*)$/i) {
                ($prefix, $first_name) = ($1, $2);
            }
            if ($prefix eq "" & $first_name =~
                /^((?:Lt Gen|Hon\.|Prof\.|Professor|Rev\.|Rt\. Hon\.?|Sir|Dr|Mr|Mrs|Ms)\.? )?(.*)$/i) {
                    ($prefix, $first_name) = ($1, $2);
            }
            if ($prefix eq "" & $first_name =~ /^(Sen\. |Senator )?(.*)$/i) {
                ($prefix, $first_name) = ($1, $2);
            }
        }

    }

    # Remove last-name prefixes from first names
    if ($first_name =~ /(.+?)((?:\s[a-z]+)+)$/) {
        $first_name = $1;
        $last_name_prefix = $2;
        $last_name_prefix =~ s/^\s+//;
        $last_name = $last_name_prefix . ' ' . $last_name;
    }

    return {first_name => $first_name, middle_initial => $middle_initial,
            last_name => $last_name, suffix => $suffix, prefix => $prefix };
$CODE$ LANGUAGE plperl;

ALTER FUNCTION issvoting.extract_name(text) OWNER TO activism;

SET work_mem='3GB';

DROP TABLE IF EXISTS issvoting.auto_names;

CREATE TABLE issvoting.auto_names AS
SELECT DISTINCT itemdesc, issvoting.extract_name(itemdesc) AS name
FROM issvoting.compvote
WHERE itemdesc ~* '^\s*Elect';

ALTER TABLE issvoting.auto_names OWNER TO activism;

DROP TABLE IF EXISTS issvoting.director_names;

CREATE TABLE issvoting.director_names AS
SELECT itemdesc, prefix, first_name, middle_initial, last_name, suffix
FROM issvoting.manual_names
UNION
SELECT itemdesc, (name).prefix, (name).first_name, (name).middle_initial,
    (name).last_name, (name).suffix
FROM issvoting.auto_names
WHERE trim(itemdesc) NOT IN (SELECT itemdesc FROM issvoting.manual_names);

ALTER TABLE issvoting.director_names OWNER TO activism;

COMMENT ON TABLE issvoting.director_names IS
    'CREATED USING iss_extract_names.sql';

DROP TABLE IF EXISTS issvoting.auto_names;
