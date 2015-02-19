@files = (
	['//property[propertyName="ui_forms"]/propertySheet/property[propertyName="GerritCreateConfigForm"]/value'  , 'GerritCreateConfigForm.xml'],
	['//property[propertyName="ui_forms"]/propertySheet/property[propertyName="GerritEditConfigForm"]/value'  , 'GerritEditConfigForm.xml'],

	['//property[propertyName="pseudo_code"]/propertySheet/property[propertyName="cmd_overlay"]/value', 'server/cmd_overlay'],
	['//property[propertyName="pseudo_code"]/propertySheet/property[propertyName="cmd_clone"]/value'  , 'server/cmd_clone'],
	['//property[propertyName="pseudo_code"]/propertySheet/property[propertyName="cmd_revert"]/value' , 'server/cmd_revert'],
	['//property[propertyName="pseudo_code"]/propertySheet/property[propertyName="cmd_update"]/value' , 'server/cmd_update'],

	['//property[propertyName="preamble"]/value' , 'server/preamble.pl'],
	['//property[propertyName="api"]/value' , 'server/api.pl'],
	['//property[propertyName="ECGerrit"]/value' , 'server/ECGerrit.pm'],

	['//procedure[procedureName="CreateConfiguration"]/step[stepName="CreateConfiguration"]/command' , 'config/createcfg.pl'],
	['//procedure[procedureName="DeleteConfiguration"]/step[stepName="DeleteConfiguration"]/command' , 'config/deletecfg.pl'],
	
	['//property[propertyName="ec_setup"]/value', 'ec_setup.pl'],
	
	['//procedure[procedureName="DevBuildCleanup"]/step[stepName="annotate"]/command' , 'server/DevBuildCleanup/annotate.pl'],
	['//procedure[procedureName="DevBuildPrepare"]/step[stepName="allocate"]/command',  'server/allocate.pl'],
	['//procedure[procedureName="DevBuildPrepare"]/step[stepName="annotate"]/command' , 'server/DevBuildPrepare/annotate.pl'],
	['//procedure[procedureName="DevBuildPrepare"]/step[stepName="apply"]/command'    , 'server/DevBuildPrepare/apply.pl'],
	['//procedure[procedureName="DevBuildPrepare"]/step[stepName="clone"]/command'    , 'server/DevBuildPrepare/clone.pl'],
	['//procedure[procedureName="DevBuildPrepare"]/step[stepName="revert"]/command'   , 'server/DevBuildPrepare/revert.pl'],
	['//procedure[procedureName="DeveloperScan"]/step[stepName="scan"]/command'       , 'server/DeveloperScan/scan.pl'],
	['//procedure[procedureName="TeamBuildPrepare"]/step[stepName="allocate"]/command','server/allocate.pl'],
	['//procedure[procedureName="TeamBuildPrepare"]/step[stepName="changes"]/command','server/TeamBuildPrepare/changes.pl'],
	['//procedure[procedureName="TeamBuildPrepare"]/step[stepName="annotate"]/command','server/TeamBuildPrepare/annotate.pl'],
	['//procedure[procedureName="TeamBuildPrepare"]/step[stepName="apply"]/command'   ,'server/TeamBuildPrepare/apply.pl'],
	['//procedure[procedureName="TeamBuildPrepare"]/step[stepName="clone"]/command'   ,'server/TeamBuildPrepare/clone.pl'],
	['//procedure[procedureName="TeamBuildPrepare"]/step[stepName="revert"]/command'  ,'server/TeamBuildPrepare/revert.pl'],
	['//procedure[procedureName="TeamBuildCleanup"]/step[stepName="allocate"]/command','server/allocate.pl'],
	['//procedure[procedureName="TeamBuildCleanup"]/step[stepName="approve"]/command' , 'server/TeamBuildCleanup/approve.pl'],
	['//procedure[procedureName="CustomBuildPrepare"]/step[stepName="allocate"]/command',  'server/allocate.pl'],
	['//procedure[procedureName="CustomBuildPrepare"]/step[stepName="changes"]/command','server/CustomBuildPrepare/changes.pl'],
	['//procedure[procedureName="CustomBuildPrepare"]/step[stepName="annotate"]/command','server/CustomBuildPrepare/annotate.pl'],
	['//procedure[procedureName="CustomBuildPrepare"]/step[stepName="apply"]/command'   ,'server/CustomBuildPrepare/apply.pl'],
	['//procedure[procedureName="CustomBuildPrepare"]/step[stepName="clone"]/command'   ,'server/CustomBuildPrepare/clone.pl'],
	['//procedure[procedureName="CustomBuildPrepare"]/step[stepName="revert"]/command'  ,'server/CustomBuildPrepare/revert.pl'],
	['//procedure[procedureName="CustomBuildPrepare"]/step[stepName="helperMetodsExamples"]/command'  ,'server/CustomBuildPrepare/helpers.pl'],
	['//procedure[procedureName="SetupGerritServer"]/step[stepName="Setup"]/command'  ,'server/Misc/setup.pl'],
	
    ['//property[propertyName="ui_forms"]/propertySheet/property[propertyName="DevBuildCleanup"]/value', 'forms/gerritDevBuildCleanupForm.xml'], 
    ['//property[propertyName="ui_forms"]/propertySheet/property[propertyName="DevBuildPrepare"]/value', 'forms/gerritDevBuildPrepareForm.xml'], 
    ['//property[propertyName="ui_forms"]/propertySheet/property[propertyName="TeamBuildPrepare"]/value', 'forms/gerritTeamBuildPrepareForm.xml'], 
    ['//property[propertyName="ui_forms"]/propertySheet/property[propertyName="TeamBuildCleanup"]/value', 'forms/gerritTeamBuildCleanupForm.xml'], 
    ['//property[propertyName="ui_forms"]/propertySheet/property[propertyName="CustomBuildPrepare"]/value', 'forms/gerritCustomBuildPrepareForm.xml'], 
    ['//property[propertyName="ui_forms"]/propertySheet/property[propertyName="SetupGerritServer"]/value', 'forms/gerritSetupGerritServerForm.xml'], 
    ['//property[propertyName="ui_forms"]/propertySheet/property[propertyName="TeamBuildExample"]/value', 'forms/gerritTeamBuildExampleForm.xml'],  
    ['//property[propertyName="ui_forms"]/propertySheet/property[propertyName="DevBuildExample"]/value', 'forms/gerritDevBuildExampleForm.xml'], 
		
    ['//procedure[procedureName="DevBuildCleanup"]/propertySheet/property[propertyName="ec_parameterForm"]/value', 'forms/gerritDevBuildCleanupForm.xml'], 
    ['//procedure[procedureName="DevBuildPrepare"]/propertySheet/property[propertyName="ec_parameterForm"]/value', 'forms/gerritDevBuildPrepareForm.xml'],  
    ['//procedure[procedureName="TeamBuildPrepare"]/propertySheet/property[propertyName="ec_parameterForm"]/value', 'forms/gerritTeamBuildPrepareForm.xml'], 
    ['//procedure[procedureName="TeamBuildCleanup"]/propertySheet/property[propertyName="ec_parameterForm"]/value', 'forms/gerritTeamBuildCleanupForm.xml'], 
    ['//procedure[procedureName="CustomBuildPrepare"]/propertySheet/property[propertyName="ec_parameterForm"]/value', 'forms/gerritCustomBuildPrepareForm.xml'], 
    ['//procedure[procedureName="SetupGerritServer"]/propertySheet/property[propertyName="ec_parameterForm"]/value', 'forms/gerritSetupGerritServerForm.xml'], 	
    ['//procedure[procedureName="TeamBuildExample"]/propertySheet/property[propertyName="ec_parameterForm"]/value', 'forms/gerritTeamBuildExampleForm.xml'], 
    ['//procedure[procedureName="CustomBuildExample"]/propertySheet/property[propertyName="ec_parameterForm"]/value', 'forms/gerritCustomBuildExampleForm.xml'],
    ['//procedure[procedureName="DevBuildExample"]/propertySheet/property[propertyName="ec_parameterForm"]/value', 'forms/gerritDevBuildExampleForm.xml'],  
	
);


