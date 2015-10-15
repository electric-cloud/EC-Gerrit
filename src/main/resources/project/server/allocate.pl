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
# allocate.pl
##########################
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

if ("$opts->{ResourcePool}" eq "") {
    print "Error: no resource pool specified.\n";
    exit 1;
}
$ENV{'PATH'} = '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/root/bin';
$ec->setProperty("/myJob/git_resource",$opts->{ResourcePool});
