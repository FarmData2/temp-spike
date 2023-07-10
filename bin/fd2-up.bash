#!/bin/bash

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

# Ensuring this script is not being run as root.
RUNNING_AS_ROOT=$(id -un | grep "root" )
if [ -n "$RUNNING_AS_ROOT" ];
then
  echo "The fd2-up.bash script should not be run as root."
  echo "Please run without using sudo."
  exit 255
fi

# Ensure that this script is not being run in the development container.
HOST=$(docker inspect -f '{{.Name}}' $HOSTNAME 2> /dev/null)
if [ "$HOST" == "/fd2_dev" ];
then
  echo "The fd2-up.bash script should not be run in the dev container."
  echo "Always run fd2-up.bash on your host OS."
  exit 255
fi

# Get the path to the main repo directory.
SCRIPT_PATH=$(readlink -f $0)  # Path to this script.
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")  # Path to directory containing this script.
REPO_ROOT_DIR=$(builtin cd "$SCRIPT_DIR/.." && pwd) # REPO root directory.
cd "$REPO_ROOT_DIR"

echo "Starting FarmData2..."

# Get the name of the directory containing the FarmData2 repo.
# This is the FarmData2 directory by default, but may have been
# changed by the user.
FD2_PATH=$(pwd)
FD2_DIR=$(basename $FD2_PATH)
cd docker
echo "  Starting from $FD2_PATH in repo $FD2_DIR."

# Check for docker.sock and ensure that ~/.docker/run/docker.sock exists.
echo "Checking for docker..."
DOCKER_SOCK_VAR=$(ls /var/run/docker.sock 2> /dev/null)
DOCKER_SOCK_HOME=$(ls ~/.docker/run/docker.sock 2> /dev/null)
if [ -z "$DOCKER_SOCK_VAR" ] && [ -z "$DOCKER_SOCK_HOME" ];
then
  echo "  Docker socket not found at /var/run/docker.sock or ~/.docker/run/docker.sock"
  echo "  Ensure that the docker engine or Docker desktop is installed and running."
  exit 255
else
  if [ -z "$DOCKER_SOCK_HOME" ]
  then
    # This symlink allows the docker-compose to mount it the same on linux/mac/win.
    echo "  Creating symbolic link to /var/run/docker.sock as ~/.docker/run/docker.sock"
    ln -s /var/run/docker.sock ~/.docker/run/docker.sock
  fi 
fi
# We now know this path exists on all platforms.
DOCKER_SOCK_PATH=~/.docker/run/docker.sock
echo "  Using docker socket at $DOCKER_SOCK_PATH."

# Determine the host operating system.  This allows us to do different
# things based on the host, both in this script and in the startup.bash
# script that runs in the dev container when it starts.
echo "Detecting Operating System..."
OS=$(uname -a)
PROFILE=
if [[ "$OS" == *"Darwin"* ]];
then
  PROFILE=macos
elif [[ "$OS" == *"microsoft"* ]] || [[ "$OS" == *"Microsoft"* ]];
then
  # Note that this is before Linux because if running in WSL
  # uname -a reports Linux, but also has microsoft later in the output.
  PROFILE=wsl
elif [[ "$OS" == *"Linux"* ]];
then
  PROFILE=linux
else
  echo "Your host operating system $OS was not recognized."
  echo "Plese file an issue on the FarmData2 issue tracker."
  exit 255
fi
echo "  Running on a $PROFILE host."

# Make sure that things are in order so that the user in the 
# development container will be able to access the docker.sock
# file and all of the FarmData2 files. This is done by making 
# sure that...
#
# For Linux and Windows (WSL) hosts: 
#   * There is a docker group.
#   * The current user is in the docker group. 
#   * The docker.sock file is in the docker group.
#   * The docker group has RW access to docker.sock
#
#   * There is an fd2grp group.
#   * That the current user is in the fd2grp
#   * The fd2grp has RW access to to everything in FarmData2
#
# When the development environment container starts:
#   * There is a fd2grp with the same GID as on the host.
#   * The fd2dev user is in the fd2grp group
#
#  Note: The pieces in the development environment container are
#        handled by the dev/startup.bash script that runs when the
#        container starts.

