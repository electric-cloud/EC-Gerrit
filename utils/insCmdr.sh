echo "INSERT INTO APPROVAL_CATEGORIES \(NAME,ABBREVIATED_NAME,POSITION,FUNCTION_NAME,COPY_MIN_SCORE,CATEGORY_ID\) VALUES\('ElectricCommander',NULL,2,'NoOp','N','CMDR'\);" | ssh -p 29418 commander@localhost gerrit gsql
echo "INSERT INTO APPROVAL_CATEGORY_VALUES \(NAME,CATEGORY_ID, VALUE\) VALUES\('build succeeded','CMDR','1'\);" | ssh -p 29418 commander@localhost gerrit gsql
echo "INSERT INTO APPROVAL_CATEGORY_VALUES \(NAME,CATEGORY_ID, VALUE\) VALUES\('No score','CMDR','0'\);" | ssh -p 29418 commander@localhost gerrit gsql
echo "INSERT INTO APPROVAL_CATEGORY_VALUES \(NAME,CATEGORY_ID, VALUE\) VALUES\('build failed','CMDR','-1'\);" | ssh -p 29418 commander@localhost gerrit gsql
echo "INSERT INTO REF_RIGHTS \(MIN_VALUE,MAX_VALUE,PROJECT_NAME,REF_PATTERN,CATEGORY_ID,GROUP_ID\) VALUES \(-1,1,'-- All Projects --','refs/heads/*','CMDR',3\);" | ssh -p 29418 commander@localhost gerrit gsql
echo "INSERT INTO PROJECT_RIGHTS \(MIN_VALUE,MAX_VALUE,PROJECT_NAME,CATEGORY_ID,GROUP_ID\) VALUES \(-1,1,'-- All Projects --','CMDR',3\);" | ssh -p 29418 commander@localhost gerrit gsql
