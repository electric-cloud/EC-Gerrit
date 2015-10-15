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

use ElectricCommander;
use File::Basename;
use ElectricCommander::PropDB;
use ElectricCommander::PropMod;
use Switch;

$|=1;

my $ec = new ElectricCommander();
$ec->abortOnError(0);

my $cfgName = "$[gerrit_cfg]";
my $proj ="$[/plugins/EC-Gerrit]";

my $cfg = new ElectricCommander::PropDB($ec,"/projects/$proj/gerrit_cfgs");
my %vals = $cfg->getRow($cfgName);
my $opts = \%vals;

# get pseudo code snippets
my $code = new ElectricCommander::PropDB($ec,"/projects/$proj/");
my %code_vals = $code->getRow("pseudo_code");

foreach my $snippet (keys %code_vals) {
    $opts->{$snippet} = "$code_vals{$snippet}";
}

if (!defined $opts->{gerrit_server} || $opts->{gerrit_server} eq "") {
        print "configuration [$cfgName] does not contain a gerrit server name\n";
            exit 1;
}

## add other parms and values to opts
$opts->{gerrit_cfg} = "$cfgName";
$opts->{gerrit_working_dir} = "$[/myResource/gerrit_working_dir]";
$opts->{changeid} = $cfg->getProp("/myJob/changeid");
$opts->{patchid} =  $cfg->getProp("/myJob/patchid");
$opts->{project} =  $cfg->getProp("/myJob/project");
$opts->{group_build_changes} = $cfg->getProp("/myJob/group_build_changes");
$opts->{parent_jobId} = $cfg->getProp("/myJob/parent_jobId");
$opts->{self_jobId} = $cfg->getProp("/myJob/jobId");

if (!ElectricCommander::PropMod::loadPerlCodeFromProperty(
    $ec,"/projects/$proj/scm_driver/ECGerrit") ) {
    print "Could not load ECGerrit.pm\n";
}

my $gt = new ECGerrit( $ec, 
    "$opts->{gerrit_user}", 
    "$opts->{gerrit_server}", 
    "$opts->{gerrit_port}", 
    "$opts->{gerrit_public_key}", 
    "$opts->{gerrit_private_key}", 
    $opts->{debug});

###############################################################################
#  
#   API Calls
###############################################################################   
###############################################################################
# Polling
###############################################################################

###############################################################################
# gr_scanChanges  
#  Aplies the filter for the selected project/branches and sets the changes 
#  to be verified
# Args:
#  manifest project/branches (optional) 
#  filter (optional)
#   if not args specified we use the config
#
# Returns:
#   $change_str it also sets a property called 
# gerrit_changes in cofig
###############################################################################
sub gr_scanChanges {
    my $manifest = shift;
    my $filter = shift;
    # get all eligible change/patch combinations from Gerrit
    my @changes = $gt->custom_build($filter,$manifest);
    if (scalar @changes == 0) {
        print "No changes meet the filter criteria.\n";
        exit 0;
    }            
    # save changes so that code extraction, build, and comments
    # all operate on this list regardeless of other changes
    # that appear in mid flight
    my $change_str = gr_encodeJSON(\@changes);
    print "===CHANGES===\n";
    print $change_str . "\n";
    gr_setProperty("changes", $change_str);
    return $change_str;
} 

###############################################################################
# gr_getChanges
#  get the list of changes cached in a property
# 
# Args:
#   none
# Returns:
#   array of change records
###############################################################################
sub gr_getChanges {
    return $gt->getChanges();
}

###############################################################################
# gr_getChange
#  get the information from a single change
# 
# Args:
#   changeId
# Returns:
#   change record
###############################################################################
sub gr_getChange {
	my $changeId = shift;
	my $query = "";
	if ($changeId ne "") {  
       $query .= "SELECT * FROM ". $gt->t('CHANGES')." WHERE CHANGE_ID = '$changeId';";
       @result = gr_dbQuery($query);               
    }
    else {
       $gt->showError("The change id cannot be null");
    }      
}

