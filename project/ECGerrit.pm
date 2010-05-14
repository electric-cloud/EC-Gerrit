####################################################################
#
# ECGerrit
#   A perl package to encapsulate interaction with the
#   gerrit code review tool
#
####################################################################
package ECGerrit;

$|=1;

# get JSON from the plugin directory
if ("$ENV{COMMANDER_PLUGIN_PERL}" ne "") {
    # during tests
    push @INC, "$ENV{COMMANDER_PLUGIN_PERL}";
} else {
    # during production
    push @INC, "$ENV{COMMANDER_PLUGINS}/@PLUGIN_NAME@/agent/perl";
}
require JSON;

use URI::Escape;
use IPC::Open2;
use MIME::Base64;
use ElectricCommander;
use ElectricCommander::PropDB;

####################################################################
# Object constructor for ECGerrit
#
# Inputs
#   sshurl = the gerrit server  (ssh://user@host:port)
#   dbg    = debug level (0-3)
####################################################################
sub new {
    my $class = shift;

    my $self = {
        _cmdr   => shift,
        _sshurl => shift,
        _dbg    => shift,
    };
    
    my $ssh = $self->{_sshurl};
    # sshurl form:  shh://user@server:port
    $ssh =~ /ssh:\/\/(.*)@(.*):(.*)/;
    $self->{_user}   = $1;
    $self->{_server} = $2;
    $self->{_port}   = $3;

    bless ($self, $class);
    return $self;
}

######################################
# getCmdr
#
# Get the commander object
######################################
sub getCmdr {
    my $self = shift;
    return $self->{_cmdr};
}


######################################
# getSSHUrl
#
# Get the SSHUrl
######################################
sub getSSHUrl {
    my $self = shift;
    return $self->{_sshurl};
}

######################################
# getServer
#
# Get the server
######################################
sub getServer {
    my $self = shift;
    if (!defined $self->{_server} ||
        $self->{_server} eq "") {
        # default to localhost
        return "localhost";
    } else {
        return $self->{_server};
    }
}

######################################
# getUser
#
# Get the user
######################################
sub getUser {
    my $self = shift;
    if (!defined $self->{_user} ||
        $self->{_user} eq "") {
        # default to commander
        return "commander";
    } else {
        return $self->{_user};
    }
}
######################################
# getPort
#
# Get the Port
######################################
sub getPort {
    my $self = shift;
    if (!defined $self->{_port} ||
        $self->{_port} eq "") {
        # default to gerrit default
        return "29418";
    } else {
        return $self->{_port};
    }
}

######################################
# getDbg
#
# Get the Dbg level
######################################
sub getDbg {
    my $self = shift;
    if (!defined $self->{_dbg} ||
        $self->{_dbg} eq "") {
        return 0;
    } else {
        return $self->{_dbg};
    }
}


######################################
# gerrit_db_query
#
# parse output of gerrit db query
#
# Gerrit queries are run through the 
# ssh host gerrit gsql command which
# returns data in JSON format. 
#
# Depending on the query, results could
# be large (too large to hold in mem)
# so be carefull with the query 
#
# args
#   opertation = a SQL string
#
# returns
#   results  - array of results
#
# example
#  my ($exit,@results) = $self->gerrit_db_query("SELECT * FROM ACCOUNTS;");
#  print @results[0]->{columns}{ssh_user_name};
#
######################################
sub gerrit_db_query {
    my $self = shift;
    my $operation = shift;

    my @sqlout = ();

    my $gcmd = "ssh -p " . $self->getPort()
        . " " .  $self->getUser() . "\@" . $self->getServer()
        . " gerrit gsql --format JSON 2>1&";

    my $input = "$operation\n\\q\n";
    $self->debugMsg(3,"========command =========");
    $self->debugMsg(3, $operation);
    $self->debugMsg(3,"========raw output ======");
    my ($exit,$out) = $self->runCmd($gcmd,$input);
    if ($exit != 0 ) {
        # if command did not succeed we should exit
        # this is drastic, but if query command is not working 
        # something fundamental is wrong with setup
        $self->showMsg("$out");
        $self->showError("error running command $gcmd ($exit)");
    }
    $self->debugMsg(3, $out);

    my $row = 0;
    my (@lines) = split(/\n/,$out);
    foreach my $line (@lines) {
        my $json = JSON->new->utf8;
        my $arr = $json->decode($line);
        push @sqlout, $arr;
        $row++;
    }

    # remove the statistics record
    #   {"type":"query-stats","rowCount":3,"runTimeMilliseconds":1}
    if (scalar(@sqlout) > 0) {
        pop @sqlout;
    }

    $self->debugMsg(3, "table found $row rows");
    return @sqlout;
}   

##########################################
# trimstr
#   trim leading and trailing whitespace
# 
# args
#   intput string
#
# returns
#   trimmed output string
##########################################
sub trimstr {
    my $self = shift;
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}


##########################################
# getChangeComments
#   get the comments for a change
# 
# args
#   change - change id
#
# returns
#   table - table of results
#
##########################################
sub getChangeComments {
    my $self = shift;
    my $changeid = shift;
    my @empty = ();
    if (!defined $changeid || "$changeid" eq "") {
        $self->showError("no changeid passed to getChangeComments");
        return @empty;
    }
    # must have something after MESSAGE or the limited parser will not work
    return ($self->gerrit_db_query(
        "select MESSAGE,UUID from CHANGE_MESSAGES where CHANGE_ID = '$changeid';"));
}

