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
            print "Skipping scan for configuration [$cfgName]. It does not contain the Gerrit server name.\n";
            next;
    }

    # only process if scan enabled
    if ($opts->{devbuild_mode} eq "off") {
        print "Skipping scan for configuration [$cfgName]. 'Developer Build Mode' is 'OFF' for the configuration.\n";
        next;
    }

    ## add other parms and values to opts
    $opts->{gerrit_cfg} = "$cfgName";

    my $gt = new ECGerrit( $ec, 
        "$opts->{gerrit_user}", 
        "$opts->{gerrit_server}", 
        "$opts->{gerrit_port}", 
        "$opts->{gerrit_public_key}", 
        "$opts->{gerrit_private_key}", 
        $opts->{debug});

    $opts->{'use_file_manifest'} = 1;
	$opts->{'changes_manifest_file'} = $opts->{"teambuild_project_branches"};
	
	$gt->debugMsg(4, "calling: processNewChanges");
    #  process new gerrit changes
    $gt->processNewChanges($opts);

    #  process commander jobs
    $gt->processFinishedJobs($opts);

    #  cleanup old jobs
    $gt->cleanup($opts);

    print "Completed scan for configuration [$cfgName].\n";
}

print "Scan completed for all configurations.\n";