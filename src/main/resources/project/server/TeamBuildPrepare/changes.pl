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
# changes.pl
##########################
$[/myProject/procedure_helpers/preamble]

# get all eligible change/patch combinations from Gerrit
my @changes;

if ($opts->{group_build_changes} eq "") {
	@changes = $gt->team_build($opts->{team_build_rules},$opts->{teambuild_project_branches});
} else {
    @changes = $gt->custom_build($opts->{team_build_rules},$opts->{group_build_changes});
}


if (scalar @changes == 0) {
    print "No changes meet the filter criteria.\n";
    exit 0;
}



# save changes so that code extraction, build, and comments
# all operate on this list regardeless of other changes
# that appear in mid flight
my $json = JSON->new->utf8;
my $change_str = $json->encode(\@changes);

print "===CHANGES===\n";
print $change_str . "\n";

$gt->getCmdr()->setProperty("/myJob/gerrit_changes", $change_str);


