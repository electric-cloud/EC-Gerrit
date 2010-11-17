@files = (
 ['//property[propertyName="pseudo_code"]/propertySheet/property[propertyName="cmd_overlay"]/value', 'cmd_overlay'],
 ['//property[propertyName="pseudo_code"]/propertySheet/property[propertyName="cmd_clone"]/value'  , 'cmd_clone'],
 ['//property[propertyName="pseudo_code"]/propertySheet/property[propertyName="cmd_revert"]/value' , 'cmd_revert'],
 ['//property[propertyName="pseudo_code"]/propertySheet/property[propertyName="cmd_update"]/value' , 'cmd_update'],

 ['//property[propertyName="ui_forms"]/propertySheet/property[propertyName="GerritCreateConfigForm"]/value'  , 'GerritCreateConfigForm.xml'],
 ['//property[propertyName="ui_forms"]/propertySheet/property[propertyName="GerritEditConfigForm"]/value'  , 'GerritEditConfigForm.xml'],

 ['//property[propertyName="preamble"]/value' , 'preamble.pl'],
 ['//property[propertyName="api"]/value' , 'api.pl'],
 ['//property[propertyName="ECGerrit"]/value' , 'ECGerrit.pm'],

 ['//procedure[procedureName="DevBuildCleanup"]/step[stepName="annotate"]/command' , 'DevBuildCleanup/annotate.pl'],
 ['//procedure[procedureName="DevBuildPrepare"]/step[stepName="allocate"]/command',  'allocate.pl'],
 ['//procedure[procedureName="DevBuildPrepare"]/step[stepName="annotate"]/command' , 'DevBuildPrepare/annotate.pl'],
 ['//procedure[procedureName="DevBuildPrepare"]/step[stepName="apply"]/command'    , 'DevBuildPrepare/apply.pl'],
 ['//procedure[procedureName="DevBuildPrepare"]/step[stepName="clone"]/command'    , 'DevBuildPrepare/clone.pl'],
 ['//procedure[procedureName="DevBuildPrepare"]/step[stepName="revert"]/command'   , 'DevBuildPrepare/revert.pl'],
 ['//procedure[procedureName="DeveloperScan"]/step[stepName="scan"]/command'       , 'DeveloperScan/scan.pl'],
 ['//procedure[procedureName="TeamBuildPrepare"]/step[stepName="allocate"]/command','allocate.pl'],
 ['//procedure[procedureName="TeamBuildPrepare"]/step[stepName="changes"]/command','TeamBuildPrepare/changes.pl'],
 ['//procedure[procedureName="TeamBuildPrepare"]/step[stepName="annotate"]/command','TeamBuildPrepare/annotate.pl'],
 ['//procedure[procedureName="TeamBuildPrepare"]/step[stepName="apply"]/command'   ,'TeamBuildPrepare/apply.pl'],
 ['//procedure[procedureName="TeamBuildPrepare"]/step[stepName="clone"]/command'   ,'TeamBuildPrepare/clone.pl'],
 ['//procedure[procedureName="TeamBuildPrepare"]/step[stepName="revert"]/command'  ,'TeamBuildPrepare/revert.pl'],
 ['//procedure[procedureName="TeamBuildCleanup"]/step[stepName="allocate"]/command','allocate.pl'],
 ['//procedure[procedureName="TeamBuildCleanup"]/step[stepName="approve"]/command' , 'TeamBuildCleanup/approve.pl'],
 ['//procedure[procedureName="CreateConfiguration"]/step[stepName="CreateConfiguration"]/command' , 'CreateConfiguration/createcfg.pl'],
 ['//procedure[procedureName="DeleteConfiguration"]/step[stepName="DeleteConfiguration"]/command' , 'DeleteConfiguration/deletecfg.pl'],
 ['//procedure[procedureName="CustomBuildPrepare"]/step[stepName="allocate"]/command',  'allocate.pl'],
 ['//procedure[procedureName="CustomBuildPrepare"]/step[stepName="changes"]/command','CustomBuildPrepare/changes.pl'],
 ['//procedure[procedureName="CustomBuildPrepare"]/step[stepName="annotate"]/command','CustomBuildPrepare/annotate.pl'],
 ['//procedure[procedureName="CustomBuildPrepare"]/step[stepName="apply"]/command'   ,'CustomBuildPrepare/apply.pl'],
 ['//procedure[procedureName="CustomBuildPrepare"]/step[stepName="clone"]/command'   ,'CustomBuildPrepare/clone.pl'],
 ['//procedure[procedureName="CustomBuildPrepare"]/step[stepName="revert"]/command'  ,'CustomBuildPrepare/revert.pl'],
 ['//procedure[procedureName="CustomBuildPrepare"]/step[stepName="helperMetodsExamples"]/command'  ,'CustomBuildPrepare/helpers.pl'],
 
 ['//procedure[procedureName="SettingUpGerritServer"]/step[stepName="Setup"]/command'  ,'Misc/setup.pl'],
 
 ['//property[propertyName="ec_setup"]/value', 'ec_setup.pl'],
);