###############################################################################
# gr_getChangeByKey
#  get the information from a single change
# 
# Args:
#   changeKey
# Returns:
#   change record
###############################################################################
sub gr_getChangeByKey {
	my $changeKey = shift;
	my $query = "";	
	if ($changeKey ne "") {  
       $query .= "SELECT * FROM ". $gt->t('CHANGES'). " WHERE CHANGE_KEY = '$changeKey';";
       @result = gr_dbQuery($query);               
    }
    else {
       $gt->showError("The change key cannot be null");
    }      
}


###############################
# Dependancy checking routines
###############################

###############################################################################
#  gr_getChangeMessages
#  reads the commit message of the change and all the comments
#  
#
#   Args:
#     change_id
#   Returns:
#      array with the commit message and all the comments for
#      a given change
############################################################################### 
sub gr_getChangeMessages {
    my $id = shift;
    my @commit_msg = $gt->gerrit_db_query("SELECT SUBJECT FROM ". $gt->t('CHANGES')." WHERE CHANGE_ID = '$id';");    
    if (scalar(@commit_msg) == 0 || "$commit_msg[0]->{columns}{subject}" eq "") {
        $gt->showError("No category name for id $id.");
        return "";
    }       
    my $msg = $commit_msg[0]->{columns}{subject};
    $msg =~ s/ /-/g;
    $msg = lc ($msg);
    my %o_msg;
    $o_msg->{commit_msg} = $msg;
    
    #get the comments from gerrit
    my @query_comments = $gt->gerrit_db_query("SELECT MESSAGE FROM ". $gt->t('CHANGE_MESSAGES')." WHERE CHANGE_ID = '$id';");
    
    @output = ();    
    push @output,$o_msg; 
    foreach (@query_comments){
        my %comment;
        $comment->{comment} = $_->{columns}{message}; 
        push @output, $comment;      
    }              
    $gt->debugMsg(3,"id=$id commit_msg=$msg");        
    return @output;
}

###############################################################################
# gr_getChangeStatus
#    reading the status field of a particular change
# Args: 
#   id of the change
#   short_mode
#
# Returns:
#   The status of the change  
# NOTE: if short mode is false, it will show the complete word, if not
#   the routine will show the short version of the status 
###############################################################################
sub gr_getChangeStatus {
    my $id = shift;
    my $short_mode = shift;
    my @status = $gt->gerrit_db_query("SELECT STATUS FROM ". $gt->t('CHANGES')." WHERE CHANGE_ID = '$id';");    
    if (scalar(@status) == 0 || "$status[0]->{columns}{status}" eq "") {
        $gt->showError("No category name for id $id.");
        return "";
    }   
    $stat = $status[0]->{columns}{status};
    if ($short_mode == 0 || $short_mode eq ""){
       switch ($stat){
           case('s') { $stat = "Submitted/merge pending"; }
           case('M') { $stat = "Merged"; }
           case('n') { $stat = "Review in progress"; }
           case('A') { $stat = "Abandoned"; }          
       }               
    }
    return $stat;    
}

###############################################################################
# gr_isIncludedInThisVerificationSet
# determine whether a change is included in the current
# verification set
#
#  Args:
#    change_id
#
#  Returns:
#    true if the change is present in the verification set
#    false if the change is not present in the set
###############################################################################
sub gr_isIncludedInThisVerificationSet {
    my $change_id = shift;    
    my $str_changes = gr_getProperty("changes");
    my @changes = gr_decodeJSON($str_changes);    
    if (scalar @changes != 0) {
      
        foreach (@changes) {
            my @change= split(/:/, $_);
            if (@change[0] == $change_id){
               return 1;
            }     
       }             
    }  
    return 0;
}


###############################################################################
# Approval
###############################################################################

###############################################################################
# gr_insertApprovalCategory
#   Add a new aproval category to gerrit, and set the rights
#    
#  NOTE: Gerrit server must be restarted after using this
###############################################################################
sub gr_insertApprovalCategory {
    my ($name, $abb_name, $position, $function_name, 
    $copy_min_score,$category_id) = @_;    
    my $query = 'INSERT INTO '. $gt->t('APPROVAL_CATEGORIES') 
       .' (NAME,ABBREVIATED_NAME,POSITION,FUNCTION_NAME,COPY_MIN_SCORE,CATEGORY_ID) ';  
    if ($abb_name eq ""){
        $abb = 'NULL';
    }  
    if ($name ne "") {  
       $query .= "VALUES ('$name',$abb_name,$position,'$function_name','$copy_min_score','$category_id');";
       @result = gr_dbQuery($query);   
	   print @result;
       gr_insertRefRights($category_id);
       gr_insertProjectRights($category_id);       
    }
    else {
       $gt->showError("The category name cannot be null");
    }  
}

