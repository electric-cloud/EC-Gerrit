if ($promoteAction eq 'promote') {

} elsif ($promoteAction eq 'demote') {

}

if ($upgradeAction eq 'upgrade') {
    my $query = $commander->newBatch();
    my $newcfg = $query->getProperty(
        "/plugins/$pluginName/project/gerrit_cfgs");
    my $oldcfgs = $query->getProperty(
        "/plugins/$otherPluginName/project/gerrit_cfgs");
    $query->getProperties( { projectName => "$otherPluginName", path => "pseudo_code"});
    $query->getSchedule( "$otherPluginName", "Gerrit New Change Scanner");

    local $self->{abortOnError} = 0;
    my $xpath = $query->submit();

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

    # move over specific pseudo_code customizations
    # make a copy of the new code for reference
    $batch->clone({
        path => "/plugins/$pluginName/project/pseudo_code",
        cloneName => "/plugins/$pluginName/project/pseudo_code_$pluginName"
    });

    # now move over the old settings
    $batch->setProperty(
        "/plugins/$pluginName/project/pseudo_code/cmd_clone",
        $xpath->findvalue('//propertySheet/property[propertyName="cmd_clone"]/value')->string_value);
    $batch->setProperty(
        "/plugins/$pluginName/project/pseudo_code/cmd_overlay",
        $xpath->findvalue('//propertySheet/property[propertyName="cmd_overlay"]/value')->string_value);
    $batch->setProperty(
        "/plugins/$pluginName/project/pseudo_code/cmd_magic_dir",
        $xpath->findvalue('//propertySheet/property[propertyName="cmd_magic_dir"]/value')->string_value);
    $batch->setProperty(
        "/plugins/$pluginName/project/pseudo_code/cmd_revert",
        $xpath->findvalue('//propertySheet/property[propertyName="cmd_revert"]/value')->string_value);
    $batch->setProperty(
        "/plugins/$pluginName/project/pseudo_code/cmd_update",
        $xpath->findvalue('//propertySheet/property[propertyName="cmd_update"]/value')->string_value);
    $batch->setProperty(
        "/plugins/$pluginName/project/pseudo_code/repo_cmd",
        $xpath->findvalue('//propertySheet/property[propertyName="repo_cmd"]/value')->string_value);

    # preserve schedule customizations

    # schedule details
    #<response requestId="1">
    #<schedule>
    #  <scheduleId>27</scheduleId>
    #  <scheduleName>Gerrit New Change Scanner</scheduleName>
    #  <beginDate />
    #  <createTime>2010-05-17T22:09:59.395Z</createTime>
    #  <description>Scan the gerrit server for changes</description>
    #  <endDate />
    #  <interval>15</interval>
    #  <intervalUnits>minutes</intervalUnits>
    #  <lastModifiedBy>project: EC-Gerrit-1.0.0.0</lastModifiedBy>
    #  <lastRunTime>2010-05-17T22:30:00.046Z</lastRunTime>
    #  <misfirePolicy>ignore</misfirePolicy>
    #  <modifyTime>2010-05-17T22:30:00.047Z</modifyTime>
    #  <monthDays />
    #  <owner>admin</owner>
    #  <priority>normal</priority>
    #  <procedureName>DeveloperScan</procedureName>
    #  <scheduleDisabled>0</scheduleDisabled>
    #  <startTime />
    #  <stopTime />
    #  <timeZone>America/Los_Angeles</timeZone>
    #  <weekDays />
    #  <projectName>EC-Gerrit-1.0.0.0</projectName>
    #  <propertySheetId>21681</propertySheetId>
    #</schedule>
    #</response>

    my $sched = "Gerrit New Change Scanner";
    $batch->modifySchedule( "$pluginName", "$sched",
        {
            beginDate             => $xpath->findvalue(
                "//schedule[scheduleName=\"$sched\"]/beginDate")->string_value,
            endDate               => $xpath->findvalue(
                "//schedule[scheduleName=\"$sched\"]/endDate")->string_value,
            interval              => $xpath->findvalue(
                "//schedule[scheduleName=\"$sched\"]/interval")->string_value,
            intervalUnits         => $xpath->findvalue(
                "//schedule[scheduleName=\"$sched\"]/intervalUnits")->string_value,
            misfirePolicy         => $xpath->findvalue(
                "//schedule[scheduleName=\"$sched\"]/misfirePolicy")->string_value,
            monthDays             => $xpath->findvalue(
                "//schedule[scheduleName=\"$sched\"]/monthDays")->string_value,
            weekDays              => $xpath->findvalue(
                "//schedule[scheduleName=\"$sched\"]/weekDays")->string_value,
            priority              => $xpath->findvalue(
                "//schedule[scheduleName=\"$sched\"]/priority")->string_value,
            scheduleDisabled      => $xpath->findvalue(
                "//schedule[scheduleName=\"$sched\"]/scheduleDisabled")->string_value,
            startTime             => $xpath->findvalue(
                "//schedule[scheduleName=\"$sched\"]/startTime")->string_value,
            stopTime              => $xpath->findvalue(
                "//schedule[scheduleName=\"$sched\"]/stopTime")->string_value,
            timeZone              => $xpath->findvalue(
                "//schedule[scheduleName=\"$sched\"]/timeZone")->string_value,
        });
}
