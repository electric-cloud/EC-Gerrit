##########################
# approve.pl
##########################

$[/myProject/procedure_helpers/preamble]


my $jobId = "$[jobId]";
my $xPath = $ec->getProperty("/myJob/outcome");
my $outcome = $xPath->findvalue('//value')->string_value;
my $msg;

my $project = "$[project]";
my $branch  = "$opts->{gerrit_branch}";
my $rules   = "$opts->{team_build_rules}";

my @changes= $gt->getChanges();

if (!@changes) {
	if ($opts->{group_build_changes} eq "") {
		@changes = $gt->team_build($opts->{team_build_rules},$opts->{teambuild_project_branches});
	} else {
		@changes = $gt->custom_build($opts->{team_build_rules},$opts->{group_build_changes});
	}
}   

my $msg;
if ($outcome eq "success") {

      $msg="ElectricCommander team build succeeded."
        . " https://$opts->{cmdr_webserver}/commander/link/jobDetails/jobs/$jobId";
    $gt->team_approve(\@changes, $rules,$msg);
} else {

      $msg="ElectricCommander team build outcome=$outcome."
        . " https://$opts->{cmdr_webserver}/commander/link/jobDetails/jobs/$jobId";
    $gt->team_disapprove(\@changes, $rules,$msg);
}   
print "Updating gerrit comment to:\n$msg\n";
exit 0;

