##########################
# annotate.pl
##########################
$[/myProject/procedure_helpers/preamble]

my $jobId = "$[jobId]";
my $xPath = $ec->getProperty("/myJob/outcome");
my $outcome = $xPath->findvalue('//value')->string_value;
my $msg;
if ($outcome eq "success") {
      $msg = "This change was successfully built with ElectricCommander."
        . "https://$opts->{cmdr_webserver}/commander/link/jobDetails/jobs/$jobId";
} else {
      $msg = "This change failed the ElectricCommander build."
        . "https://$opts->{cmdr_webserver}/commander/link/jobDetails/jobs/$jobId";
}

$gt->setECState( "$opts->{changeid}", "$opts->{patchid}","jobComplete",$msg);

print "Updating gerrit comment to:\n$msg\n";
exit 0;