##########################################
# getAccountId
#   get the AccountId for the gerrit user
# 
# args
#   user - user name
#
# returns
#   id - numeric AccountId or user
#
##########################################
sub getAccountId {
    my $self = shift;
    my $user = shift;
    if (!defined $user || "$user" eq "") {
        $self->showError ("no user passed to getUserId");
        return undef;
    }
    my @tmp = $self->gerrit_db_query(
        "select ACCOUNT_ID from ACCOUNTS where SSH_USER_NAME = '$user';");
    if (scalar(@tmp) == 0 || "$tmp[0]->{columns}{account_id}" eq "") {
        $self->showError( "No account found for user $user.");
        return "";
    }
    return $tmp[0]->{columns}{account_id};
}

##########################################
# getTime
#   format at time string
# 
# args
#   none
#
# returns
#   time string
##########################################
sub getTime {
    my $self = shift;
    my $string;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,
    $yday,$isdst)=localtime(time);
    $string = sprintf( "%4d-%02d-%02d %02d:%02d:%02.3f",
        $year+1900,$mon+1,$mday,$hour,$min,$sec);
    return $string;
}

##########################################
# computeUUID
#   key field for messages is a computed
#   uuid based on the sequence
#   CHANGE_MESSAGE_ID. This computes the 
#   uuid string
# 
# NOT NEEDED NOW THAT WE ARE USING COMMAND LINE
# FOR APPROVALS. LEFT HERE IN CASE WE NEED IT
# AGAIN
#
# args
#   key - numeric key value
#
# returns
#   uuid string
##########################################
sub computeUUID {
    my $self = shift;
    my $key = shift;
    my $seq=0x7FFFFFFF;
    my $num = pack('NN',$key,$seq);
    my $string = encode_base64($num);
    chomp $string;
    return $string;
}

###################################################
# getOpenChanges
#
# Get a list of open changes for this
# project/branch
#
# args
#   project - project of interest (optional)
#   branch  - branch of interest
# 
# returns
#   result - array from query results
###################################################
sub getOpenChanges {
    my ($self,$proj,$branch) = @_;

    my @result;
    my $destbranch = "refs/heads/$branch";
    my $query = "SELECT * from CHANGES WHERE"
        . " DEST_BRANCH_NAME = '$destbranch'"
        . " AND OPEN = 'Y'";
    if ("$proj" ne "") {
        $query .= " AND DEST_PROJECT_NAME = '$proj'";
    }
    $query .= ";";
    return ($self->gerrit_db_query($query));
}

################################################
# testECState
#
# Tests if a change/patchid has been marked in a 
# particualr state by the commander integration
# This is done by looking in the comments. 
# The EC integration will  add comments to 
# document what has been done.
# 
# comment form
# ec:change:patch:state notes
#
# Examples:
#   job run for this patchid
#   ec:1:1:jobRunning 3453 http://....
#
#   job finished for this patchid
#   ec:1:1:jobDone success http://...
#
# args
#   changeid - numeric changeid
#   patchid - numeric patchid
#   state - state to test
#       valid: jobAvailable jobRunning jobDone
# 
# returns
#   0 - not found
#   uuid of CHANGE_MESSAGES row if found
#
#################################################
sub testECState {
    my $self = shift;
    my $changeid = shift;
    my $patchid = shift;
    my $state    = shift;

    $self->debugMsg(2, "testECState...c=$changeid p=$patchid s=$state");
    if (!defined $changeid || !defined $patchid || !defined $state ||
        "$changeid" eq "" || "$patchid" eq "" ) {
        $self->showError("bad arguments to testECState");
        return 0;
    }
    # get all comments for this changeset 
    # comments are not indexed by patchid
    my @changes = $self->getChangeComments($changeid) ;
    if (!@changes) {
        return 0;
    }
    # look for magic string
    my $numComments = scalar(@changes);
    foreach my $row (@changes) {
        my $msg = $row->{columns}{message};
        if ($msg =~ m/ec\:$changeid\:$patchid\:$state/) {
            return $row->{columns}{uuid};
        }
    }
    return 0;
}
  
################################################
# setECState
#
# marks a change/patchid for  commander integration
# 
# comment form
# ec:change:patch:state notes
#
# args
#   changeid - numeric changeid
#   patchid - numeric patchid
#   state -  state to add
#       valid: jobRunning jobDone jobComplete jobAvailable
#   notes - other text to include in message
# 
#################################################
sub setECState {
    my $self = shift;
    my $changeid = shift;
    my $patchid = shift;
    my $state    = shift;
    my $notes    = shift;

    $self->debugMsg(1,"setECState...c=$changeid p=$patchid s=$state n=$notes");
    if (!defined $self || !defined $changeid || 
        !defined $patchid || !defined $state ||
        "$changeid" eq "" || "$patchid" eq "" || \
        "$state" eq "") {
        $self->showError( "bad arguments to testECState");
        return 0;
    }

    # test for this exact state
    my $newid = testECState($self,$changeid,$patchid,$state);

    if ($newid) {
        $self->debugMsg(1, "state already set: ec:$changeid:$patchid:$state");
        return 1;
    }
    my $result;
    my $msg = "$notes    ec:$changeid:$patchid:$state";
    return $self->approve("",$changeid, $patchid,$msg,"","");
}

#################################################
#################################################
# team_build
#################################################
#################################################
sub team_build {
    my ($self, $project,$branch,$rules) = @_;

    $rules =~ s/^'//g;
    $rules =~ s/'$//g;
    $self->debugMsg(2,"rules:$rules");

    my ($filters,$actions) = $self->parseRules($rules);
    my @changes  = $self->getOpenChanges($project,$branch);
    my ($metrics,$idmap) = $self->get_team_build_metrics(@changes);
    my @eligible = $self->get_eligible_changes($filters,$metrics,$idmap);

    if ($self->getDbg()) {
        $self->print_filters($filters);
        $self->print_actions($actions);
        $self->print_metrics($metrics);
        $self->print_changes(@changes);
        $self->print_idmap($idmap);
        $self->print_eligible(@eligible);
    }
    return @eligible;
}

