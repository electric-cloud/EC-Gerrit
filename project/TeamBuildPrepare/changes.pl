##########################
# changes.pl
##########################
$[/myProject/procedure_helpers/preamble]

# get all eligible change/patch combinations from Gerrit
my @changes;

if ($opts->{group_build_changes} eq "") {
	@changes = $gt->team_build($opts->{team_build_rules},$opts->{teambuild_project_branches});
} else {
    @changes = $gt->custom_build($opts->{team_build_rules},$opts->{group_build_changes});
}


if (scalar @changes == 0) {
    print "No changes meet the filter criteria.\n";
    exit 0;
}



# save changes so that code extraction, build, and comments
# all operate on this list regardeless of other changes
# that appear in mid flight
my $json = JSON->new->utf8;
my $change_str = $json->encode(\@changes);

print "===CHANGES===\n";
print $change_str . "\n";

$gt->getCmdr()->setProperty("/myJob/gerrit_changes", $change_str);


