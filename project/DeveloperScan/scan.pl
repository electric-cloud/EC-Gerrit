##########################
# scan.pl
##########################

use URI::Escape;
use ElectricCommander;
use ElectricCommander::PropDB;
use ElectricCommander::PropMod;

my $ec = new ElectricCommander();
$ec->abortOnError(0);

my $proj = "$[/myProject/projectName]";

my $cfg = new ElectricCommander::PropDB($ec,"");
my %cfgs = $cfg->getSheets("/projects/$proj/gerrit_cfgs");

if (!ElectricCommander::PropMod::loadPerlCodeFromProperty(
    $ec,"/myProject/scm_driver/ECGerrit") ) {
    print "Could not load ECGerrit.pm\n";
    exit 1;
}

# for each configuration
foreach my $cfgName (keys %cfgs) {
    print "====Scanning configuration $cfgName =====\n";

    my $config = new ElectricCommander::PropDB($ec,"/projects/$proj/gerrit_cfgs");
    my %vals = $config->getRow($cfgName);
    my $opts = \%vals;

    if (!defined $opts->{gerrit_server} || $opts->{gerrit_server} eq "") {
            print "configuration [$cfgName] does not contain a gerrit server name\n";
                exit 1;
    }

    # only process if scan enabled
    if ($opts->{devbuild_mode} eq "off") {
        next;
    }

    ## add other parms and values to opts
    $opts->{gerrit_cfg} = "$cfgName";

    my $gt = new ECGerrit( $ec, "$opts->{gerrit_server}", $opts->{debug});

    #  process new gerrit changes
    $gt->processNewChanges($opts);

    #  process commander jobs
    $gt->processFinishedJobs($opts);

    #  cleanup old jobs
    $gt->cleanup($opts);
}