#################################################
# team_appprove
#################################################
sub team_approve {
    my ($self,$changes,$rules,$msg) = @_;
    return $self->team_approve_base($changes, $rules, "SUCCESS",$msg);
}

#################################################
# team_disappprove
#################################################
sub team_disapprove {
    my ($self,$changes,$rules,$msg) = @_;
    return $self->team_approve_base($changes, $rules, "ERROR",$msg);
}

#################################################
# team_approve_base
#################################################
sub team_approve_base {
    my ($self,$changes,$rules, $state, $msg) = @_;

    my ($filters,$actions) = $self->parseRules($rules);

    # lookup the category, value, and user from the 
    # team_build_rules
    my $category = $actions->{$state}{CAT};
    my $value    = $actions->{$state}{VAL};

    $self->debugMsg(2,"approve");
    $self->debugMsg(2,"category = $category");
    $self->debugMsg(2,"value    = $value");

    foreach my $str (@$changes) {
        my ($changeid, $patchid,$project) = split (/:/,$str);
        $self->approve($project, $changeid, $patchid, $msg, $category,$value);
    }
    return ;
}

##########################################
# approve
#   add comment and/or set approval 
#      using gerrit approve command
# 
# args
#   project - the project  (optional)
#   changeid - the changeset id
#   patchid - the patchset id
#   msg - the message to include
#   category - the CATEGORY to set in approval  (optional)
#   value - the value to set  (optional)
#
# returns
#   exit code of running approve command
##########################################
sub approve {
    my ($self,$project, $changeid, $patchid, $msg, $category,$value) = @_;


    my $gcmd = "ssh -p " . $self->getPort() . " " . $self->getUser() . "\@" . $self->getServer()
        . " gerrit approve $changeid,$patchid"
        . " '--message=\"$msg\"'";

    if ($project && "$project" ne "") {
        $gcmd .= " '--project=\"$project\"'";
    }

    if ($category && "$category" ne "") {
        my $category_option = $self->get_category_name($category);
        if ("$category_option" eq "") {
            $self->showError( "Could not find category name for $category");
            return;
        }
        $gcmd .= " --$category_option=$value";
    }

    $self->debugMsg(2,"approve cmd:$gcmd");

    # run the approve command
    my ($exit,$out) = $self->runCmd($gcmd);
    $self->showMsg($out);
    return $exit;
}
    

#################################################
# get_eligible_changes
#
# process filters, changes, and metrics to 
# pull out the set of changes that should
# be built
#
# Inputs
#   changes - list of candidate changes
#   filters- map of user specified filters
#   metrics - map of user/category/min/max/counts
#
# Return
#   list of change:patch numbers that should be built
#
#################################################
sub get_eligible_changes {
    my ($self,$filters, $metrics,$idmap) = @_;

    my @eligble;
    foreach my $changeid (keys % {$metrics}) {
        # check filters against metrics
        $self->debugMsg(1, "---Checking change $changeid against filters ---");
        if ($self->check_filters($filters, $metrics->{$changeid} )) {
            ## add change/patch to eligible list
            my $patchid = $idmap->{$changeid}{patchid};
            my $project = $idmap->{$changeid}{project};
            $self->debugMsg(1, "...hit $changeid:$patchid");
            push (@eligible, "$changeid:$patchid:$project");
        } else {
            $self->debugMsg(1, "...miss $changeid:$patchid");
        }
    }
    return @eligible;
}


#################################################
# get_team_build_metrics
#
# Search through comments for a project, branch
# and find max/min/count of different category 
# comments
#
# Input
#     filters - map of filters
#################################################
sub get_team_build_metrics {
    my ($self,@changes) = @_;

    my $metrics = ();
    my $idmap = ();

    foreach my $change (@changes) {
        my $changeid = $change->{columns}{change_id};
        my $project  = $change->{columns}{dest_project_name};
        my @max = $self->gerrit_db_query("SELECT MAX(PATCH_SET_ID) FROM"
            . " PATCH_SETS WHERE CHANGE_ID = '$changeid';");
        my $patchid = $max[0]->{columns}{'max(patch_set_id)'};
        $idmap->{$changeid}{patchid} = "$patchid";
        $idmap->{$changeid}{project} = "$project";

        $metrics->{$changeid}{""}{$cat}{COUNT} = 0;
        $metrics->{$changeid}{""}{$cat}{MAX}   = 0;
        $metrics->{$changeid}{""}{$cat}{MIN}   = 0;

        # find all approvals for highest patchset for change
        my @approvals = $self->gerrit_db_query("SELECT * FROM PATCH_SET_APPROVALS WHERE CHANGE_OPEN = 'Y'"
            . " AND CHANGE_ID = '$changeid' AND PATCH_SET_ID = '$patchid';");
        foreach my $approval (@approvals) {
            my $cat      = $approval->{columns}{category_id};
            my $user     = $self->get_user($approval->{columns}{account_id} );
            my $value    = $approval->{columns}{value};

            $metrics->{$changeid}{""}{$cat}{COUNT} += 1;
            if (!defined $metrics->{$changeid}{""}{$cat}{MIN}  ||
                $value < $metrics->{$changeid}{""}{$cat}{MIN} ) {
                $metrics->{$changeid}{""}{$cat}{MIN} = $value;
            }
            if (!defined $metrics->{$changeid}{""}{$cat}{MAX}  ||
                $value > $metrics->{$changeid}{""}{$cat}{MAX} ) {
                $metrics->{$changeid}{""}{$cat}{MAX} = $value;
            }
            $metrics->{$changeid}{$user}{$cat}{COUNT} += 1;
            if (!defined $metrics->{$changeid}{$user}{$cat}{MIN}  ||
                $value < $metrics->{$changeid}{$user}{$cat}{MIN} ) {
                $metrics->{$changeid}{$user}{$cat}{MIN} = $value;
            }
            if (!defined $metrics->{$changeid}{$user}{$cat}{MAX} ||
                $value > $metrics->{$changeid}{$user}{$cat}{MAX} ) {
                $metrics->{$changeid}{$user}{$cat}{MAX}= $value;
            }
        }
    }
    return ($metrics,$idmap);
}


