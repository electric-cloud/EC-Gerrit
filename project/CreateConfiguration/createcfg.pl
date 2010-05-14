#########################
## createcfg.pl
#########################
use ElectricCommander;
use ElectricCommander::PropDB;

my $opts;

my $PLUGIN_NAME = "EC-Gerrit";

if (!defined $PLUGIN_NAME) {
    print "PLUGIN_NAME must be defined\n";
    exit 1;
}

## get an EC object
my $ec = new ElectricCommander();
$ec->abortOnError(0);

## load option list from procedure parameters
my $x = $ec->getJobDetails($ENV{COMMANDER_JOBID});
my $nodeset = $x->find('//actualParameter');
foreach my $node ($nodeset->get_nodelist) {
    my $parm = $node->findvalue('actualParameterName');
    my $val = $node->findvalue('value');
    $opts->{$parm}="$val";
}

if (!defined $opts->{config} || "$opts->{config}" eq "" ) {
    print "config parameter must exist and be non-blank\n";
    exit 1;
}

# check to see if a config with this name already exists before we do anything else
my $xpath = $ec->getProperty("/myProject/gerrit_cfgs/$opts->{config}");
my $property = $xpath->findvalue("//response/property/propertyName");

if (defined $property && "$property" ne "") {
    my $errMsg = "A configuration named '$opts->{config}' already exists.";
    $ec->setProperty("/myJob/configError", $errMsg);
    print $errMsg;
    exit 1;
}

my $cfg = new ElectricCommander::PropDB($ec,"/myProject/gerrit_cfgs");

# add all the options as properties
foreach my $key (keys % {$opts}) {
    if ("$key" eq "config" ) { 
        next;
    }
    $cfg->setCol("$opts->{config}","$key","$opts->{$key}");
}
exit 0;
