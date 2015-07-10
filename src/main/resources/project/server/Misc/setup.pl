##########################
# setup.pl
##########################
$[/plugins/EC-Gerrit/project/procedure_helpers/api]

gr_insertApprovalCategory('ElectricCommander','NULL',3,'NoOp','N','CMDR');

gr_insertApprovalCategoryValue('Build succeeded','CMDR',1);
gr_insertApprovalCategoryValue('No score','CMDR',0);
gr_insertApprovalCategoryValue('Build failed','CMDR',-1);


print "Setup completed successfully.\n";