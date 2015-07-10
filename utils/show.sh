echo "SELECT * FROM  PATCH_SET_APPROVALS WHERE CHANGE_ID=549;" | ssh -p 29418 commander@localhost gerrit gsql
echo "SELECT * FROM  CHANGE_MESSAGES WHERE CHANGE_ID=549;" | ssh -p 29418 commander@localhost gerrit gsql
