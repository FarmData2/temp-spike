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
REPO_ROOT_DIR=$(builtin cd "$SCRIPT_DIR/.." && pwd) # REPO root directory.

# shellcheck source=./colors.bash
source "$SCRIPT_DIR/colors.bash"

# Don't check this git conditions if testing.
if [ -z ${TESTING+x} ]
then 
    # Check that the main branch is checked out
    CUR_GIT_BRANCH=$(git branch)
    if [[ ! "$CUR_GIT_BRANCH" == *"* main"* ]]
    then
        echo -e "${ON_RED}ERROR:${NO_COLOR} You must have the main branch checked out to add an entry point."
        echo -e "Switch to the main branch."
        echo -e "Then run this script again."
        exit 255
    fi
fi

# Check that working tree is clean
GIT_STATUS=$(git status | tail -1)
if [[ ! "$GIT_STATUS" =~ ^"nothing to commit, working tree clean"$ ]]
then
    echo -e "${ON_RED}ERROR:${NO_COLOR} The working tree must be clean to add an entry point."
    echo -e "Commit chagnes to a feature branch or use git stash."
    echo -e "Then run this script again."
    exit 255
fi

# Get the module to which the endpoint should be added.
ALLOWED_MODULES=("farm_fd2" "farm_fd2_examples" "farm_fd2_school")
echo -e "Choose the module in which an entry point should be created."
select MODULE_NAME in "${ALLOWED_MODULES[@]}"
do
    if (( "$REPLY" <= 0 || "$REPLY" > "${#ALLOWED_MODULES[@]}" ))
    then
        echo -e "${ON_RED}ERROR:${NO_COLOR} Invalid choice. Please try again."
    else
        break
    fi
done
DRUPAL_ROUTE_PREFIX="${MODULE_NAME:5}"
echo -e ""

# Switch to the directory for the module to which the entry point is being added.
MODULE_DIR="$REPO_ROOT_DIR/modules/$MODULE_NAME"
cd "$MODULE_DIR" 2> /dev/null || ( \
    echo -e "${ON_RED}ERROR:${NO_COLOR} Directory modules/$MODULE_NAME is missisng."; \
    echo -e "Restore this directory and try again."; \
    exit 255 ) || exit 255

# Get the name for the new entry point.
read -rp "Name for new entry point (snake_case): " ENTRY_POINT
echo -e ""

DRUPAL_ROUTE="$DRUPAL_ROUTE_PREFIX""\/$ENTRY_POINT"
ENTRY_POINT_SRC_DIR="$MODULE_DIR/src/entrypoints/$ENTRY_POINT"
ENTRY_POINT_TEMPLATE_DIR="$SCRIPT_DIR/templates/entrypoints"
DRUPAL_ROUTE_NAME="$DRUPAL_ROUTE_PREFIX""_$ENTRY_POINT"
FEATURE_BRANCH_NAME="add_$ENTRY_POINT""_entry_point"

# Check if a feature branch already exists for the entry point...
FEATURE_BRANCH_EXISTS=$(git branch -a | grep "$FEATURE_BRANCH_NAME")
if [[ ! "$FEATURE_BRANCH_EXISTS" == "" ]]
then
  echo -e "${ON_RED}ERROR:${NO_COLOR} The feature branch $FEATURE_BRANCH_NAME already exists."
  echo -e "Pick a different name for your entry point."
  echo -e "Or delete the feature branch $FEATURE_BRANCH_NAME."
  echo -e "Then run this script again."
  exit 255
fi

# Check if the directory for the entry point exits...
if [ -d "src/entrypoints/$ENTRY_POINT" ]
then
    echo -e "${ON_RED}ERROR:${NO_COLOR} A directory for the entry point $ENTRY_POINT already exists"
    echo -e "in the directory $$ENTRY_POINT_SRC_DIR."
    echo -e "Pick a different name for your entry point."
    echo -e "OR:"
    echo -e "  Remove the src/entrypoints/$ENTRY_POINT directory"
    echo -e "  And remove any definitions realated to the entry point $ENTRY_POINT from the files:"
    echo -e "    $ROUTING_YML_FILE"
    echo -e "    $LINKS_YML_FILE"
    echo -e "    $LIBRARIES_YML_FILE"
    echo -e "Then run this script again."
    exit 255
fi

# Define the module .yml file paths for convenience.
ROUTING_YML_FILE="src/module/$MODULE_NAME.routing.yml"
LINKS_YML_FILE="src/module/$MODULE_NAME.links.menu.yml"
LIBRARIES_YML_FILE="src/module/$MODULE_NAME.libraries.yml"

# Check that the entry point is not already defined.
IN_ROUTES=$(grep "^farm.fd2_$ENTRY_POINT.content:$" "$ROUTING_YML_FILE")
IN_LINKS=$(grep "^farm.fd2_$ENTRY_POINT:$" "$LINKS_YML_FILE")
IN_LIBRARIES=$(grep "^$ENTRY_POINT:$" "$LIBRARIES_YML_FILE")

# The directory for the entry point does not exist.
# So now check if the entry point has information in any of the .yml files.
if [[ ! ("$IN_ROUTES" == "" && "$IN_LINKS" == "" && "$IN_LIBRARIES" == "") ]]
then
    echo -e "${ON_RED}ERROR:${NO_COLOR} The entry point $ENTRY_POINT was previously defined."
    echo -e "Remove definitions realated to the entry point $ENTRY_POINT from the files:"
    echo -e "  $ROUTING_YML_FILE"
    echo -e "  $LINKS_YML_FILE"
    echo -e "  $LIBRARIES_YML_FILE"
    echo -e "Then run this script again."
    exit 255
fi