if [ "$PROFILE" == "linux" ] || [ "$PROFILE" == "wsl" ];
then
  echo "Configuring Linux or Windows (WSL) host..."

  # If the docker group doesn't exist on the host, create it.
  DOCKER_GRP_EXISTS=$(grep "docker" /etc/group)
  if [ -z "$DOCKER_GRP_EXISTS" ];
  then
    echo "  Creating new docker group on host."
    sudo groupadd docker
    error_check
    DOCKER_GRP_GID=$(cat /etc/group | grep "^docker:" | cut -d':' -f3)
    echo "  docker group created with GID=$DOCKER_GRP_GID."
  else 
    DOCKER_GRP_GID=$(cat /etc/group | grep "^docker:" | cut -d':' -f3)
    echo "  docker group exists on host with GID=$DOCKER_GRP_GID."
  fi

  # If the current user is not in the docker group add them.
  USER_IN_DOCKER_GRP=$(groups | grep "docker")
  if [ -z "$USER_IN_DOCKER_GRP" ];
  then 
    echo "  Adding user $(id -un) to the docker group."
    sudo usermod -a -G docker $(id -un)
    error_check
    echo "  User $(id -un) added to the docker group."
    echo "  ***"
    echo "  *** Run the ./fd2-up.bash script again to continue."
    echo "  ***"
    exec newgrp docker
  else
    echo "  User $(id -un) is in docker group."
  fi

  # If the docker.sock does not belong to the docker group assign it.
  SOCK_IN_DOCKER_GRP=$(ls -lH "$DOCKER_SOCK_PATH" | grep " docker ")
  if [ -z "$SOCK_IN_DOCKER_GRP" ];
  then
    echo "  Assigning $DOCKER_SOCK_PATH to the docker group."
    sudo chgrp docker $DOCKER_SOCK_PATH
    error_check
    echo "  $DOCKER_SOCK_PATH assigned to docker group."
  else
    echo "  $DOCKER_SOCK_PATH belongs to docker group."
  fi

  # If the docker group does not have write permission to docker.sock add it.
  DOCKER_GRP_RW_SOCK=$(ls -lH $DOCKER_SOCK_PATH | cut -c 5-6 | grep "rw")
  if [ -z "$DOCKER_GRP_RW_SOCK" ];
  then
    echo "  Granting docker group RW access to $DOCKER_SOCK_PATH."
    sudo chmod g+rw $DOCKER_SOCK_PATH
    error_check
    echo "  docker group granted RW access to $DOCKER_SOCK_PATH."
  else 
    echo "  docker group has RW access to $DOCKER_SOCK_PATH."
  fi

  echo "Configuring FarmData2 group (fd2grp)..."
  # If group fd2grp does not exist on host create it
  FD2GRP_EXISTS=$(grep "fd2grp" /etc/group)
  if [ -z "$FD2GRP_EXISTS" ];
  then
    echo "  Creating fd2grp group on host."
    FD2GRP_GID=$(cat "$SCRIPT_DIR"/fd2grp.gid)
    FD2GRP_GID_EXISTS=$(grep ":$FD2GRP_GID:" /etc/group)
    if [ -n "$FD2GRP_GID_EXISTS" ];
    then
      echo "Attempted to create the fd2grp with GID=$FD2GRP_GID."
      echo "Host machine already has a group with that GID."
      echo "Change the group number in docker/dev/f2grp.gid to an unused GID."
      echo "Then run ./fd2-up.bash again."
      exit -1
    fi

    sudo -S groupadd --gid $FD2GRP_GID fd2grp
    error_check
    echo "  fd2grp group created on host with GID=$FD2GRP_GID."
  else
    FD2GRP_GID=$(getent group fd2grp | cut -d: -f3)
    echo "  fd2grp group exists on host with GID=$FD2GRP_GID."
  fi

  # If the current user is not in the fd2grp then add them.
  USER_IN_FD2GRP=$(groups | grep "fd2grp")
  if [ -z "$USER_IN_FD2GRP" ];
  then
    echo "  Adding user $(id -un) to the fd2grp group."
    sudo usermod -a -G fd2grp $(id -un)
    error_check
    echo "  User user $(id -un) added to the fd2grp group."
    echo "  ***"
    echo "  *** Run the fd2-up.bash script again to continue."
    echo "  ***"
    exec newgrp fd2grp
  else
    echo "  User $(id -un) is in fd2grp group."
  fi

  # If the FarmData2 directory is not in the fd2grp then set it.
  FD2GRP_OWNS_FD2=$(ls -ld ../../$FD2_DIR | grep " fd2grp ")
  if [ -z "$FD2GRP_OWNS_FD2" ];
  then
    echo "  Assigning $FD2_DIR to the fd2grp group."
    sudo chgrp -R fd2grp ../../$FD2_DIR
    error_check
    echo "  $FD2_DIR assigned to the fd2grp group."
  else
    echo "  $FD2_DIR is in fd2grp group."
  fi

  # If the fd2grp does not have RW access to FarmData2 change it.
  FD2GRP_RW_FD2=$(ls -ld ../../$FD2_DIR | cut -c 5-6 | grep "rw")
  if [ -z "$FD2GRP_RW_FD2" ];
  then
    echo "  Granting fd2grp RW access to $FD2_DIR."
    sudo chmod -R g+rw ../../$FD2_DIR
    error_check
    echo "  fd2grp granted RW access to $FD2_DIR."
  else
    echo "  fd2grp has RW access to $FD2_DIR."
  fi
