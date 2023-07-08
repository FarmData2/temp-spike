#!/bin/bash

# Define to disable some checks when testing.
TESTING=

PWD="$(pwd)"

# The name of the directory in which the user ran the script.
# This will also be the name of the module (e.g. farm_fd2)
MODULE_NAME=$(basename "$PWD") 

# Get the path to the main repo directory.
SCRIPT_PATH=$(readlink -f $0)  # Path to this script.
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")  # Path to directory containing this script.
MAIN_DIR=$(builtin cd "$SCRIPT_DIR/.." && pwd) # Project root directory.

# shellcheck source=./colors.bash
source "$SCRIPT_DIR/colors.bash"

# Check that the main branch is checked out
BRANCH=$(git branch)
if [[ ! "$BRANCH" == *"* main"* ]]
then
    echo -e "${ON_RED}ERROR:${NO_COLOR} You must have the main branch checked out to add an entry point."
    echo -e "Switch to the main branch."
    echo -e "Then run this script again."
    exit 255
fi

# Don't check this git conditions if testing.
if [ -z ${TESTING+x} ]
then 
    # Check that working tree is clean
    STATUS=$(git status | tail -1)
    if [[ ! "$STATUS" =~ ^"nothing to commit, working tree clean"$ ]]
    then
        echo -e "${ON_RED}ERROR:${NO_COLOR} The working tree must be clean to add an entry point."
        echo -e "Commit chagnes to a feature branch or use git stash."
        echo -e "Then run this script again."
        exit 255
    fi
fi

# Get the module to which the endpoint should be added.
MODULES=("farm_fd2" "farm_fd2_examples" "farm_fd2_school")

echo -e "Choose the module in which an entry point should be created."
select MODULE_NAME in "${MODULES[@]}"
do
    if (( "$REPLY" <= 0 || "$REPLY" > "${#MODULES[@]}" ))
    then
        echo -e "Invalid choice. Please try again."
    else
        break
    fi
done

cd "$MAIN_DIR/modules/$MODULE_NAME"
echo -e "Adding an ${UNDERLINE_GREEN}entry point${NO_COLOR} to ${UNDERLINE_GREEN}$MODULE_NAME${NO_COLOR}."
echo -e ""
read -rp "Name for new entry point (snake_case): " ENTRY_POINT

# Define the module .yml file paths for convenience.
ROUTING_YML_FILE="src/module/$MODULE_NAME.routing.yml"
LINKS_YML_FILE="src/module/$MODULE_NAME.links.menu.yml"
LIBRARIES_YML_FILE="src/module/$MODULE_NAME.libraries.yml"

# Check that the entry point is not already defined.
IN_ROUTES=$(grep "^farm.fd2_$ENTRY_POINT.content:$" "$ROUTING_YML_FILE")
IN_LINKS=$(grep "^farm.fd2_$ENTRY_POINT:$" "$LINKS_YML_FILE")
IN_LIBRARIES=$(grep "^$ENTRY_POINT:$" "$LIBRARIES_YML_FILE")

if [[ ! ("$IN_ROUTES" == "" && "$IN_LINKS" == "" && "$IN_LIBRARIES" == "") ]]
then
    echo -e "${ON_RED}ERROR:${NO_COLOR} The entry point $ENTRY_POINT is already defined."
    echo -e "Pick a different name for your entry point."
    echo -e "Or remove definitions realated to the entry point $ENTRY_POINT from the files:"
    echo -e "  $ROUTING_YML_FILE"
    echo -e "  $LINKS_YML_FILE"
    echo -e "  $LIBRARIES_YML_FILE"
    echo -e "Then run this script again."
fi

exit 1

# Define the route that will be used for the entyrpoint in farmOS
ROUTE="fd2/$ENTRY_POINT"

# Get a title and a description for the farmOS drupal module.
echo -e "Enter a title (2-5 words) for the entry point."
read -r ENTRY_POINT_TITLE
echo -e "Enter a short (one 5-10 word sentence) description of the entry point."
read -r ENTRY_POINT_DESCRIPTION

