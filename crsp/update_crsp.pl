#!/usr/bin/env perl
chdir('..') or die "$!";

# Update monthly data
$msf = system("./wrds_to_pg_v2 crsp.msf --fix-missing");
$msi = system("./wrds_to_pg_v2 crsp.msi");
$msedelist = system("./wrds_to_pg_v2 crsp.msedelist --fix-missing");

$mport = system("./wrds_to_pg_v2 crsp.mport1");
# See http://perldoc.perl.org/functions/system.html

$mport = $mport >> 8;
if ($mport) {
    print "Getting ermport1\n";
    system("crsp/get_ermport.pl");
    system("psql -f crsp/crsp_make_ermport1.sql");
}

$msf = $msf >> 8;
$msi = $msi >> 8;
$msedelist = $msedelist >> 8;

if ($mport | $msf | $msi | $msedelist) {
    system("psql -f crsp/crsp_make_mrets.sql")
}

# Update daily data
$dsf = system("./wrds_to_pg_v2 crsp.dsf --fix-missing");
$dsi = system("./wrds_to_pg_v2 crsp.dsi");
$dsedelist = system("./wrds_to_pg_v2 crsp.dsedelist --fix-missing");

$dport = system("./wrds_to_pg_v2 crsp.dport1");

# See http://perldoc.perl.org/functions/system.html
$dport = $dport >> 8;
$dsf = $dsf >> 8;
$dsi = $dsi >> 8;
$dsedelist = $dsedelist >> 8;

if ($dport) {
    print "Getting erdport1\n";
    system("crsp/get_erdport.pl");
    system("psql -f crsp/crsp_make_erdport1.sql");
}

if ($dport | $dsf | $dsi | $dsedelist) {
    system("psql -f crsp/crsp_make_rets_alt.sql")
}

# Update other data sets
system("
    ./wrds_to_pg_v2 crsp.dseexchdates;
    ./wrds_to_pg_v2 crsp.msp500list;
    ./wrds_to_pg_v2 crsp.stocknames;
    ./wrds_to_pg_v2 crsp.ccmxpf_linktable --fix-missing;
    ./wrds_to_pg_v2 crsp.ccmxpf_lnkhist --fix-missing;
    ./wrds_to_pg_v2 crsp.ccmxpf_lnkused --fix-missing;
    ./wrds_to_pg_v2 crsp.dsedist --fix-missing;
    ./wrds_to_pg_v2 crsp.fund_names --fix-missing;")