fi

# Put GID's of docker and fd2grp groups into files in ~/.fd2gids on host.
# This directory is mounted into the dev container as ~/.fd2gids:/home/fd2dev/.contconf/gids.
# These GIDs will be used by the startup.bash script in the dev container
# to ensure that the fd2dev user in the container has permissions to
# RW FarmData2 and /var/run/docker.sock.
echo "Preparing to pass GID's to the dev container..."

if [ "$PROFILE" == "macos" ];
then
  # For macos use default values because they do not
  # have to match the host.
  FD2GRP_GID=$(cat fd2grp.gid)
  DOCKER_GRP_GID=$(( $FD2GRP_GID + 1 ))
else
  # For linux or WSL use the values that were obtained above so that
  # those in the container match those on the host.
  DOCKER_GRP_GID=$(cat /etc/group | grep "^docker:" | cut -d':' -f3)
  FD2GRP_GID=$(cat /etc/group | grep "^fd2grp:" | cut -d':' -f3)
fi

echo "  The docker GID=$DOCKER_GRP_GID."
echo "  The fd2grp GID=$FD2GRP_GID."

rm -rf ~/.fd2gids &> /dev/null
mkdir ~/.fd2gids
echo "$FD2GRP_GID" > ~/.fd2gids/fd2grp.gid
echo "$DOCKER_GRP_GID" > ~/.fd2gids/docker.gid 

# Now finally... actually start the containers...

# Delete any of the existing containers.
echo "Removing any stale containers..."
docker rm fd2_postgres &> /dev/null
docker rm fd2_farmos &> /dev/null
docker rm fd2_dev &> /dev/null

echo "Starting containers..."
# Note: Any command line args are passed to the docker-compose up command
docker compose --profile $PROFILE up -d "$@"

echo "Clearing drupal cache..."
sleep 3  # give site time to come up before clearing the cache.
docker exec -it fd2_farmos drush cr

echo "FarmData2 started."