############################################################
# check_filters
#
# Process filters with metrics to see if rules in 
# filters pass. If they do, return 1, otherwise
# return 0
#
# Input
#   filters and metrics maps
# Returns
#   1 if all filters pass, 0 otherwies
############################################################
sub check_filters {
    my ($self,$filters, $metrics) = @_;

    # for each filter
    my $result = 1;
    foreach my $num (sort keys % {$filters}) {
        if ($filters->{$num}{TYPE} =~ /MAX/) { 
            $result = $self->check_max($filters->{$num},$metrics); 
        }
        if ($filters->{$num}{TYPE} =~ /MIN/) { 
            $result = $self->check_min($filters->{$num},$metrics); 
        }
        if ($filters->{$num}{TYPE} =~ /COUNT/) { 
            $result = $self->check_count($filters->{$num},$metrics); 
        }
        if  (!$result) { last; }
    }
    return $result;
}

############################################################
# check_max
#
# Check a filter of type max 
#
# Input
#   fitlers map
#   metrics map
# Returns
#   1 if filter pass, 0 otherwies
############################################################
sub check_max {
    my ($self,$filter,$metrics) = @_;
    my $cat     = $filter->{CAT};
    my $op      = $filter->{OP};
    my $val     = $filter->{VAL};
    my $user_op = $filter->{USER_OP};
    my $user    = $filter->{USER};
    # get the maximum value
    my $max = 0;
    if ("$user_op" eq "") {
        $max = $metrics->{""}{$cat}{MAX} || 0;
    } elsif ($user_op eq "eq") {
        $max = $metrics->{$user}{$cat}{MAX} || 0;
    } elsif ($user_op eq "ne") {
        # take max of all users except $user
        my $usermax = undef;
        foreach my $ruser (keys % {$metrics}) {
            # skip the ne user
            if ($ruser = "$user") { next;}
            if (!defined $usermax || $metrics->{$user}{$cat}{MAX} > $usermax ) {
                $usermax = $metrics->{$user}{$cat}{MAX} || 0;
            }
        }
        $max = $usermax;
    }
    # check max against filter
    my $expr = "$max $op $val";
    my $result = eval $expr;
    $self->debugMsg(1,"...MAX $cat $op $val $user_op $user , max=$max, result=$result");
    return $result;
}

############################################################
# check_min
#
# Check a filter of type min 
#
# Input
#   fitlers map
#   metrics map
# Returns
#   1 if filter pass, 0 otherwies
############################################################
sub check_min {
    my ($self,$filter,$metrics) = @_;
    my $cat     = $filter->{CAT};
    my $op      = $filter->{OP};
    my $val     = $filter->{VAL};
    my $user_op = $filter->{USER_OP};
    my $user    = $filter->{USER};
    # get the maximum value
    my $min = 0;
    if ("$user_op" eq "") {
        $min = $metrics->{""}{$cat}{MIN} || 0;
    } elsif ($user_op eq "eq") {
        $min = $metrics->{$user}{$cat}{MIN} || 0;
    } elsif ($user_op eq "ne") {
        # take min of all users except $user
        my $usermin = undef;
        foreach my $ruser (keys % {$metrics}) {
            # skip the ne user
            if ($ruser = "$user") { next;}
            if (!defined $usermin || $metrics->{$user}{$cat}{MIN} < $usermax ) {
                $usermin = $metrics->{$user}{$cat}{MIN} || 0;
            }
        }
        $min = $usermin;
    }
    # check min against filter
    my $expr = "$min $op $val";
    my $result = eval $expr;
    $self->debugMsg(1,"...MIN $cat $op $val $user_op $user , min=$min, result=$result");
    return $result;
}

############################################################
# check_count
#
# Check a filter of type count 
#
# Input
#   fitlers map
#   metrics map
# Returns
#   1 if filter pass, 0 otherwies
############################################################
sub check_count {
    my ($self,$filter,$metrics) = @_;
    my $cat     = $filter->{CAT};
    my $op      = $filter->{OP};
    my $val     = $filter->{VAL};
    my $user_op = $filter->{USER_OP};
    my $user    = $filter->{USER};
    # get the count value
    my $count = 0;
    if ("$user_op" eq "") {
        $count = $metrics->{""}{$cat}{COUNT} || 0;
    } elsif ($user_op eq "eq") {
        $count = $metrics->{$user}{$cat}{COUNT} || 0;
    } elsif ($user_op eq "ne") {
        # take max of all users except $user
        my $usercount = 0;
        foreach my $ruser (keys % {$metrics}) {
            # skip the ne user
            if ($ruser = "$user") { next;}
            $usercount += $metrics->{$user}{$cat}{COUNT} || 0;
        }
        $count = $usercount;
    }
    # check max against filter
    my $expr = "$count $op $val";
    my $result = eval $expr;
    $self->debugMsg(1,"...COUNT $cat $op $val $user_op $user , count=$count, result=$result");
    return $result;
}

############################################################
# get_user
#
# finds the ssh user name for a given account_id
#
# Args:
#   id - a gerrit account id
#
# Returns
#   string - the ssh_user configured for the account_id
############################################################
sub get_user {
    my ($self,$id) = @_;
    my @accounts = $self->gerrit_db_query("SELECT SSH_USER_NAME FROM ACCOUNTS WHERE ACCOUNT_ID = '$id';");
    if (scalar(@accounts) == 0 || "$accounts[0]->{columns}{ssh_user_name}" eq "") {
        $self->showError("No account found for user $id.");
        return "";
    }
    my $user = $accounts[0]->{columns}{ssh_user_name};
    $self->debugMsg(3,"id=$id user=$user");
    return $user;
}

