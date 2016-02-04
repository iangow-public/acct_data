-- Function: boardex.parse_name(text)

-- DROP FUNCTION boardex.parse_name(text);

CREATE OR REPLACE FUNCTION boardex.parse_name(text)
  RETURNS parsed_names AS
$BODY$
    # Reset variables
    my ($prefix, $names, $suffixes, $first_names, $last_names);
    my ($last_name, $first_name, $middle_initial, $first_name_alt);

    if (defined($_[0])) {
        #$row[0] =~ s/'/''/g;        # Escape single-quotes (for SQL)
        $temp = $_[0];
        $temp =~ s/Professor, Dr/Professor Dr/;
        $temp    =~ s/\*//g;        # Remove asterisks
        $temp =~ s/\s{2,}/ /g;      # Remove any multiple spaces
        $temp =~ s/The Duke Of/Duke/i;
        $temp =~ s/(The )?(Right |Rt\. )?Hon(ou?rable|\.) /Rt. Hon. /i;

        print "$temp\n";

        $name = $temp; # Text identified as name

        if ($name =~ "," & $name =~ /^\s?(.*?)\s+([\w']*?)\s?,\s?(.*)\s?$/) {
            # If there's a comma, put the part after the first comma into a suffix
            ($first_name, $last_name, $suffixes) = ($1, $2, $3);
        } elsif ($name =~ /^(.*)\s+(.*?)\s+(JR\s?\.?|SR\s?\.?|PH\.?D\.?|II|III|IV|V|VI|M\.?D\.?|\(RET(\.|ired)?\)|3D|CBE)$/i) {
            ($first_name, $last_name, $suffixes) = ($1, $2, $3);
            # Some suffixes are not always separated by a comma, but we can be confident that
            # they're suffixes. Pull these out too.
        } else {
            $name =~ s/\s+$//;
            # If there's no suffix...
            if ($name =~ /^(.*)\s+(.*?)$/) {
                ($first_name, $last_name) = ($1, $2);
                $suffixes="";
            }
        }

        $prefixes = '(?:';
        $prefixes .= 'Amb\.|Ambassador|(?:Rear|Vice )?(?:Adm\.|Admiral)|RADM';
        $prefixes .= '|(?:(?:Lieutenant |Maj\. |Major )?(?:Gen\.|General))';
        $prefixes .= '|Governor|Chancellor';
        $prefixes .= '|(?:Lt Gen|Hon\.|Professor\s+Dr|Prof\.|Professor|Doctor|Rev\.|Rt\. Hon|Sir|Dr|Mr|Mrs|Ms)\.?';
        $prefixes .= '|Sen\.|Senator';
        $prefixes .= '|Lord';
        $prefixes .= '|Air (?:(?:Chief |Vice )?Marshal|Commodore)';
        $prefixes .= '|Sir';
        $prefixes .= '|Shri |Tan Sri Dato |The Hon\. |The Rt\. Hon |Lt\. Gen\. |Major |Madam |General Sir';
        $prefixes .= ')';

        # Pull out prefixes like Mr, Dr, etc.
        if ($first_name =~ /^($prefixes?)(.*)$/i) {
            ($prefix, $first_name) = ($1, $2);
            $first_name =~ s/^\s+//g;
        }

        if ($first_name =~ /^($prefixes?)(.*)$/i) {
            ($prefix, $first_name) = ($prefix . ' '. $1, $2);
            $first_name =~ s/^\s+//g;
        }

        $prefix =~ s/^\s+//g;

        if ($first_name =~ /\((.+)\)/) {
            $first_name_alt = $1;
            $first_name =~ s/ \(.*\)//;
        }

        if ($first_name =~ /(\w{2,})\s+(\w{1})\b/) {
            ($first_name, $middle_initial) = ($1, $2);
        }

    }
    return {first_names => [$first_name, $first_name_alt],
            middle_initial => $middle_initial,
            last_name => $last_name, suffix => $suffixes, prefix => $prefix };

$BODY$
  LANGUAGE plperl VOLATILE
  COST 100;
