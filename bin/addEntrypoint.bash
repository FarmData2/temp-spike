#!/bin/bash

PWD="$(pwd)"

# Directory that should be holding the app to add the entry point to.
APP_DIR=$(basename "$PWD") 

# Get the path to the main repo directory.
SCRIPT_PATH=$(readlink -f $0)  # Path to this script.
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")  # Path to directory containing this script.
MAIN_DIR=$(builtin cd "$SCRIPT_DIR/.." && pwd) # Project root directory.

# shellcheck source=./colors.bash
source $SCRIPT_DIR/colors.bash

# Check if script was run from a valid location.
APPS=" farm_fd2 farm_fd2_example farm_fd2_school "
if [[ ! "$APPS" =~ $APP_DIR ]]
then
    echo -e "${ON_RED}ERROR:${NO_COLOR} This script must be run in a directory containing a farm_fd2 module."
    echo -e "It was run in: $PWD"
    echo -e "The valid directories are:"
    echo -e "  farm_fd2"
    echo -e "  farm_fd2_example"
    echo -e "  farm_fd2_school"
    echo -e ""
    echo -e "Change to the directory contianing the module you want to add an entry point to."
    echo -e "Then run this script again."
    exit 255
fi

# Check that the main branch is checked out
BRANCH=$(git branch)
if [[ ! "$BRANCH" =~ ^"* main" ]]
then
    echo -e "${ON_RED}ERROR:${NO_COLOR} You must have the main branch checked out to add an entry point."
    echo -e "Switch to the main branch."
    echo -e "Then run this script again."
    exit 255
fi

# Check that working tree is clean
STATUS=$(git status | tail -1)
if [[ ! "$STATUS" =~ ^"nothing to commit, working tree clean"$ ]]
then
    echo -e "${ON_RED}ERROR:${NO_COLOR} The working tree must be clean to add an entry point."
    echo -e "Commit chagnes to a feature branch or use git stash."
    echo -e "Then run this script again."
    exit 255
fi

echo -e "Adding an ${UNDERLINE_GREEN}entry point${NO_COLOR} to ${UNDERLINE_GREEN}$APP_DIR${NO_COLOR}."
echo -e ""
read -rp "Name for new entry point (snake_case): " ENTRY_POINT

# Define the module .yml files for convenience.
ROUTE_YML_FILE="src/module/$APP_DIR.routing.yml"
LINKS_YML_FILE="src/module/$APP_DIR.links.menu.yml"
LIBRARY_YML_FILE="src/module/$APP_DIR.libraries.yml"

# Check that the entry point is not already defined.
IN_ROUTES=$(grep $ROUTE_YML_FILE "^farm.farm_$ENTRY_POINT.content:$")

if [[ ! "$IN_ROUTES" = "" ]]
then
    echo -e "${ON_RED}ERROR:${NO_COLOR} The entry point $ENTRY_POINT is already defined."
    echo -e "Pick a different name for your entry point.
    echo -e "Or remove definitions realated to the entry point $ENTRY_POINT from the files:"
    echo -e "  $ROUTE_YML_FILE"
    echo -e "  $LINKS_YML_FILE"
    echo -e "  $LIBRARIES_YML_FLIE"
    echo -e "Then run this script again."
fi

echo "$ENTRY_POINT"

# Get entry point information
  # Name - One word all lowercase
  # Route - fd2/name  - generate this.
  # Title - Descriptive sentence...
  # Permissions - ????

#read var

# verify entry point doesn't exist (check for dir)
# verify route doesn't exist (check routing.yml)

# Create a new branch

# Create a new entry point

# make the directory
# populate with stock App.vue, .html, .js, .cy.js
  # .html, .js and .cy.js need to be updated
  # use sed?

# Add to the end of 
# links.menu.yml
# routing.yml
# libraries.yml

# clear drupal cache

