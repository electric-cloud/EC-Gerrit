##########################
# clone.pl
##########################
$[/myProject/procedure_helpers/preamble]

my $map = $gt->makeReplacementMap($opts);

# get values from configuration
# run through replacement twice to allow double indirection
#     i.e.   a->b->c
my $cloneCmd  = $gt->replace_strings("$opts->{cmd_clone}",$map);
my $cloneCmd  = $gt->replace_strings("$cloneCmd",$map);
my $updateCmd = $gt->replace_strings("$opts->{cmd_update}",$map);
my $updateCmd = $gt->replace_strings("$updateCmd",$map);
my $magicDir  = $gt->replace_strings("$opts->{cmd_magic_dir}",$map);
my $magicDir  = $gt->replace_strings("$magicDir",$map);


### If working directory is blank
if ("$opts->{gerrit_working_dir}" eq "") {
    print "Working directory not specified.  Set the directory in a property"
        . " named gerrit_working_dir on the resource.\n";
    exit 1;
}

### Examine working directory and see if it needs to be created from scratch
if (! -d $opts->{gerrit_working_dir}) {
    print "Creating a clone of remote repository\n";
    eval "$cloneCmd";
}

### Do we have an initialized dir?
if (!-d "$opts->{gerrit_working_dir}/$magicDir") {
    print "$opts->{gerrit_working_dir} missing directory $magicDir.\n";
    exit 1;
}

### Sync to head
print "Updating the repository to latest head.\n";
eval  "$updateCmd" ;




