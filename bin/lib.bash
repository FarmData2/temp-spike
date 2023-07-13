# Function that checks if prior operation succeded and
# terminates if not.  Used throughout to avoid continuing
# if an operation fails.
function error_check {
  if [ "$?" != "0" ];
  then
    echo "** Terminating: Error in last operation."
    exit -1
  fi
}