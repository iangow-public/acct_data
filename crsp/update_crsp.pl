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

if ($msi) {
    system("psql -c 'CREATE INDEX ON crsp.msi (date)'");
}

if ($mport | $msf | $msi | $msedelist) {
    system("psql -f crsp/crsp_make_mrets.sql")
}

if ($msf) {
    system("psql -c 'CREATE INDEX ON crsp.msf (permno, date);'");
}

# Update daily data
$dsf = system("./wrds_to_pg_v2 crsp.dsf --fix-missing");
# See http://perldoc.perl.org/functions/system.html
$dsf = $dsf >> 8;

if ($dsf) {
    system("psql -c 'SET maintenance_work_mem=\"10GB\"; CREATE INDEX ON crsp.dsf (permno, date)'");
}

$dsi = system("./wrds_to_pg_v2 crsp.dsi");
$dsi = $dsi >> 8;

if ($dsi) {
    # system("psql -f crsp/crsp_indexes.sql");
    system("psql -c 'CREATE INDEX ON crsp.dsi (date)'");
    system("psql -f crsp/make_trading_dates.sql");
}

$dsedelist = system("./wrds_to_pg_v2 crsp.dsedelist --fix-missing");
$dsedelist = $dsedelist >> 8;

if ($dsedelist) {
    system("psql -c 'CREATE INDEX ON crsp.dsedelist (permno)'");
}

$dport = system("./wrds_to_pg_v2 crsp.dport1");
$dport = $dport >> 8;

if ($dport) {
    system("psql -f crsp/fix_d_permnos.sql");
    print "Getting erdport1\n";
    system("crsp/get_erdport.pl");
    system("psql -f crsp/crsp_make_erdport1.sql");
    system("psql -c 'CREATE INDEX ON crsp.dport1 (permno, date)'");
}

if ($dport | $dsf | $dsi | $dsedelist) {
    system("psql -f crsp/crsp_make_rets_alt.sql");
    system("psql -f crsp/crsp_make_rets_alt_2.sql");
}

$ccmxpf_linktable = system("./wrds_to_pg_v2 crsp.ccmxpf_linktable --fix-missing");
$ccmxpf_linktable = $ccmxpf_linktable >> 8;

if ($ccmxpf_linktable) {
    system("psql -c 'CREATE INDEX ON crsp.ccmxpf_linktable (lpermno)'");
    system("psql -c 'CREATE INDEX ON crsp.ccmxpf_linktable (gvkey)'");
}

$ccmxpf_lnkhist = system("./wrds_to_pg_v2 crsp.ccmxpf_lnkhist --fix-missing");
$ccmxpf_lnkhist = $ccmxpf_lnkhist >> 8;

if ($ccmxpf_lnkhist) {
    system("psql -c 'CREATE INDEX ON crsp.ccmxpf_lnkhist (gvkey)'");
}

$dsedist = system("./wrds_to_pg_v2 crsp.dsedist --fix-missing");
$dsedist = $dsedist >> 8;

if ($dsedist) {
    system("psql -c 'CREATE INDEX ON crsp.dsedist (permno)'");
}

$stocknames = system("./wrds_to_pg_v2 crsp.stocknames");
$stocknames = $stocknames >> 8;

if ($stocknames) {
    system("psql -c 'ALTER TABLE crsp.stocknames ALTER permno TYPE bigint'");
    system("psql -c 'ALTER TABLE crsp.stocknames ALTER permco TYPE bigint'");
    system("psql -f crsp/crsp_fix_permnos.sql;");
}

$dseexchdates = system("./wrds_to_pg_v2 crsp.stocknames");
$dseexchdates = $dseexchdates >> 8;
if ($dseexchdates) {
    system("psql -c 'CREATE INDEX ON crsp.dseexchdates (permno)'");
}

# Update other data sets
system("./wrds_to_pg_v2 crsp.msp500list;");
system("./wrds_to_pg_v2 crsp.ccmxpf_lnkused --fix-missing;");
system("./wrds_to_pg_v2 crsp.fund_names --fix-missing;");
system("psql -f pg/permissions.sql");

$any_updated = $dsf | $dseexchdates | $stocknames | $dsedist
                    | $ccmxpf_lnkhist | $ccmxpf_linktable | $dsedist
                    | $msf | $msi | $msedelist 
                    | $dsedelist | $dsi | $dport;
$any_updated = 1;
$cmd = "pg_dump --format custom --no-tablespaces --file ";
$cmd .= "~/Dropbox/pg_backup/crsp.backup --schema 'crsp'";
if ($any_updated) {
    system($cmd);
}
