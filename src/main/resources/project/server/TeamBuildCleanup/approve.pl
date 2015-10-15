#
#  Copyright 2015 Electric Cloud, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

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
print "Updated gerrit comment to:\n$msg\n";
exit 0;