###############################################################################
# gr_insertRefRights
#  Adds the category id into the REF_RIGHTS table
#  Args:
#     $category_id
###############################################################################

sub gr_insertRefRights {
    my $category_id = shift;    
    my $query = 'INSERT INTO '. $gt->t('REF_RIGHTS')
       . ' (MIN_VALUE,MAX_VALUE,PROJECT_NAME,REF_PATTERN,CATEGORY_ID,GROUP_ID) ';
    my @result;    
    if ($category_id ne "") {
        $query .= "VALUES (-1,1,'-- All Projects --','refs/heads/*','$category_id',3);";
        @result = gr_dbQuery($query); 
    }
}

###############################################################################
# gr_insertProjectRights
#  Adds the category id into the PROJECT_RIGHTS table
#  Args:
#     $category_id
###############################################################################

sub gr_insertProjectRights {
    my $category_id = shift;    
    my $query = 'INSERT INTO '. $gt->t('PROJECT_RIGHTS')
    . ' (MIN_VALUE,MAX_VALUE,PROJECT_NAME,CATEGORY_ID,GROUP_ID) ';
    my @result;    
    if ($category_id ne "") {
        $query .= "VALUES (-1,1,'-- All Projects --','$category_id',3);";
        @result = gr_dbQuery($query); 
    }
}

###############################################################################
# gr_insertApprovalCategoryValue
#
# Insert a new category value to be used like a new approval bit
# Args:
#  $name
#  $category_id
#  $value
###############################################################################
sub gr_insertApprovalCategoryValue {
    my ($name,$category_id, $value ) = @_;
    my $query = "INSERT INTO ". $gt->t('APPROVAL_CATEGORY_VALUES')
       . " (NAME,CATEGORY_ID, VALUE) ";    
    if ($name ne "") {  
       $query .= "VALUES ('$name','$category_id','$value');";
       @result = gr_dbQuery($query);          
	   print @result;
    }
    else {
       $gt->showError("The category name value cannot be null");
   }  
}

###############################################################################
# gr_setCustomReviewComment
#   args
#     change_id
###############################################################################
sub gr_setCustomReviewComment{
    my $msg = shift;    
    gr_setProperty("custom_review_msg", $msg);
}


###############################################################################
# MISC Routines
###############################################################################
###############################################################################
# gr_loadPerlCodeFromFile
#  Load and executes the perl code from a file 
#  Args:
#    filename
#
#  Returns:
#    true if the execution of the code is succesful 
###############################################################################
sub gr_loadPerlCodeFromFile {     
    my $file = shift;
    my $openResult = open( my $fin, $file);
    if (!defined($openResult)) {
        print "could not open $file:$!\n"; 
        return 0;
    }
    local $/;
    my $code = <$fin>;
    close $fin;
    if ("$code" eq "") {
        print "Error: could not load perl code from $file\n";
        return 0;
    }   
    eval "$code";
    if ($@) {
        warn $!;
        return 0;
    }   
    return 1;
}

###############################################################################
# gr_loadTextFile 
#   Loads a text file and returns the text
#  
# Args:
#    filename
# Returns:
#    a string with the text
###############################################################################
sub gr_loadTextFile {
    my $file = shift;
    my $openResult = open( my $fin, $file);
    if (!defined($openResult)) {
        print "could not open $file:$!\n"; 
        return 0;
    }
    local $/;
    my $text = <$fin>;
    close $fin;
    if ("$text" eq "") {
        print "Error: could not load text from $file\n";
        return 0;
    }    
    return $text;
}

###############################################################################
# gr_loadManifest
#   LoadProject/branches manifest from file and store it on a property
#  
# Args:
#    property name in where the text will be stored
#    file path
#    
###############################################################################
sub gr_loadManifest {
   my $property = shift;
   my $filePath = shift;   
   my $manifest_str = gr_loadTextFile($filePath);   
   return gr_setProperty($property, $manifest_str);    
}