# Get a title and a description for the farmOS drupal module.
echo -e "Enter a title (2-5 words) for the entry point."
read -r ENTRY_POINT_TITLE
echo -e ""
echo -e "Enter a short (one 5-10 word sentence) description of the entry point."
read -r ENTRY_POINT_DESCRIPTION
echo -e ""

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
echo -e ""


# ****
# *** NEED TO DEAL WITH Permissions - ????
# ***

# shellcheck disable=SC1003
DISPLAY_DRUPAL_ROUTE=$(echo "$DRUPAL_ROUTE"| tr -d '\\')

echo -e "About to add an entry point as follows:"
echo -e "               in module: $MODULE_NAME"
echo -e "        module direcotry: $MODULE_DIR"
echo -e "        entry point name: $ENTRY_POINT"
echo -e "   entry point directory: $ENTRY_POINT_SRC_DIR"
echo -e "      template directory: $ENTRY_POINT_TEMPLATE_DIR"
echo -e "                   title: $ENTRY_POINT_TITLE"
echo -e "             description: $ENTRY_POINT_DESCRIPTION"
echo -e "            drupal route: $DISPLAY_DRUPAL_ROUTE"
echo -e "       drupal route name: $DRUPAL_ROUTE_NAME"
echo ""

# Confirm that the entry point should be created.
Y_N=""
while  [[ "$Y_N" != "Y" && "$Y_N" != "y" ]]
do 
    read -rp "Continue (Y/N)? " Y_N
    echo -e ""

    if [[ "$Y_N" == "n" || "$Y_N" == "N" ]]
    then
        echo -e "Entry point creation canceled."
        exit 255
    fi
done

# Create a new feature branch for the entry point.
git branch "$FEATURE_BRANCH_NAME"
echo -e "Created feature branch '$FEATURE_BRANCH_NAME"
git switch "$FEATURE_BRANCH_NAME"
echo -e ""

# Make the directory for the entrypoint and populate it with the template files.
mkdir "$ENTRY_POINT_SRC_DIR"
echo -e "Created entry point directory '$ENTRY_POINT_SRC_DIR"

cp "$ENTRY_POINT_TEMPLATE_DIR/App.vue" "$ENTRY_POINT_SRC_DIR"
sed -i "s/%ENTRY_POINT%/$ENTRY_POINT/g" "$ENTRY_POINT_SRC_DIR/App.vue"
echo -e "Added $ENTRY_POINT_SRC_DIR/App.vue from templates."

cp "$ENTRY_POINT_TEMPLATE_DIR/entry_point.exists.cy.js" "$ENTRY_POINT_SRC_DIR/$ENTRY_POINT.exists.cy.js"
sed -i "s/%ENTRY_POINT%/$ENTRY_POINT/g" "$ENTRY_POINT_SRC_DIR/$ENTRY_POINT.exists.cy.js"
echo -e "Added $ENTRY_POINT_SRC_DIR/$ENTRY_POINT.exists.cy.js from templates."

cp "$ENTRY_POINT_TEMPLATE_DIR/entry_point.html" "$ENTRY_POINT_SRC_DIR/$ENTRY_POINT.html"
sed -i "s/%ENTRY_POINT_TITLE%/$ENTRY_POINT_TITLE/g" "$ENTRY_POINT_SRC_DIR/$ENTRY_POINT.html"
sed -i "s/%ENTRY_POINT%/$ENTRY_POINT/g" "$ENTRY_POINT_SRC_DIR/$ENTRY_POINT.html"
echo -e "Added $ENTRY_POINT_SRC_DIR/$ENTRY_POINT.html from templates."

cp "$ENTRY_POINT_TEMPLATE_DIR/entry_point.js" "$ENTRY_POINT_SRC_DIR/$ENTRY_POINT.js"
echo -e "Added $ENTRY_POINT_SRC_DIR/$ENTRY_POINT.js from templates."

# Make the new entry point into a drupal Module by adding to the
# libraries, links.menu and routing  yml files.
cat "$ENTRY_POINT_TEMPLATE_DIR/libraries.yml" >> "$LIBRARIES_YML_FILE"
sed -i "s/%ENTRY_POINT%/$ENTRY_POINT/g" "$LIBRARIES_YML_FILE"
echo -e "Updated $LIBRARIES_YML_FILE from templates."

cat "$ENTRY_POINT_TEMPLATE_DIR/links.menu.yml" >> "$LINKS_YML_FILE"
sed -i "s/%ENTRY_POINT_TITLE%/$ENTRY_POINT_TITLE/g" "$LINKS_YML_FILE"
sed -i "s/%ENTRY_POINT_DESCRIPTION%/$ENTRY_POINT_DESCRIPTION/g" "$LINKS_YML_FILE"
sed -i "s/%ENTRY_POINT_PARENT%/$ENTRY_POINT_PARENT/g" "$LINKS_YML_FILE"
sed -i "s/%ENTRY_POINT%/$ENTRY_POINT/g" "$LINKS_YML_FILE"
echo -e "Updated $LINKS_YML_FILE from templates."

cat "$ENTRY_POINT_TEMPLATE_DIR/routing.yml" >> "$ROUTING_YML_FILE"
sed -i "s/%DRUPAL_ROUTE_NAME%/$DRUPAL_ROUTE_NAME/g" "$ROUTING_YML_FILE"
sed -i "s/%DRUPAL_ROUTE%/$DRUPAL_ROUTE/g" "$ROUTING_YML_FILE"
sed -i "s/%ENTRY_POINT_TITLE%/$ENTRY_POINT_TITLE/g" "$ROUTING_YML_FILE"
echo -e "Updated $ROUTING_YML_FILE from templates."

# Build the drupal module...
npm run build:"$DRUPAL_ROUTE_PREFIX"

# Clear drupal cache

# Run existence tests...

# Print a message...

