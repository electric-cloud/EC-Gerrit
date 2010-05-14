##########################
# annotate.pl
##########################
$[/myProject/procedure_helpers/preamble]

my $jobId = "$[jobId]";
my $xPath = $ec->getProperty("/myJob/outcome");
my $outcome = $xPath->findvalue('//value')->string_value;
my $msg;

my $project = "$[project]";
my $branch  = "$opts->{gerrit_branch}";
my $rules   = "$opts->{team_build_rules}";


if ($outcome ne "success") {
      print "This change failed the ElectricCommander build."
        . "https://$opts->{cmdr_webserver}/commander/link/jobDetails/jobs/$jobId";
    exit 1;
}   

my @changes = $gt->getChanges();
my $gt->team_annotate(@changes,$rules);

exit 0;

