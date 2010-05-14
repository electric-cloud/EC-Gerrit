if ($promoteAction eq 'promote') {

} elsif ($promoteAction eq 'demote') {

}

if ($upgradeAction eq 'upgrade') {
    my $query = $commander->newBatch();
    my $newcfg = $query->getProperty(
        "/plugins/$pluginName/project/gerrit_cfgs");
    my $oldcfgs = $query->getProperty(
        "/plugins/$otherPluginName/project/gerrit_cfgs");

    local $self->{abortOnError} = 0;
    $query->submit();

    # if new plugin does not already have cfgs
    if ($query->findvalue($newcfg,'code') eq 'NoSuchProperty') {
        # if old cfg has some cfgs to copy
        if ($query->findvalue($oldcfgs,'code') ne 'NoSuchProperty') {
            $batch->clone({
                path => "/plugins/$otherPluginName/project/gerrit_cfgs",
                cloneName => "/plugins/$pluginName/project/gerrit_cfgs"
            });
        }
    }
}
