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

$ec->setProperty("/myJob/git_resource",$opts->{ResourcePool});
exit 0;
