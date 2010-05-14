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
my $code = new ElectricCommander::PropDB($ec,"/projects/$proj/gerrit_code");
my %code_vals = $code->getRow($cfgName);
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
$opts->{changeid} = $cfg->getProp("/myJob/changeid");
$opts->{patchid} =  $cfg->getProp("/myJob/patchid");
$opts->{project} =  $cfg->getProp("/myJob/project");

if (!ElectricCommander::PropMod::loadPerlCodeFromProperty(
    $ec,"/myProject/scm_driver/ECGerrit") ) {
    print "Could not load ECGerrit.pm\n";
}

my $gt = new ECGerrit( $ec, "$opts->{gerrit_server}", $opts->{debug});