############################################################
# get_category_name
#
# finds the category name from category id
#
# Args:
#   id - a category id
#
# Returns
#   string - the category name suitable as an approve option
#            it is all lowercase with spaces converted to -
############################################################
sub get_category_name {
    my ($self,$id) = @_;
    my @cats = $self->gerrit_db_query("SELECT NAME FROM APPROVAL_CATEGORIES  WHERE CATEGORY_ID = '$id';");
    if (scalar(@cats) == 0 || "$cats[0]->{columns}{name}" eq "") {
        $self->showError("No category name for id $id.");
        return "";
    }
    my $name = $cats[0]->{columns}{name};
    $name =~ s/ /-/g;
    $name = lc ($name);
    $self->debugMsg(3,"id=$id name=$name");
    return $name;
}

############################################################
# parseRules
#
# read in a blob of config text and parse into 
# filter and action maps
#
# Args:
#   blob - string to process
#
# Returns
#   filters,actions maps
############################################################
sub parseRules {
    my ($self,$blob) = @_;
    my $filters = ();
    my $actions = ();
    my @lines = split (/\n/,$blob);
    my $num = 0;
    foreach my $line (@lines ) {
        if ($line =~ /^#/) { next;}
        if ($line =~ /^[\s]*$/) { next;}
        my @tokens = split (/ /, $line);
        if ($line =~ /^FILTER/) {
            my $type    = @tokens[1];
            my $cat     = @tokens[2];
            my $op      = @tokens[3];
            my $val     = @tokens[4];
            my $userflg = @tokens[5];
            my $user_op = @tokens[6];
            my $user    = @tokens[7];
            $self->debugMsg(3,"parsing FILTER:$type $cat $op $val $user_op $user");
            if ("$type" ne "MAX" && "$type" ne "MIN" &&
                "$type" ne "COUNT" ) {
                $self->showError("FILTER ($type) must be MAX, MIN, or COUNT");
                $self->showError($line);
                next;
            }
            if ("$op" ne "ge" && "$op" ne "eq" &&
                "$op" ne "gt" && "$op" ne "lt" &&
                "$op" ne "le" && "$op" ne "ne") {
                $self->showError("FILTER operation ($op) must be one of:eq ne lt le gt ge");
                $self->showError($line);
                next;
            }
            if ("$val" eq "" ) {
                $self->showError("FILTER value is blank.");
                $self->showError($line);
                next;
            }
            if ("$userflg" eq "USER" ) {
                if ("$user_op" ne "eq" && "$user_op" ne "ne") {
                    $self->showError("USER op ($user_op) must be one of:eq ne");
                    $self->showError($line);
                    next;
                }
                if ("$user" eq "") {
                    $self->showError("user name not found");
                    $self->showError($line);
                    next;
                }
            }
            $filters->{$num}{TYPE} = $type;
            $filters->{$num}{TYPE} = $type;
            $filters->{$num}{CAT} = $cat;
            $filters->{$num}{OP} = $op;
            $filters->{$num}{VAL} = $val;
            $filters->{$num}{USER_OP} = $user_op;
            $filters->{$num}{USER} = $user;
            $num++;
        }
        if ($line =~ /^ACTION/) {
            my $state   = @tokens[1];
            my $cat     = @tokens[2];
            my $val     = @tokens[3];
            $self->debugMsg(3, "parsing ACTION:$state $cat $val $user");
            if ("$state" ne "ERROR" && "$state" ne "SUCCESS") {
                $self->showError("ACTION ($state) must be SUCCESS or ERROR");
                $self->showError($line);
                next;
            }
            if ("$cat" eq "" || "$val" eq "" ) {
                $self->showError("ACTION category and value are required");
                $self->showError($line);
                next;
            }
            $actions->{$state}{CAT} = $cat;
            $actions->{$state}{VAL} = $val;
        }
    }
    return ($filters,$actions);
}


############################################################
# replace_strings
#
# replace keywords in strings.
#
# Args:
#   instring - string to scan
#   map - a map of replacements 
#
# Returns
#   instring with keywords replaced
############################################################
sub replace_strings {
    my ($self,$instring,$map) = @_;
    foreach my $str (keys % {$map}) {
        $instring =~ s/$str/$map->{$str}/g;
    }
    return $instring;
}

############################################################
# getChanges
#
# get the list of changes cached in a property
#
# Returns
#   array of change records
############################################################
sub getChanges {
    my ($self) = @_;
    my @changes=();
    my $cfg = new ElectricCommander::PropDB($self->getCmdr(),"");
    my $change_str = $cfg->getProp("/myJob/gerrit_changes");
    if (!defined $change_str || "$change_str" eq "") {
        return @changes;
    }   
    $self->debugMsg(2,"Changes:$change_str");
    my $json = JSON->new->utf8;
    my $ref = $json->decode($change_str);
    return (@$ref);
}

#############################################################
# runCmd: run a command
#                                                           
# opts  - hashref of options
# cmdin - the command to run
# input - the text to pipe into cmd (optional)
#
# returns
#   exitstatus - exit code of command
#   text       - stdout of command
#############################################################
sub runCmd {
    my $self  = shift;
    my $cmd   = shift;
    my $input = shift;

    ## for test, if canned output is given, pop off
    ## the next output block and return
    if ($::gRunCmdUseFakeOutput) {
        if ("$::gFakeCmdOutput" eq "") {
            # we ran out of fake output
            return (99,"no more output");
        }
        my @lines = split(/\|\|/, "$::gFakeCmdOutput");
        my $text = shift (@lines);
        my ($exitstatus,$out) = split(/\:\:/,$text);
        chomp $exitstatus;

        # push remaining text 
        my $newv = join ("\|\|", @lines);
        $::gFakeCmdOutput = $newv;
        return ($exitstatus,$out);
    }   

    my $pid = open2 (\*CMD_OUT, \*CMD_IN, $cmd);
    if (defined $input && "$input" ne "") {
        print CMD_IN "$input\n";
    }   
    close CMD_IN;
    my $out = do { local $/; <CMD_OUT> };
    close CMD_OUT;
    waitpid $pid, 0;
    my $exitstatus = $? >> 8;
    return ($exitstatus,$out);

}

############################################################
# makeReplacementMap
#
# make a map out of all opts suitable for use in
# replacement calls (replaceStrings)
#
# Returns
#   the hashmap
############################################################
sub makeReplacementMap {
    my $self = shift;
    my $map = (); 
    foreach my $opt (keys % {$opts}) {
        $map->{"{$opt}"} = "$opts->{$opt}";
    }   
    return $map;
}

############################################################
# SCAN FUNCTIONS
############################################################

###################################################
# processNewChanges
#
# find new gerrit changes that this integration has not 
# previously processed and process them
#
# args
#   opts - configuration options
# 
# returns
#   nothing
###################################################
sub processNewChanges {
    my $self = shift;
    my $opts = shift;

    $self->showMsg("Processing new gerrit changes for project $opts->{gerrit_project}"
        . " and branch $opts->{gerrit_branch}...");
    # Get list of all open changes
    my @ch = $self->getOpenChanges("$opts->{gerrit_project}", "$opts->{gerrit_branch}");
    if (!@ch) {
        $self->showMsg( "No changes found.");
        return;
    }
    foreach my $row (@ch) {
        my $changeid = $row->{columns}{change_id};
        my $patchid = $row->{columns}{current_patch_set_id};
        my $project = $row->{columns}{dest_project_name};

        $self->showMsg( "Found change $changeid:$patchid");
        
        # see if any of them need processing
        my $state = "jobAvailable";
        if ($opts->{devbuild_mode} eq "auto") {
            $state = "jobRunning";
        }
        my $uuid = $self->testECState($changeid,$patchid,$state);
        if ($uuid) {
            $self->debugMsg(1, "Already processed change=$changeid patchset=$patchid");
            next;
        } 
        $self->showMsg( "Processing change=$changeid patchset=$patchid");

        # create a comment
        my $msg = "";
        if ($opts->{devbuild_mode} eq "auto") {
            # run a job too
            $self->showMsg ("Running job for $changeid:$patchid");
            $msg = $self->launchECJob($opts,$changeid,$patchid,$project);
        } else {
            # just put a link in comment for building
            $self->showMsg("Creating a link to run a job for $changeid:$patchid");
            $msg = "This change can be built with ElectricCommander. "
                . "https://$opts->{cmdr_webserver}/commander/link/runProcedure/projects/"
                . uri_escape($opts->{devbuild_cmdr_project}) . "/procedures/"
                . uri_escape($opts->{devbuild_cmdr_procedure}) . "?"
                . "&numParameters=4"
                . "&parameters1_name=gerrit_cfg"
                . "&parameters1_value="
                . uri_escape($opts->{gerrit_cfg})
                . "&parameters2_name=changeid"
                . "&parameters2_value=$changeid"
                . "&parameters3_name=project"
                . "&parameters3_value=$project"
                . "&parameters4_name=patchid"
                . "&parameters4_value=$patchid";
        }
        $self->setECState($changeid, $patchid, $state, $msg);
    }
}

###################################################
# launchECJob
#
# Launch a new EC job to test these changes
#
# args
#   opts - configuration options
#   changeid - change id of changes
#   patchid  - patchid of changes
# 
# returns
#   msg - message to put in gerrit comment
###################################################
sub launchECJob {
    my $self = shift;
    my $opts = shift;
    my $changeid = shift;
    my $patchid = shift;
    my $project = shift;

    my $xPath = $self->getCmdr()->runProcedure($opts->{devbuild_cmdr_project} ,
        { procedureName => $opts->{devbuild_cmdr_procedure}, 
          actualParameter => [
            {actualParameterName => 'changeid', value => "$changeid" },
            {actualParameterName => 'patchid', value => "$patchid" },
            {actualParameterName => 'project', value => "$project" },
            {actualParameterName => 'gerrit_cfg', value => "$opts->{gerrit_cfg}" },
          ]
        });
    my $msg = "";
    my $errcode = $xPath->findvalue('//responses/error/code')->string_value;
    if (defined $errcode && "$errcode" ne "") {
        my $errmsg = $xPath->findvalue('//responses/error/message')->string_value;
        $msg = "ElectricCommander tried but could not run a job for this change. [$errcode]";
    } else {
        my $jobId = $xPath->findvalue('//responses/response/jobId')->string_value;
        # Mark the change as processed
        $msg = "This change is being built with ElectricCommander. "
            . "https://$opts->{cmdr_webserver}/commander/link/jobDetails/jobs/$jobId";
    }
    return $msg;
}

###################################################
# processFinishedJobs
#
# find jobs that were started by this integration
# and if complete, mark them in gerrit comments
#
# args
#   opts - configuration options
# 
# returns
#   nothing
###################################################
sub processFinishedJobs {
    my $self = shift;
    my $opts = shift;

    $self->showMsg("Processing finished jobs...");
    if (!defined $opts) {
        $self->showError("bad arguments to processFinishedJobs");
        return;
    }
    my @filter,@selects;
    push (@filter, {"propertyName" => "status",
                    "operator" => "equals",
                    "operand1" => "completed"});
    push (@filter, {"propertyName" => "projectName",
                    "operator" => "equals",
                    "operand1" => $opts->{devbuild_cmdr_project}});
    push (@filter, {"propertyName" => "procedureName",
                    "operator" => "equals",
                    "operand1" => $opts->{devbuild_cmdr_procedure}});
    push (@filter, {"propertyName" => "processed_by_gerrit",
                    "operator" => "notEqual",
                    "operand1" => "done"});

    push (@selects, {"propertyName" => "outcome"});
    push (@selects, {"propertyName" => "branch"});
    push (@selects, {"propertyName" => "changeid"});
    push (@selects, {"propertyName" => "patchid"});
    push (@selects, {"propertyName" => "project"});
    push (@selects, {"propertyName" => "gerrit_cfg"});

    # get list of jobs that are finished but not recorded
    # this should be a relatively small list
    # only returns objectId's
    my $xPath = $self->getCmdr()->findObjects("job", {numObjects => "0",     
        filter => \@filter, select => \@selects});
    {
        my $errcode = $xPath->findvalue('//responses/error/code')->string_value;
        if (defined $errcode && "$errcode" ne "") {
            my $errmsg = $xPath->findvalue('//responses/error/message')->string_value;
            $self->showError("error [$errcode] when searching jobs. $errmsg");
            return;
        }
    }

    # for each job found
    my $objectNodeset = $xPath->find('//response/objectId');
    foreach my $node ($objectNodeset->get_nodelist)
    {
        my $objectId = $node->string_value();
        # get the details
        my $jPath = $self->getCmdr()->getObjects({objectId => $objectId, select => \@selects});
        {
            my $errcode = $jPath->findvalue('//responses/error/code')->string_value;
            if (defined $errcode && "$errcode" ne "") {
                my $errmsg = $jPath->findvalue('//responses/error/message')->string_value;
                $self->showError("error [$errcode] when looking up object #$objectid. $errmsg");
                next;
            }
        }
        # load up all the properties found
        my $props;
        my $on = $jPath->find('//responses/response/object/property');
        foreach my $n ($on->get_nodelist) {
            my $name= $n->findvalue('propertyName')->string_value;
            my $value= $n->findvalue('value')->string_value;
            $props->{$name} = "$value";
            $self->debugMsg(1, "props{$name}=$props->{$name}");
        }

        
        my $msg;
        my $jobId= $jPath->findvalue('//jobId')->string_value;
        my $outcome= $jPath->findvalue('//outcome')->string_value;

        $self->showMsg("Found job $jobId for"
            . " change=$props->{changeid} patchset=$props->{patchid}"
            . " completed with outcome $outcome");
        # mark as done
        $self->getCmdr()->setProperty("/jobs/$jobId/processed_by_gerrit","done");

        # sanity check this job
        if (!defined $props->{changeid} || $props->{changeid} eq "" | 
          !($props->{changeid} =~ /^(\d+\.?\d*|\.\d+)$/) ) {
            $self->debugMsg(1, "changeid[$props->{changeid}] for job $jobId is invalid");
            next;
        }
        if ($outcome eq "success") {
              $msg = "This change was successfully built with ElectricCommander. "
            . "https://$opts->{cmdr_webserver}/commander/link/jobDetails/jobs/$jobId";
        } else {
              $msg = "This change failed the ElectricCommander build. "
            . "https://$opts->{cmdr_webserver}/commander/link/jobDetails/jobs/$jobId";
        }
        $self->debugMsg(1, "$msg");
        $self->setECState("$props->{changeid}", "$props->{patchid}","jobComplete",$msg);
    }
    return;
}

###################################################
# cleanup
#
# remove previous runs of the scanner job
#
# args
#   opts - configuration options
# 
# returns
#   nothing
###################################################
sub cleanup {
    my $self = shift;

    # Check for the OS Type
    my $osIsWindows = $^O =~ /MSWin/;
    my $cfg = new ElectricCommander::PropDB($self->getCmdr(),"");

    my $projectName   = $cfg->getProp("/plugins/EC-Gerrit/projectName");
    my $procedureName = "DeveloperScan";
    my $scheduleName  = "Gerrit New Change Scanner";

    #  Find all previous runs of this job
    my @filterList;
    push (@filterList, {"propertyName" => "projectName",
                        "operator" => "equals",
                        "operand1" => "$projectName"});
    push (@filterList, {"propertyName" => "procedureName",
                        "operator" => "equals",
                        "operand1" => "$procedureName"});
    push (@filterList, {"propertyName" => "status",
                        "operator" => "equals",
                        "operand1" => "completed"});

    # Delete only the jobs that this SCHEDULE started (unless deleteAll specified)
    push (@filterList, {"propertyName" => "scheduleName",
                        "operator" => "equals",
                        "operand1" => "$scheduleName"});

    push (@filterList, {"propertyName" => "outcome",
                        "operator" => "notEqual",
                        "operand1" => "error"});

    # Run the Query
    my $xPath = $self->getCmdr()->findObjects(
        "job", {numObjects => "500", filter => \@filterList });

    # Loop over all returned jobs
    my $nodeset = $xPath->find('//job');
    foreach my $node ($nodeset->get_nodelist)
    {
        #  Find the workspaces (there can be more than one if some steps
        #  were configured to use a different workspace
        my $jobId = $xPath->findvalue('jobId', $node);
        my $jobName = $xPath->findvalue('jobName', $node);
        my $xPath = $self->getCmdr()->getJobInfo($jobId);
        my $wsNodeset = $xPath->find('//job/workspace');
        foreach my $wsNode ($wsNodeset->get_nodelist) {
            my $workspace;
            if ($osIsWindows)
            {
                $workspace = $xPath->findvalue('./winUNC', $wsNode);
                $workspace =~ s/\/\//\\\\/g;
            }
            else
            {
                $workspace = $xPath->findvalue('./unix', $wsNode);
            }

            # Delete the workspace (after checking its name as a sanity test)
            # look for "job_nnn" or "ElectricSentry-nnn"
            if ($workspace =~ /[-_][\d]+$/)
            {
                use File::Path;

                rmtree ([$workspace]) ;
                $self->showMsg( "Deleted workspace - $workspace");
            }
        }

        # Delete the job

        my $xPath = $self->getCmdr()->deleteJob($jobId);
        $self->showMsg( "Deleted job - $jobName");
    }
}
###############################################
# error routines
###############################################

###############################################
# showError
#
# print an error and quit
#
# args
#   msg  - the message to show
#   code - if present, exit with this code
#
###############################################
sub showError {
    my $self = shift;
    my $msg  = shift;
    my $code = shift;

    print STDERR "Error: $msg\n";
    if (defined $code) {
        exit $code;
    }
}

###############################################
# showMsg
#
# print a message
#
# args
#   msg  - the message to show
#
###############################################
sub showMsg {
    my $self = shift;
    my $msg  = shift;

    print "$msg\n";
}

###############################################
# debugMsg
#
# print a message if debug level permits
#
# args
#   lvl  - the debug level for this message
#   msg  - the message to show
#
###############################################
sub debugMsg {
    my $self = shift;
    my $lvl  = shift;
    my $msg  = shift;

    if ($self->getDbg() >= $lvl) {
        print "$msg\n";
    }
}

###############################################
# Debugging routines
###############################################

###############################################
# printAllTables
#
# enumerates all tables in schema, loads them
# into perl hashes and prints contents
#
# could result in very large datasets
# should only be used in development
# on small gerrit dbs
###############################################
sub printAllTables {
    my $self = shift;
    my @tables = $self->gerrit_db_query("\\d");
    $self->print_table(@tables);
    my $rows = scalar(@tables);
    for (my $index=0; $index < $rows; $index++) {
        my @tbl = $self->gerrit_db_query("select * from " .
            $tables[$index]->{columns}{table_name} . ";");
        $self->print_table(@tbl);
    }
}

##########################################
# print_table
#   print the results of a query
# 
# args
#   array returned from gerrit_db_query
#
# returns
#   nothing
##########################################
sub print_table {
    my ($self,@table) = @_;
    print "========table =========\n"; 
    my $row=0;
    foreach my $row (@table) {
        foreach my $col (keys % {$row}) {
            print "row[$row]->{$col}=$row->{$col}\n";
        }
        $row++;
    }
}

############################################################
# print_filters
#
# For debugging, prints out a filters map
#
# Args:
#   filters -  a filters map
#
# Returns
#   prints out contents of filters map
############################################################
sub print_filters {
    my ($self,$filters) = @_;

    # for each filter
    print "--FILTERS--\n";
    foreach my $num (sort keys % {$filters}) {
        print "filter $num: type=$filters->{$num}{TYPE}"
            . " cat=$filters->{$num}{CAT}"
            . " op=$filters->{$num}{OP}"
            . " num=$filters->{$num}{VAL}"
            . " user_op=$filters->{$num}{USER_OP}"
            . " user=$filters->{$num}{USER} \n";
    }

}

############################################################
# print_actions
#
# For debugging, prints out a actions map
#
# Args:
#   actions -  a actions map
#
# Returns
#   prints out contents of actions map
############################################################
sub print_actions {
    my ($self,$actions) = @_;

    print "--ACTIONS--\n";
    print "action SUCCESS: "
        . " $actions->{SUCCESS}{CAT}"
        . " $actions->{SUCCESS}{USER}\n";
    print "action ERROR: "
        . " $actions->{ERROR}{CAT}"
        . " $actions->{ERROR}{USER}\n";
}

############################################################
# print_metrics
#
# For debugging, prints out a metrics map
#
# Args:
#   metrics -  a metrics map
#
# Returns
#   prints out contents of metrics map
############################################################
sub print_metrics {
    my ($self,$metrics) = @_;

    # for each user
    print "--METRICS--\n";
    foreach my $changeid (keys % {$metrics}) {
        print "---change $changeid ---\n";
        foreach my $user (sort keys % {$metrics->{$changeid}}) {
            foreach my $cat (sort keys %{$metrics->{$changeid}{$user}}) {
                print "metric: user=$user category=$cat"
                    . " min=$metrics->{$changeid}{$user}{$cat}{MIN}"
                    . " max=$metrics->{$changeid}{$user}{$cat}{MAX}"
                    . " count=$metrics->{$changeid}{$user}{$cat}{COUNT}\n";
            }
        }
    }
}

############################################################
# print_changes
#
# For debugging, prints out a changes array
#
# Args:
#   changes -  a changes array
#
# Returns
#   prints out contents of changes array
############################################################
sub print_changes {
    my ($self,@changes) = @_;

    # for each user
    print "--CHANGES--\n";
    foreach my $change (@changes) {
        print "Change " . $change->{columns}{change_id} . "\n";
    }
}

############################################################
# print_eligible
#
# For debugging, prints out a eligible array
#
# Args:
#   eligible -  a eligible map
#
# Returns
#   prints out contents of eligible array
############################################################
sub print_eligible {
    my ($self,@eligible) = @_;

    # for each change
    print "--ELIGIBLE LIST--\n";
    foreach my $changestr (@eligible) {
        my ($c,$patch,$proj) = split(/:/,$changestr);
        print "$c:$patch:$proj\n";
    }
}

############################################################
# print_idmap
#
# For debugging, prints out a idmap map
#
# Args:
#   eligible -  a idmap map
#
# Returns
#   prints out contents of patchid map
############################################################
sub print_idmap {
    my ($self,$idmap) = @_;

    # for each change
    print "--PATCH SET IDS--\n";
    foreach my $changeid (keys % {$idmap}) {
        print "$changeid:$idmap->{$changeid}{patchid}:$idmap->{$changeid}{project}\n";
    }
}


1;