###############################################################################
#  gr_getProperty
#    Read the content of a property, it only works for properties
#    created using this API
#
#  Args:
#    property name
#    jobId
#  Returns:
#    value
###############################################################################
sub gr_getProperty {
    my $name = shift;
    my $jobId = shift;
    
    my $property_value = "";     
    
    if ($jobId eq "") {
        
        if ($opts->{parent_jobId} eq "") {
          $property_value = $cfg->getProp("/myJob/gerrit_$name");
        } else {       
          @data = gr_readFromFile($name, $opts->{parent_jobId});    
        }            
    } else {
          @data = gr_readFromFile($name, $jobId);    
    }
    my $output = "";
    if ($property_value eq ""){
        foreach my $line (@data){
            $output .= $line;
        }
        return $output;
    }
    else {
        return $property_value;
    }   
}

###############################################################################
#  gr_setProperty
#    Sets a new property in the commander
#
#  Args:
#   property name
#   property value
#   
###############################################################################
sub gr_setProperty {
    my $name = shift;
    my $property_value = shift; 
    
    $gt->getCmdr()->setProperty("/myJob/gerrit_$name", $property_value);
    gr_saveToFile($name, $property_value);    
    return $property_value;
}

###############################################################################
#  gr_saveToFile
#    Sets a new property to a file in the workspace
#
#  Args:
#   property name
#   property value
#   jobId
###############################################################################
sub gr_saveToFile {
    my $name = shift;
    my $property_value = shift; 
     
                       #gpf = gerrit property file
    open FILE, ">$name.gpf" or die $!;
    print FILE $property_value;
    close FILE;     
}

###############################################################################
#  gr_readFromFile
#    gets a property from a file in the workspace
#
#  Args:
#   property name
#   jobId
###############################################################################
sub gr_readFromFile {
    my $name = shift;
    my $jobId = shift;
       
    my $xpath = $gt->getCmdr()->getJobDetails($jobId);
    
    my $ws;
    if ("$^O" eq "MSWin32") {
       $ws = $xpath->findvalue("//workspace[1]/winUNC"); 
    } else {
       $ws = $xpath->findvalue("//workspace[1]/unix"); 
    }
    
                       #gpf = gerrit property file
    my $path = "$ws/$name.gpf";
          
    open FILE, "<$path" or die "Can't open the file $path in the workspace, check the property name or the jobId.";
    my @data = <FILE>;
    close FILE;    
           
    return @data;    
}

###############################################################################
# gr_encodeJSON 
#  Encodes the data to JSON format
# Args:
#   Array of data
# Returns:
#   data string formated in JSON
###############################################################################
sub gr_encodeJSON {
    my @data = shift;
    my $json = JSON->new->utf8;
    my $data_str = $json->encode(@data);    
    return $data_str;
}

###############################################################################
# gr_decodeJSON
#   Decodes a JSON string 
# Args:
#   String data formated in JSON
# Returns:
#   Data array
###############################################################################
sub gr_decodeJSON {
    my $data = shift;
    my $json = JSON->new->utf8;
    my $ref = $json->decode($data);
    return ($ref);
}

###############################################################################
# gr_dbQuery
#   Perfroms a query in SQL against the configured gerrit server
#  Args:
#    SQL query
#  Returns:
#    Array of data results 
###############################################################################
sub gr_dbQuery{
    my $query = shift;    
    return $gt->gerrit_db_query($query);
}


###############################################################################
# gr_jobStatus
#   Get the status of a given job
#  Args:
#    Job id
#  Returns:
#    true if the job was succesful 
###############################################################################

sub gr_jobStatus{
    my $jobId = shift;
    my $xPath = $ec->getProperty("/myJob/outcome");
    my $outcome = $xPath->findvalue('//value')->string_value;
    
    if ($outcome eq "success"){
        return 1;
    }    
    return 0;
}

###############################################################################
# grouping
###############################################################################

###############################################################################
# gr_createGroupFromFile
#   Loads a manifest into a property
#  Args:
#    filename
#    groupname
#  
###############################################################################
sub gr_createGroupFromFile{
	my $filename = shift;
	my $groupName = shift;
	gr_loadManifest($groupName, $filename);  	
}

