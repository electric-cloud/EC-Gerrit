##########################
# annotate.pl
##########################
$[/plugins/EC-Gerrit/project/procedure_helpers/api]

my $jobId = "$[jobId]";
my $xPath = $ec->getProperty("/myJob/outcome");
my $outcome = $xPath->findvalue('//value')->string_value;
my $msg;

my $project = "$[project]";
my $branch  = "$opts->{gerrit_branch}";
my $rules   = "$opts->{team_build_rules}";

$msg = gr_getProperty("custom_review_msg");

if ($msg eq "") {
    my $msg = "This change is being built with ElectricCommander."
    . "https://$opts->{cmdr_webserver}/commander/link/jobDetails/jobs/$[jobId]";
}

my @changes = $gt->getChanges();
my $gt->team_annotate(@changes,$msg);

exit 0;

