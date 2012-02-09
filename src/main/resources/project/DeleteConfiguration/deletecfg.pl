##########################
# deletecfg.pl
##########################

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

my $opts;
$opts->{config} = "$[config]";

if (!defined $opts->{config} || "$opts->{config}" eq "" ) {
    print "config parameter must exist and be non-blank\n";
    exit 1;
}

# check to see if a config with this name already exists before we do anything else
my $xpath = $ec->getProperty("/myProject/gerrit_cfgs/$opts->{config}");
my $property = $xpath->findvalue("//response/property/propertyName");

if (!defined $property || "$property" eq "") {
    my $errMsg = "Error: A configuration named '$opts->{config}' does not exist.";
    $ec->setProperty("/myJob/configError", $errMsg);
    print $errMsg;
    exit 1;
}

$ec->deleteProperty("/myProject/gerrit_cfgs/$opts->{config}");
exit 0;
