echo "DELETE FROM APPROVAL_CATEGORIES WHERE CATEGORY_ID='CMDR';" | ssh -p 29418 commander@localhost gerrit gsql
echo "DELETE FROM APPROVAL_CATEGORY_VALUES WHERE CATEGORY_ID='CMDR';" | ssh -p 29418 commander@localhost gerrit gsql
echo "DELETE FROM REF_RIGHTS WHERE CATEGORY_ID='CMDR';" | ssh -p 29418 commander@localhost gerrit gsql
echo "DELETE FROM PROJECT_RIGHTS WHERE CATEGORY_ID='CMDR';" | ssh -p 29418 commander@localhost gerrit gsql
