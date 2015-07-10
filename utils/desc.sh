echo APPROVAL_CATEGORIES
echo "SELECT * FROM APPROVAL_CATEGORIES ;" | ssh -p 29418 commander@localhost gerrit gsql
echo APPROVAL_CATEGORY_VALUES
echo "SELECT * FROM APPROVAL_CATEGORY_VALUES ;" | ssh -p 29418 commander@localhost gerrit gsql
echo REF_RIGHTS
echo "SELECT * FROM REF_RIGHTS ;" | ssh -p 29418 commander@localhost gerrit gsql
echo PROJECT_RIGHTS
echo "SELECT * FROM PROJECT_RIGHTS ;" | ssh -p 29418 commander@localhost gerrit gsql
