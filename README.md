# Integrated version

This plugin was tested against Gerrit 2.8.5.

# Compile

To compile the plugin, run `./gradlew`.

# Setup

To use this plugin with Gerrit, configure Gerrit as follows:

1.  Add the repo tool to the PATH environment variable for the resource
    where the plugin will run. If the path cannot be updated for the
    resource, update the plugin property called *pseudo\_code/repo\_cmd*
    to point to the repo tool. This plugin uses the repo tool for
    synchronizing with the Git repositories and downloading changes from
    the repositories.

2.  Grant **Access Database** capability to the Gerrit user configured
    to communicate with the Gerrit server. Since Gerrit 2.6, Gerrit
    administrators no longer have the **Access Database** capability by
    default. This capability is required by the plugin for access to the
    Gerrit database using the **gsql** command.

You perform these procedures in the CloudBees CD/RO UI.

# Creating CloudBees CD/RO resources

Create one or more resources where your builds will run. Group these
resources in one or more pools. When you create the Gerrit plugin
configuration later, you can specify a pool name for the resources to
use.

You can also set a special property called *gerrit\_working\_dir* for
each resource. The value of this property is the directory where you
want to put build sources. This directory can be relative to the current
directory (the standard CloudBees CD/RO workspace created for the build)
or absolute.

When the plugin runs, it checks if the directory exists. If the
directory is found, CloudBees CD/RO assumes there is a repository and
only synchronizes changes. If the directory is not found, the plugin
creates one and does a full initialization and synchronization of the
repository. Because this process can be time consuming, the plugin also
supports using cached directories.

You can setup one or more locations where builds can be run. Directory
contents are not deleted after a build so the plugin only needs to reset
and synchronize to the head of the branch at the start of each build.
Assuming you build the same branch many times, each reset and
synchronization will run much faster than a full initialization and
synchronization. Changes are applied as before.

This example shows how to create resource.

1.  Go to the **Cloud** tab in the CloudBees CD/RO UI.

You can create the resource using the Gerrit tool or edit an existing
one:

1.  Provide the parameters to create the resource.

2.  Add the required *gerrit\_working\_dir* property by clicking
    **Create Property** in the **Custom Resource Properties** section.

3.  Provide the name of the property and the value.

# Scheduling when the Gerrit server is scanned

The plugin scans your Gerrit server for changes every 15 minutes. based
on an CloudBees CD/RO schedule. If you want to change this frequency,
modify the "Gerrit New Change Scanner" schedule in the
**Administration** &gt; **Plugins** &gt; **EC-Gerrit** &gt;
**Schedules** page in CloudBees CD/RO.

# Changing resources in procedures

The resource for some procedures is set to *local* for your convenience.
However, if you need to change the resource, do the following:

1.  Click on the procedure name to view the details.

2.  Click **Edit**.

3.  Change the **Default Resource**.

# Plugin procedures

For all parameter descriptions in this document, required parameters are
shown in <span class=".required">bold italics</span>.

## CustomBuildPrepare

All the other Gerrit methods (procedures) in this plugin are references
for how to use the EC-Gerrit plugin. Custom builds use several helper
methods located in a property called *API*. With these helper methods,
you can access some Gerrit functions and create new ones by querying the
Gerrit database directly, which provides additional flexibility.

The CustomBuildPrepare procedure uses the new helper methods to prepare
an environment to test all the open changes in the Gerrit server and
those that were scanned previously, which can include changes from one
or more projects.

### Input

1.  Go to the CustomBuildPrepare procedure.

2.  Enter the following parameters:

<table>
<colgroup>
<col style="width: 50%" />
<col style="width: 50%" />
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">Parameter</th>
<th style="text-align: left;">Description</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;"><p>Gerrit Config</p></td>
<td style="text-align: left;"><p>The name of the configuration that has
the connection information for Gerrit.</p></td>
</tr>
</tbody>
</table>

### Output

After the job runs, you can view the results on the **Job Details** page
in CloudBees CD/RO. Every job step was completed successfully.

