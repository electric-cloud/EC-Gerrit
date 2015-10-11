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

##########################
# setup.pl
##########################
$[/plugins/EC-Gerrit/project/procedure_helpers/api]

gr_insertApprovalCategory('ElectricCommander','NULL',3,'NoOp','N','CMDR');

gr_insertApprovalCategoryValue('Build succeeded','CMDR',1);
gr_insertApprovalCategoryValue('No score','CMDR',0);
gr_insertApprovalCategoryValue('Build failed','CMDR',-1);


print "Setup completed successfully.\n";