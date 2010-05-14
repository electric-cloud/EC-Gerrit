##########################
# annotate.pl
##########################
$[/myProject/procedure_helpers/preamble]

my $msg = "This change is being built with ElectricCommander."
           . "https://$opts->{cmdr_webserver}/commander/link/jobDetails/jobs/$[jobId]";

$gt->setECState("$opts->{changeid}", "$opts->{patchid}","jobRunning",$msg);
print "Updating gerrit comment to:\n$msg\n";
exit 0;