###############################################################################
# gr_createGroupFromStr
#   Creates a group from a string
#  Args:
#   groupname
#   string
#  
###############################################################################
sub gr_createGroupFromStr{
	my $string = shift;
	my $groupName = shift;
	gr_setProperty($groupName, $string); 	
}

###############################################################################
# gr_scanGroup
#   Scan a set of changes specified in a group
#  Args:
#    groupname
#    procedure name
#    is multigroup?
#
###############################################################################
sub gr_scanGroup {
	my $groupName = shift;
	my $procedure = shift;	
	my $multiGroup = shift;
	
	my $changes = "";
    	
	if ($multiGroup ne 1){
		$changes = gr_getProperty($groupName);        		
	} else {		
		my @groups = split(/\n/, gr_getProperty($groupName));	
			
		foreach $group (@groups) {		
			$changes .=  gr_getProperty($group) . "\n";            			
		}			
	}
			
	if ($procedure ne "") {
		my $xPath = $gt->getCmdr()->runProcedure($opts->{devbuild_cmdr_project} ,
			{ procedureName => $procedure, 
			  actualParameter => [
				{actualParameterName => 'group_build_changes', value => "$changes" },			
                {actualParameterName => 'parent_jobId', value => "$opts->{self_jobId}" },                
				{actualParameterName => 'gerrit_cfg', value => "$opts->{gerrit_cfg}" },
			  ]
			});	
		my $errcode = $xPath->findvalue('//responses/error/code')->string_value;
		if (defined $errcode && "$errcode" ne "") {
			my $errmsg = $xPath->findvalue('//responses/error/message')->string_value;
			$msg = "ElectricCommander tried but could not run a job for this group. [$errcode]";
		} else {
			my $jobId = $xPath->findvalue('//responses/response/jobId')->string_value;
			# Mark the change as processed
			$msg = "The scan is running. "
				. "https://$opts->{cmdr_webserver}/commander/link/jobDetails/jobs/$jobId";
		}		
		return $msg;
	} else {
		$gt->showError("The procedure cannot be null.");
	}	
}

###############################################################################
# gr_downloadChanges
#   Launch the build prepare job with the supplied changes
#  Args:
#    Group name
#    is multigroup
#    procedure name
#
###############################################################################
sub gr_downloadChanges {
	my $groupName = shift;		
	my $multiGroup = shift;
    my $projectName = shift;
    my $procedureName = shift;
	
	my $changes = "";   
	
     if ($projectName eq '') {
        print "Warning: the project name is missing. We will use $opts->{devbuild_cmdr_project} by default.\n";
        $projectName = $opts->{devbuild_cmdr_project};
    }
    if ($procedureName eq '') {
        print "Warning: the procedure name is missing. We will use TeamBuildPrepare by default.\n";
        $procedureName = 'TeamBuildPrepare';
    }
       
	if ($multiGroup ne 1){
		$changes = gr_getProperty($groupName);        		
	} else {		
		my @groups = split(/\n/, gr_getProperty($groupName));	
			
		foreach $group (@groups) {		
			$changes .=  gr_getProperty($group) . "\n";            			
		}			
	}	
		my $xPath = $gt->getCmdr()->runProcedure($projectName,
			{ procedureName => $procedureName, 
			  actualParameter => [
				{actualParameterName => 'group_build_changes', value => "$changes" },                            
				{actualParameterName => 'gerrit_cfg', value => "$opts->{gerrit_cfg}" },
			  ]
			});	
		my $errcode = $xPath->findvalue('//responses/error/code')->string_value;
		if (defined $errcode && "$errcode" ne "") {
			my $errmsg = $xPath->findvalue('//responses/error/message')->string_value;
			$msg = "ElectricCommander tried but could not run a job for this group. [$errcode]";
		} else {
			my $jobId = $xPath->findvalue('//responses/response/jobId')->string_value;
			# Mark the change as processed
			$msg = "The scan is running. "
				. "https://$opts->{cmdr_webserver}/commander/link/jobDetails/jobs/$jobId";
		}		
		return $msg;	
}