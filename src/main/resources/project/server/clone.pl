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
# clone.pl
##########################
$[/myProject/procedure_helpers/preamble]

my $map = $gt->makeReplacementMap($opts);

# get values from configuration
# run through replacement twice to allow double indirection
#     i.e.   a->b->c
my $cloneCmd  = $gt->replace_strings("$opts->{cmd_clone}",$map);
my $cloneCmd  = $gt->replace_strings("$cloneCmd",$map);
my $updateCmd = $gt->replace_strings("$opts->{cmd_update}",$map);
my $updateCmd = $gt->replace_strings("$updateCmd",$map);
my $magicDir  = $gt->replace_strings("$opts->{cmd_magic_dir}",$map);
my $magicDir  = $gt->replace_strings("$magicDir",$map);


### If working directory is blank
if ("$opts->{gerrit_working_dir}" eq "") {
    print "Error: Working directory not specified.  Set the directory in a property"
        . " named gerrit_working_dir on the resource.\n";
    exit 1;
}

### Examine working directory and see if it needs to be created from scratch
if (! -d $opts->{gerrit_working_dir}) {
    print "Creating a clone of remote repository\n";
    eval "$cloneCmd" or die "Error encountered: $@";
}

### Do we have an initialized dir?
if (!-d "$opts->{gerrit_working_dir}/$magicDir") {
    print "Error: $opts->{gerrit_working_dir} missing directory $magicDir.\n";
    exit 1;
}

### Sync to head
print "Updating the repository to latest head.\n";
eval "$updateCmd" or die "Error encountered: $@";
