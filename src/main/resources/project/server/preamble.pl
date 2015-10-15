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

use ElectricCommander;
use File::Basename;
use ElectricCommander::PropDB;
use ElectricCommander::PropMod;

$|=1;

my $ec = new ElectricCommander();
$ec->abortOnError(0);

my $cfgName = "$[gerrit_cfg]";
my $proj = "$[/myProject/projectName]";
my $cfg = new ElectricCommander::PropDB($ec,"/projects/$proj/gerrit_cfgs");
my %vals = $cfg->getRow($cfgName);
my $opts = \%vals;

# get pseudo code snippets
my $code = new ElectricCommander::PropDB($ec,"/projects/$proj/");
my %code_vals = $code->getRow("pseudo_code");

foreach my $snippet (keys %code_vals) {  
    $opts->{$snippet} = "$code_vals{$snippet}";
}

if (!defined $opts->{gerrit_server} || $opts->{gerrit_server} eq "") {
        print "configuration [$cfgName] does not contain a gerrit server name\n";
            exit 1;
}

## add other parms and values to opts
$opts->{gerrit_cfg} = "$cfgName";
$opts->{gerrit_working_dir} = "$[/myResource/gerrit_working_dir]";
$opts->{changeid} = ($ec->getProperty("changeid") )->findvalue("//value");
$opts->{patchid} =  ($ec->getProperty("patchid") )->findvalue("//value");
$opts->{project} =  ($ec->getProperty("project") )->findvalue("//value");
$opts->{group_build_changes} = ($ec->getProperty("group_build_changes") )->findvalue("//value");

if (!ElectricCommander::PropMod::loadPerlCodeFromProperty(
    $ec,"/myProject/scm_driver/ECGerrit") ) {
    print "Could not load ECGerrit.pm\n";
}

my $gt = new ECGerrit( $ec, 
    "$opts->{gerrit_user}", 
    "$opts->{gerrit_server}", 
    "$opts->{gerrit_port}", 
    "$opts->{gerrit_public_key}", 
    "$opts->{gerrit_private_key}", 
    $opts->{debug});