In the **CustomBuildPrepare** step, click the **Log** button to see the
diagnostic information.

-   **allocate:** This step checks that the required parameters in the
    configuration are correct. It has no output if the job is
    successful. If an error occurs, it shows the error details.

-   **changes:** The step gets the list of changes to be processed and
    saves them for the rest of procedure. Because this procedure has no
    project parameter, the plugin searches for changes in all the Gerrit
    projects.

-   **clone:** The step creates a clone of the remote repository.

-   **revert:** The step gets the tree in the clean state before
    overlaying files.

-   **apply:** The step gets the changes from Gerrit and overlays them
    on top of local repository.

## DevBuildCleanup

This procedure cleans up after one developer build. The working tree is
cleaned up (runtime artifacts are removed, and changes are backed out).
This also marks the job as complete in the Gerrit comments.

### Input

1.  Go to the DevBuildCleanup procedure.

2.  Enter the following parameters:

<table>
<colgroup>
<col style="width: 50%" />
<col style="width: 50%" />
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">Parameter</th>
<th style="text-align: left;">Description</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;"><p>Change ID</p></td>
<td style="text-align: left;"><p>The short change ID to build, such as
<em>5</em>.</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p>Gerrit Config</p></td>
<td style="text-align: left;"><p>The name of the configuration that has
the connection information for Gerrit.</p></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><p>Patch ID</p></td>
<td style="text-align: left;"><p>The short patch set ID to build, such
as <em>1</em>.</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p>Project</p></td>
<td style="text-align: left;"><p>The project that contains the change to
build.</p></td>
</tr>
</tbody>
</table>

### Output

After the job runs, you can view the results on the **Job Details** page
in CloudBees CD/RO. In the **DevBuildCleanup** step, click the **Log**
button to see the diagnostic information.

## DevBuildPrepare

Developer builds are used to build a single patch set submitted by a
developer. CloudBees CD/RO scans Gerrit on a regular basis to find new
patch sets to process. What the plugin does depends on the value you set
for the **Developer Build Mode** in your plugin configuration.

The DevBuildPrepare procedure prepares for a developer build. This will
be one change. The working tree is adjusted to be the head of the branch
and updated with the changes.

### Input

1.  Go to the DevBuildPrepare procedure.

2.  Enter the following parameters:

<table>
<colgroup>
<col style="width: 50%" />
<col style="width: 50%" />
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">Parameter</th>
<th style="text-align: left;">Description</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;"><p>Change ID</p></td>
<td style="text-align: left;"><p>The short change ID to be built, such
as <em>5</em>.</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p>Gerrit Config</p></td>
<td style="text-align: left;"><p>The name of the configuration that has
the connection information for Gerrit.</p></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><p>Patch ID</p></td>
<td style="text-align: left;"><p>The short patch set ID to be built,
such as <em>1</em>.</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p>Project</p></td>
<td style="text-align: left;"><p>The project that contains the change to
build.</p></td>
</tr>
</tbody>
</table>

### Output

After the job runs, you can view the results on the Job Details page in
CloudBees CD/RO. In the **DevBuildPrepare** step, click the **Log**
button to see the diagnostic information.

-   **allocate:** This step checks that the required parameters in the
    configuration are correct. It has no output if the job was
    successful, and if an error occurs, the output shows the error
    details.

-   **annotate:** If this job was launched manually, annotate Gerrit so
    it knows about the job.

-   **clone:** The output shows that a clone of the remote repository
    was created.

-   **revert:** The output shows that the tree is put in the clean state
    before the files are overlaid.

-   **apply:** The output shows that changes are retrieved from Gerrit
    and overlaid on top of local repostory.

## DeveloperScan

This procedure scans the Gerrit server for any new changes and processes
them. The Gerrit plugin configuration has a parameter called *Developer
Build Mode* that is related to this procedure.

### Input

1.  Go to the DeveloperScan procedure.

This procedure has no parameters. . Run the DeveloperScan procedure.

### Output

After the job runs, you can view the results on the Job Details page in
CloudBees CD/RO. In the **DeveloperScan** step, click the **Log** button
to see the diagnostic information.

