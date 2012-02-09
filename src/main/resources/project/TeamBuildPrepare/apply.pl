##########################
# apply.pl
##########################
$[/myProject/procedure_helpers/preamble]

my $map = $gt->makeReplacementMap($opts);

# get values from configuration
# run through replacement twice to allow double indirection
#     i.e.   a->b->c

my $magicDir  = $gt->replace_strings("$opts->{cmd_magic_dir}",$map);
my $magicDir  = $gt->replace_strings("$magicDir",$map);

if (!-d "$opts->{gerrit_working_dir}/$magicDir") {
    print "$opts->{gerrit_working_dir} missing directory $magicDir.\n";
    exit 1;
}

my $rawOverlayCmd = "$opts->{cmd_overlay}";

chdir $opts->{gerrit_working_dir};

my @changes = $gt->getChanges();

foreach my $str (@changes) {
    my ($changeid, $patchid,$project) = split (/:/,$str);
    $opts->{changeid} = $changeid;
    $opts->{patchid} = $patchid;
    $opts->{gerrit_project} = $project;
    my $newmap = $gt->makeReplacementMap($opts);
    my $overlayCmd = $gt->replace_strings("$rawOverlayCmd",$newmap);
    my $overlayCmd = $gt->replace_strings("$overlayCmd",$newmap);
    print "overlay cmd\n$overlayCmd\n";

    print "Get updates\n";
    # create pull command
    eval "$overlayCmd";
}





