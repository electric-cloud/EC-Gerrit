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

my $msg = "This change is being built with ElectricCommander."
  . "https://$opts->{cmdr_webserver}/commander/link/jobDetails/jobs/$[jobId]";

my @changes = $gt->getChanges();

$gt->team_annotate(\@changes,$msg);

print "Updating gerrit comment to:\n$msg\n";

exit 0;

