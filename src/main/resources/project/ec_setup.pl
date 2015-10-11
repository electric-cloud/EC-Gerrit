#
#  Copyright 2015 Electric Cloud, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#


my %CustomBuildExample = (
    label       => "Gerrit - Custom Build Example",
    procedure   => "CustomBuildExample",
    description => "A sample Custom Build using the helper methods",
    category    => "Code Analysis"
);
my %CustomBuildPrepare = (
    label       => "Gerrit - Custom Build Prepare",
    procedure   => "CustomBuildPrepare",
    description => "Custom build example using the new helper methods",
    category    => "Code Analysis"
);
my %DevBuildCleanup = (
    label       => "Gerrit - Developer Build Cleanup",
    procedure   => "DevBuildCleanup",
    description => "Cleanup after one developer build. The working tree is cleaned up (runtime artifacts removed, change backed out).  This also marks the job as complete in Gerrit comments",
    category    => "Code Analysis"
);
my %DevBuildExample = (
    label       => "Gerrit - Developer Build Example",
    procedure   => "DevBuildExample",
    description => "An example of a developer build procedure",
    category    => "Code Analysis"
);
my %DevBuildPrepare = (
    label       => "Gerrit - Developer Build Prepare",
    procedure   => "DevBuildPrepare",
    description => "Prepare for a developer build. This will be one change. The working tree will be adjusted to be the head of the branch plus changes in the change",
    category    => "Code Analysis"
);
my %TeamBuildCleanup = (
    label       => "Gerrit - Team Build Cleanup",
    procedure   => "TeamBuildCleanup",
    description => "Mark the changes as approved if success",
    category    => "Code Analysis"
);
my %TeamBuildExample = (
    label       => "Gerrit - Team Build Example",
    procedure   => "TeamBuildExample",
    description => "A sample Team Build procedure",
    category    => "Code Analysis"
);
my %TeamBuildPrepare = (
    label       => "Gerrit - Team Build Prepare",
    procedure   => "TeamBuildPrepare",
    description => "Create a tree in /myResource/gerrit_working_dir with the head of the branch and an overlay of all open Gerrit changes which match the configuration filters",
    category    => "Code Analysis"
);
my %DeveloperScan = (
    label       => "Gerrit - Developer Scan",
    procedure   => "DeveloperScan",
    description => "Scan the Gerrit server for any new changes and process them",
    category    => "Code Analysis"
);
my %SetupGerritServer = (
    label       => "Gerrit - Setup Gerrit Server",
    procedure   => "SetupGerritServer",
    description => "[Deprecated] Setup the default settings into Gerrit to be used with the Electric Commander. This procedure is not supported with Gerrit version 2.6 and above.",
    category    => "Code Analysis"
);

$batch->deleteProperty("/server/ec_customEditors/pickerStep/Gerrit - Custom Build Prepare");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/Gerrit - Custom Build Example");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/Gerrit - Developer Build Cleanup");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/Gerrit - Developer Build Example");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/Gerrit - Developer Build Prepare");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/Gerrit - Group Build Example");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/Gerrit - Team Build Cleanup");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/Gerrit - Team Build Example");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/Gerrit - Team Build Prepare");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/Gerrit - Developer Scan");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/Gerrit - Setup Gerrit Server");

@::createStepPickerSteps = (\%CustomBuildExample, \%DevBuildCleanup, \%DeveloperScan, \%CustomBuildPrepare, \%DevBuildExample, \%DevBuildPrepare,
 \%SetupGerritServer, \%TeamBuildCleanup, \%TeamBuildExample, \%TeamBuildPrepare);

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

    # Copy configurations from $otherPluginName
    if ($query->findvalue($oldcfgs, 'code') ne 'NoSuchProperty') {
        $batch->clone(
                      {
                        path      => "/plugins/$otherPluginName/project/gerrit_cfgs",
                        cloneName => "/plugins/$pluginName/project/gerrit_cfgs"
                      }
                     );
    }

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
