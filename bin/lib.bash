# Function that checks if prior operation succeded and
# terminates if not.  Used throughout to avoid continuing
# if an operation fails.
function error_check {
  if [ "$?" != "0" ];
  then
    echo "** Terminating: Error in last operation."
    exit 255
  fi
}

# Function that waits for the novnc server to come up.  This is the
# last thing done in the fd2dev container, so once it is up, the container
# is ready to be used.
function wait_for_novnc {
  NO_VNC_RESP=$(curl -Is localhost:6901 | grep "HTTP/1.1 200 OK")

  i=1
  sp="/-\|"
  echo -n ' '
  while [ "$NO_VNC_RESP" == "" ]
  do
    # shellcheck disable=SC2059
    printf "\b${sp:i++%${#sp}:1}"
    
    NO_VNC_RESP=$(curl -Is localhost:6901 | grep "HTTP/1.1 200 OK")
    sleep 1
  done
  printf "\b "
}