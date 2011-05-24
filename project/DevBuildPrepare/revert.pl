##########################
# revert.pl
##########################
$[/myProject/procedure_helpers/preamble]

my $map = $gt->makeReplacementMap($opts);

my $magicDir  = $gt->replace_strings("$opts->{cmd_magic_dir}",$map);
my $magicDir  = $gt->replace_strings("$magicDir",$map);

my $revertCmd = $gt->replace_strings("$opts->{cmd_revert}",$map);
my $revertCmd = $gt->replace_strings("$revertCmd",$map);

if (!-d "$opts->{gerrit_working_dir}/$magicDir") {
    print "$opts->{gerrit_working_dir} not a git repostitory.\n";
    exit 1;
}

chdir $opts->{gerrit_working_dir};
print "Revert repository to latest head.\n";
eval "$revertCmd" ;

