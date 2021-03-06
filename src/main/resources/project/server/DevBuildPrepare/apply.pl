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
# apply.pl
##########################
$[/myProject/procedure_helpers/preamble]

my $map = $gt->makeReplacementMap($opts);

# get values from configuration
# run through replacement twice to allow double indirection
#     i.e.   a->b->c

my $overlayCmd = $gt->replace_strings("$opts->{cmd_overlay}",$map);
my $overlayCmd = $gt->replace_strings("$overlayCmd",$map);

my $magicDir  = $gt->replace_strings("$opts->{cmd_magic_dir}",$map);
my $magicDir  = $gt->replace_strings("$magicDir",$map);

if (!-d "$opts->{gerrit_working_dir}/$magicDir") {
    print "$opts->{gerrit_working_dir} missing directory $magicDir.\n";
    exit 1;
}

chdir $opts->{gerrit_working_dir};

print "Get updates\n";
# create pull command
eval "$overlayCmd" or die "Error encountered: $@";

  


