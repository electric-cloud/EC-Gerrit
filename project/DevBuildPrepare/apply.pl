##########################
# apply.pl
##########################
$[/myProject/procedure_helpers/preamble]

my $map = $gt->makeReplacementMap($opts);

# get values from configuration
# run through replacement twice to allow double indirection
#     i.e.   a->b->c

my $overlayCmd = $gt->replace_strings("$opts->{cmd_overlay}",$map);
my $overlayCmd = $gt->replace_strings("$overlayCmd",$map);

my $magicDir  = $gt->replace_strings("$opts->{cmd_magic_dir}",$map);
my $magicDir  = $gt->replace_strings("$magicDir",$map);

if (!-d "$opts->{gerrit_working_dir}/$magicDir") {
    print "$opts->{gerrit_working_dir} missing directory $magicDir.\n";
    exit 1;
}

chdir $opts->{gerrit_working_dir};

print "Get updates\n";
# create pull command
eval "$overlayCmd";

  


