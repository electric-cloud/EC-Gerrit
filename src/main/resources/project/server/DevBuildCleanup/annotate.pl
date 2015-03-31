##########################
# annotate.pl
##########################
$[/myProject/procedure_helpers/preamble]

my $jobId = "$[jobId]";
my $xPath = $ec->getProperty("/myJob/outcome");
my $outcome = $xPath->findvalue('//value')->string_value;
my $msg;
my $cat, $value;

# get the actions
my ($filters,$actions) = $gt->parseRules("$opts->{dev_build_rules}");

if ($outcome eq "success") {
      $cat   = $actions->{SUCCESS}{CAT} || "";
      $value = $actions->{SUCCESS}{VAL} || "";
      $msg = "This change was successfully built with ElectricCommander."
        . "https://$opts->{cmdr_webserver}/commander/link/jobDetails/jobs/$jobId";
} else {
      $cat   = $actions->{ERROR}{CAT} || "";
      $value = $actions->{ERROR}{VAL} || "";
      $msg = "This change failed the ElectricCommander build."
        . "https://$opts->{cmdr_webserver}/commander/link/jobDetails/jobs/$jobId";
}

$gt->setECState( "$opts->{project}", "$opts->{changeid}", 
    "$opts->{patchid}","jobComplete",$msg, $cat,$value);

print "Updated gerrit comment to:\n$msg\n";
exit 0;