## SetupGerritServer

\[Deprecated\] The SetupGerritServer procedure sets the default settings
into Gerrit used with the CloudBees CD/RO. This is the default method in
Gerrit 2.6 and earlier. It sets the Commander user in Gerrit and also
the approval bits needed for the integration. If you want to include
different categories of approval bits, go to the [Gerrit Home
Page](http://code.google.com/p/gerrit/) for more information. Follow the
steps [here](#gerrit-setup) to set up Gerrit to be used with CloudBees
CD/RO.

### Input

1.  Go to the SetupGerritServer procedure.

2.  Enter the following parameters:

<table>
<colgroup>
<col style="width: 50%" />
<col style="width: 50%" />
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">Parameter</th>
<th style="text-align: left;">Description</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;"><p>Gerrit Config</p></td>
<td style="text-align: left;"><p>The name of the configuration that has
the connection information for Gerrit.</p></td>
</tr>
</tbody>
</table>

### Output

After the job runs, you can view the results on the **Job Details** page
in CloudBees CD/RO. In the **SetupGerritServer** step, click the **Log**
button to see the diagnostic information.

## TeamBuildCleanup

Team builds are designed for the build and release team. These builds
combine changes of one or more patch sets to test how multiple changes
will work together. The plugin finds patch sets based on rules provided
in the *Team Build Rules* property in the plugin configuration. The
plugin does not run team builds automatically. You must run team build
procedures from CloudBees CD/RO.

The TeamBuildCleanup procedure marks the changes as approved if the job
is successful. It also reverts any uncommitted changes from the working
directory.

### Input

1.  Go to the TeamBuildCleanup procedure.

2.  Enter the following parameters:

<table>
<colgroup>
<col style="width: 50%" />
<col style="width: 50%" />
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">Parameter</th>
<th style="text-align: left;">Description</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;"><p>Gerrit Config</p></td>
<td style="text-align: left;"><p>Name of the configuration that has the
connection information for Gerrit.</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p>Group Build Changes</p></td>
<td style="text-align: left;"><p>List of the changes in the group. Any
number of lines can be added. Enter the information in one of these
ways:</p>
<ul>
<li><p><strong>Use the change ID:</strong> Every change has two
different IDs. The first is a short number and the second is a SHA1
number. You can either of these IDs: <em>2</em> or
<em>Ib34fbd69fe52c43588d39f3804341c219d087ecf</em>.</p></li>
<li><p><strong>Use the project name and the branch name:</strong> Enter
the project name and the branch separated by a colon (:). An example is
<em>ectest:master</em>.</p></li>
<li><p><strong>Use the change ID, the project name, and the the branch
name:</strong> Enter the change ID, project name, and the branch name
separated by a colon (:). Examples are <em>2:ectest:master</em> or
<em>Ib34fbd69fe52c43588d39f3804341c219d087ecf:ectest:master</em>.</p></li>
</ul></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><p>Project</p></td>
<td style="text-align: left;"><p>The project that contains the change to
build.</p></td>
</tr>
</tbody>
</table>

### Output

After the job runs, you can view the results on the **Job Details** page
in CloudBees CD/RO. In the **TeamBuildCleanup** step, click the **Log**
button to see the diagnostic information. The output is similar to the
following diagnostic report:

-   **allocate:** This step checks that the required parameters in the
    configuration are correct. It has no output if the job is
    successful. If an error occurs, it shows the error details.

-   **approve:** The step gets the changes from Gerrit and overlays them
    on top of local repostiory.

## TeamBuildPrepare

This procedure creates a tree in */myResource/gerrit\_working\_dir* with
the head of the branch and an overlay of all open Gerrit changes that
match the configuration filters.

### Input

1.  Go to the TeamBuildPrepare procedure.

2.  Enter the following parameters:

<table>
<colgroup>
<col style="width: 50%" />
<col style="width: 50%" />
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">Parameter</th>
<th style="text-align: left;">Description</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;"><p>Gerrit Config</p></td>
<td style="text-align: left;"><p>Name of the configuration that has the
connection information for Gerrit.</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p>Group Build Changes</p></td>
<td style="text-align: left;"><p>List of the changes in the group. Any
number of lines can be added. Enter the information in one of these
ways:</p>
<ul>
<li><p><strong>Use the change ID:</strong> Every change has two
different IDs. The first is a short number and the second is a SHA1
number. You can either of these IDs: <em>2</em> or
<em>Ib34fbd69fe52c43588d39f3804341c219d087ecf</em>.</p></li>
<li><p><strong>Use the project name and the branch name:</strong> Enter
the project name and the branch separated by a colon (:). An example is
<em>ectest:master</em>.</p></li>
<li><p><strong>Use the change ID, the project name, and the the branch
name:</strong> Enter the change ID, project name, and the branch name
separated by a colon (:). Examples are <em>2:ectest:master</em> or
<em>Ib34fbd69fe52c43588d39f3804341c219d087ecf:ectest:master</em>.</p></li>
</ul></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><p>Project</p></td>
<td style="text-align: left;"><p>The project that contains the change to
build.</p></td>
</tr>
</tbody>
</table>

### Output

After the job runs, you can view the results on the Job Details page in
CloudBees CD/RO. Every job step was completed successfully.

In the **TeamBuildPrepare** step, click the Log button to see the
diagnostic information. The output is similar to the following
diagnostic report:

-   **allocate:** This step checks that the required parameters in the
    configuration are correct. It has no output if the job is
    successful. If an error occurs, it shows the error details.

-   **changes:** This step gets the list of changes to be processed and
    saves for rest of procedure.

-   **annotate:** The step gets the list of changes to be processed and
    saves for rest of procedure.

-   **clone:** If needed, the step clones the remote repository in
    Gerrit to a working directory and then gets the contents. The tree
    should now be synchronized with the head of the master.

-   **revert:** The step gets the tree in the clean state before
    overlaying files.

-   **apply:** The step gets the changes from Gerrit and overlays on top
    of local repository.

# Examples and use cases

This plugin has preconfigured example procedures that include the basic
process to do the following:

-   Clone the repository.

-   Get specific changes.

-   Run user-defined builds and tests.

-   Review and approve changes.

-   Reject changes.

## CustomBuildExample

This procedure runs a sample custom build using the helper methods. This
procedure runs the CustomBuildPrepare, DoWork, and TeamBuildCleanup
procedures as steps. The DoWork step is where the builds and tests steps
are run until TeamBuildCleanup step approves or rejects the changes.

### Input

1.  Go to the CustomBuildExample procedure.

2.  Enter the following parameters:

<table>
<colgroup>
<col style="width: 50%" />
<col style="width: 50%" />
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">Parameter</th>
<th style="text-align: left;">Description</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;"><p>Gerrit Config</p></td>
<td style="text-align: left;"><p>The name of the configuration that has
the connection information for Gerrit.</p></td>
</tr>
</tbody>
</table>

### Output

After the job runs, you can view the results on the Job Details page in
CloudBees CD/RO. In the **CustomBuildExample** step, click the Log
button to see the diagnostic information. The output is similar to the
following diagnostic report:

**GetCodeFromGerrit:** This prepares the custom build using the
CustomBuildPrepare procedure:

-   **allocate:** This step checks that the required parameters in the
    configuration are correct. It has no output if the job is
    successful. If an error occurs, it shows the error details.

-   **change:** It gets the list of changes to be processed and saves
    them for the rest of procedure. Because this procedure has no
    project parameter, the plugin searches for changes in all of the
    Gerrit projects.

-   **clone:** This creates a clone of the remote repository.

-   **revert:** This gets the tree in a clean state before overlaying
    the files.

-   **apply:** This gets the changes from Gerrit and overlays them on
    top of local repostory. **DoWork:** This step runs the builds and
    tests. **GerritCleanup:**This step marks the changes as approved if
    the job is successful.

-   **allocate:** This step checks that the required parameters in the
    configuration are correct. It has no output if the job is
    successful. If an error occurs, it shows the error details.

-   **approve:** This gets the changes from Gerrit and overlays them on
    top of local repostory.

## DevBuildExample

The DevBuildExample procedure runs a sample developer build procedure.

### Input

1.  Go to the DevBuildExample procedure.

2.  Enter the following parameters:

<table>
<colgroup>
<col style="width: 50%" />
<col style="width: 50%" />
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">Parameter</th>
<th style="text-align: left;">Description</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;"><p>Change ID</p></td>
<td style="text-align: left;"><p>The short change ID to build, such as
<em>2</em>.</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p>Gerrit Config</p></td>
<td style="text-align: left;"><p>The name of the configuration that has
the connection information for Gerrit.</p></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><p>Patch ID</p></td>
<td style="text-align: left;"><p>The patchset ID to build, such as
<em>1</em>.</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p>Project</p></td>
<td style="text-align: left;"><p>The project that contains the change to
build.</p></td>
</tr>
</tbody>
</table>

### Output

After the job runs, you can view the results on the Job Details page in
CloudBees CD/RO. In the **DevBuildExample** step, click the **Log**
button to see the diagnostic information. The output is similar to the
following diagnostic report:

**GetCodeFromGerrit:** This step of the example runs the DevBuildPrepare
procedure to take the selected change in the parameters and download a
copy to work with it: \* **allocate:** This step checks that the
required parameters in the configuration are correct. It has no output
if the job is successful. If an error occurs, it shows the error
details. \* **annotate:** If this job was launched manually, annotate
Gerrit so it knows about the job. \* **clone:** This creates a clone of
the remote repository. \* **revert:** This gets the tree in the clean
state before overlaying files. \* **apply:** This gets the changes from
Gerrit and overlays them on top of local repostory. **DoWork:** This
step does the build and test procedures. **GerritCleanup:**This step
cleans up the Gerrit environment, uploading the changes if the DoWork
step is successfully completed or rejecting the change if the step
fails: \* **annotate:** This step approves or rejects the change and
adds a comment to the change in Gerrit.

## TeamBuildExample

The TeamBuildExample run a sample team build.

### Input

1.  Go to the TeamBuildExample procedure.

2.  Enter the following parameters:

<table>
<colgroup>
<col style="width: 50%" />
<col style="width: 50%" />
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">Parameter</th>
<th style="text-align: left;">Description</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;"><p>Branch</p></td>
<td style="text-align: left;"><p>The branch to use, such as
<em>master</em>.</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p>Change ID</p></td>
<td style="text-align: left;"><p>The short change ID to build, such as
<em>5</em>.</p></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><p>Gerrit Config</p></td>
<td style="text-align: left;"><p>The name of the configuration that has
the connection information for Gerrit.</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p>Patch ID</p></td>
<td style="text-align: left;"><p>The patch set ID to build, such as
<em>1</em>.</p></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><p>Project</p></td>
<td style="text-align: left;"><p>The project that contains the change to
build.</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p>Resource</p></td>
<td style="text-align: left;"><p>The name of the resource to
use.</p></td>
</tr>
</tbody>
</table>

### Output

After the job runs, you can view the results on the **Job Details** page
in CloudBees CD/RO. In the **TeamBuildExample** step, click the **Log**
button to see the diagnostic information. The output is similar to the
following diagnostic report:

**GetCodeFromGerrit:** This runs a test of Gerrit changes:

-   **allocate:** This step checks that the required parameters in the
    configuration are correct. It has no output if the job is
    successful. If an error occurs, it shows the error details.

-   **change:** This gets the list of changes to be processed and saves
    them for the rest of procedure.

-   **annotate:** This gets the list of changes to be processed and
    saves them for the rest of procedure.

-   **clone:** If needed, this clones the remote repository in Gerrit to
    a working directory and gets the contents. The tree should now be
    synchronized with the head of the master.

-   **revert:** This gets the tree in the clean state before overlaying
    files.

-   **apply:** This gets the changes from Gerrit and overlays them on
    top of local repostory. **DoWork:** This step does the build and
    test procedures.

-   **GerritCleanup:**\*This step cleans up the Gerrit environment.

-   **allocate:** This step checks that the required parameters in the
    configuration are correct. It has no output if the job is
    successful. If an error occurs, it shows the error details.

-   **approve:** This gets the changes from Gerrit and overlays them on
    top of local repostory.

# Release notes

## EC-Gerrit 2.1.4

-   The documentation has been migrated to the main documentation site.

## EC-Gerrit 2.1.3

-   The plugin icon has been updated.

## EC-Gerrit 2.1.2

-   Fixed issue with configurations being cached for IE.

## EC-Gerrit 2.1.1

-   Updated the plugin to support PostgresSQL database with Gerrit.

-   Added a plugin property *use\_upper\_case\_table\_names* to
    determine whether gsql queries should use upper-case table names.
    The property is set to 0 by default to have the gsql queries use
    lower-case table names. Queries to PostgresSQL and Oracle databases
    are not impacted by this setting. For MySQL database, if the default
    case-sensitivity for table names was changed by explicitly setting
    the MySQL system variable lower\_case\_table\_names, the plugin
    property *use\_upper\_case\_table\_names* should be updated
    accordingly.

## EC-Gerrit 2.1.0

-   Added support for Gerrit 2.8.5.

-   Updated the plugin logic to support the Gerrit review labels called
    *Code-Review* and *Verified*. Starting with Gerrit 2.6, the Verified
    label is no longer installed by default.

-   Updated the plugin logic to handle user names specified in build
    rule filters.

-   Allowed the *Repository Server* configuration parameter to
    optionally accept the protocol it uses for data transfer as part of
    the parameter value. The *Repository Server* value can now be set as
    *ssh://my\_gerrit\_server.my\_domain.com* if
    *my\_gerrit\_server.my\_domain.com* is using Secure Shell (SSH). To
    maintain backward-compatibility, if the value is specified without
    any protocol as *my\_gerrit\_server.my\_domain.com*, *Git* is
    assumed to be the protocol by default.

-   Deprecated the SetupGerritServer procedure. This procedure is no
    longer supported in Gerrit 2.6 and later. Follow the steps
    [here](#gerrit-setup) to configure Gerrit to work with CloudBees
    CD/RO.

-   Added a *revert* step to the DevBuildCleanup and TeamBuildCleanup
    procedures to revert any uncommitted changes from the working
    directory as part of the cleanup.

-   Added postProcessors to track the progress of the plugin procedures.

## EC-Gerrit 2.0.4

-   Fixed the manifest file.

## EC-Gerrit 2.0.3

-   Updated the logic for applying eligible pending changes to honor
    project paths defined in the repository manifest.

## EC-Gerrit 2.0.2.0

-   Fixed minor bugs.

## EC-Gerrit 2.0.1.0

-   Added new XML parameter panels.

-   Made improvements to the Help page.

-   Added steps to the step chooser.

-   Fixed a bug related to the cloning of the repositories.

## EC-Gerrit 1.3.6.0

-   Made minor API improvements.

## EC-Gerrit 1.3.5.0

-   Added support for mySQL.

## EC-Gerrit 1.3.4.0

-   Fixed a bug with the pseudo code snippet execution.

## EC-Gerrit 1.3.3.0

-   Made minor bug fixes.

## EC-Gerrit 1.3.2.0

-   Made minor bug fixes.

## EC-Gerrit 1.3.1.0

-   Downloaded changes.

-   Added multiscope properties.

## EC-Gerrit 1.2.0.0

-   Added grouping features.

-   Added support for scanning single changes.

## EC-Gerrit 1.1.1.0

-   Added support Gerrit 2.1.3.

-   Now use the **review** command instead of **approve** on the command
    line.

-   Now use perl Net:SSH2 library for SSH commands instead of shelling
    to SSH command.

-   Separated the configuration of the Gerrit server into three parts
    (server, user, and port).

-   Added SSH key locations in the plugin configuration (no longer
    searching ~/.ssh for them).

-   Added new helper methods.

-   The project/branches manifest file can now be used to filter the
    changes.
