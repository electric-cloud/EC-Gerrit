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

# mark job as done
$gt->getCmdr()->setProperty("/jobs/$jobId/processed_by_gerrit","done");
$gt->setECState( "$opts->{project}", "$opts->{changeid}", 
    "$opts->{patchid}","jobComplete",$msg, $cat,$value);

print "Updated gerrit comment to:\n$msg\n";
exit 0;