# Get the possible menus on which to post the entry point and 
# ask the user to pick one.
MENUS_RAW=$(grep "parent:" "$LINKS_YML_FILE" | cut -f2 -d: | tr '\n' ' ')
IFS=$' ' read -r -a MENUS <<< "$MENUS_RAW"

echo -e "Choose the parent menu on which this entry point will appear."
select ENTRY_POINT_PARENT in "${MENUS[@]}"
do
    if (( "$REPLY" <= 0 || "$REPLY" > "${#MENUS[@]}" ))
    then
        echo -e "Invalid choice. Please try again."
    else
        break
    fi
done

# Permissions - ????

# Create a new branch
BRANCH_NAME="add_$ENTRY_POINT""_entry_point"
git branch "$BRANCH_NAME"
git switch "$BRANCH_NAME"

# Make the directory for the entrypoint and populate it with the template files.
ENTRY_POINT_DIR="$PWD/src/entrypoints/$ENTRY_POINT"
mkdir "$ENTRY_POINT_DIR"

cp "$SCRIPT_DIR/templates/entrypoints/App.vue" "$ENTRY_POINT_DIR"
sed -i "s/%ENTRY_POINT%/$ENTRY_POINT/g" "$ENTRY_POINT_DIR/App.vue"
cp "$SCRIPT_DIR/templates/entrypoints/entry_point.exists.cy.js" "$ENTRY_POINT_DIR/$ENTRY_POINT.exists.cy.js"
sed -i "s/%ENTRY_POINT%/$ENTRY_POINT/g" "$ENTRY_POINT_DIR/$ENTRY_POINT.exists.cy.js"
cp "$SCRIPT_DIR/templates/entrypoints/entry_point.html" "$ENTRY_POINT_DIR/$ENTRY_POINT.html"
sed -i "s/%ENTRY_POINT_TITLE%/$ENTRY_POINT_TITLE/g" "$ENTRY_POINT_DIR/$ENTRY_POINT.html"
sed -i "s/%ENTRY_POINT%/$ENTRY_POINT/g" "$ENTRY_POINT_DIR/$ENTRY_POINT.html"
cp "$SCRIPT_DIR/templates/entrypoints/entry_point.js" "$ENTRY_POINT_DIR/$ENTRY_POINT.js"

# Make the new entry point into a drupal Module by adding to the
# libraries, links.menu and routing  yml files.
cat "$SCRIPT_DIR/templates/entrypoints/libraries.yml" >> "$LIBRARIES_YML_FILE"
sed -i "s/%ENTRY_POINT%/$ENTRY_POINT/g" "$LIBRARIES_YML_FILE"

cat "$SCRIPT_DIR/templates/entrypoints/links.menu.yml" >> "$LINKS_YML_FILE"
sed -i "s/%ENTRY_POINT_TITLE%/$ENTRY_POINT_TITLE/g" "$LINKS_YML_FILE"
sed -i "s/%ENTRY_POINT_DESCRIPTION%/$ENTRY_POINT_DESCRIPTION/g" "$LINKS_YML_FILE"
sed -i "s/%ENTRY_POINT_PARENT%/$ENTRY_POINT_PARENT/g" "$LINKS_YML_FILE"
sed -i "s/%ENTRY_POINT%/$ENTRY_POINT/g" "$LINKS_YML_FILE"

cat "$SCRIPT_DIR/templates/entrypoints/routing.yml" >> "$ROUTING_YML_FILE"
sed -i "s/%ENTRY_POINT_TITLE%/$ENTRY_POINT_TITLE/g" "$ROUTING_YML_FILE"
sed -i "s/%ENTRY_POINT%/$ENTRY_POINT/g" "$ROUTING_YML_FILE"

# Run a build...

# Clear drupal cache

# Run existence tests...

# Print a message...

