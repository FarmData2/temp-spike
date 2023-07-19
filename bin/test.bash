#!/bin/bash

source colors.bash
source lib.bash

function usage {
  echo "test.bash usage:"
  echo "  -h|--help : Display this message."
  echo ""
  echo "  Exactly one of the following must be included:"
  echo "    -e|--e2e  : Run end-to-end tests."
  echo "    -c|--comp : Run component tests."
  echo "    -u|--unit : Run unit tests."
  echo ""
  echo "  -i|--gui  : Include to run tests within the Cypress GUI test runner."
  echo "              NOTE: if -i|--gui is used with -p|--prev or -l|--live then"
  echo "                    the distribution will be watched and rebuilt when changes"
  echo "                    are made to the app."
  echo ""
  echo "  If --e2e is specified then exactly one of the following must be included:"
  echo "    -f|--fd2               : Run all of the e2e tests in the fd2 module."
  echo "    -x|--examples          : RUn all of the e2e tests in the examples module."
  echo "    -s|--school            : Run all of the e2e tests in the fd2 school module."
  echo "    -g<glob>|--glob=<glob> : Run only the e2e tests matching the glob."
  echo "                             Note: <glob> is specified relative to the root of the repo."
  echo ""
  echo "  If --e2e is specified then exactly one of the following must be included:"
  echo "    -d|--dev  : Run the e2e tests in the dev environment."
  echo "    -p|--prev : Do a bulid and run the e2e tests in the preview environment."
  echo "    -l|--live : Do a build and run e2e tests using the farmOS server"
  echo ""
  echo "  If --comp or --unit are specified then the following may be included:"
  echo "    -g<glob>|--glob=<glob>: Run only the component or unit tests matching the glob."
  echo "                            Note: <glob> is specified relative to the root of the repo."
  echo ""

  exit 255
}

# Change into the main repo directory.
SCRIPT_PATH=$(readlink -f $0)                       # Path to this script.
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")                # Path to directory containing this script.
REPO_ROOT_DIR=$(builtin cd "$SCRIPT_DIR/.." && pwd) # REPO root directory.
safe_cd "$REPO_ROOT_DIR"

# Process the command line flags
FLAGS=$(getopt -o e::c::u::i::g::h::f::x::s::d::p::l:: \
  --long e2e::,comp::,unit::,gui::,fd2::,examples::,school::,glob::,dev::,prev::,live::,help:: \
  -- "$@")
eval set -- "$FLAGS"

while true; do
  case $1 in
    -e | --e2e)
      E2E_TESTS=1
      shift 2
      ;;
    -c | --comp)
      COMPONENT_TESTS=1
      shift 2
      ;;
    -u | --unit)
      UNIT_TESTS=1
      shift 2
      ;;
    -i | --gui)
      CYPRESS_GUI=1
      shift 2
      ;;
    -f | --fd2)
      TEST_FD2=1
      shift 2
      ;;
    -x | --examples)
      TEST_EXAMPLES=1
      shift 2
      ;;
    -s | --school)
      TEST_SCHOOL=1
      shift 2
      ;;
    -g | --glob)
      if [ "$2" == "" ]; then
        echo -e "${ON_RED}ERROR:${NO_COLOR} -g|--glob requres an argument."
        echo "Use test.bash --help for usage information"
        exit 255
      fi
      SPEC_GLOB=$2
      shift 2
      ;;
    -d | --dev)
      DEV_SERVER=1
      shift 2
      ;;
    -p | --prev)
      PREVIEW_SERVER=1
      shift 2
      ;;
    -l | --live)
      LIVE_FARMOS_SERVER=1
      shift 2
      ;;
    -h | --help)
      usage
      ;;
    --)
      shift
      break
      ;;
    *)
      usage
      ;;
  esac
done

# Make sure only one of -e|--e2e or -c|--comp or -u|--unit is specified.
if ! xor "$E2E_TESTS" "$COMPONENT_TESTS" "$UNIT_TESTS"; then
  echo -e "${ON_RED}ERROR:${NO_COLOR} Exactly one of -e|--e2e, -c|--comp or -u|--unit must be included."
  echo "Use test.bash --help for usage information"
  exit 255
fi

# -e|--e2e was specified so make sure that:
#   Only one of -f|--fd2 or -x|--examples or -s|--school is specified
#   and
#   only one of -d|-dev or -p|--preveiw or -l|--live  is specified
if [ -n "$E2E_TESTS" ]; then
  if ! xor "$TEST_FD2" "$TEST_EXAMPLES" "$TEST_SCHOOL"; then
    echo -e "${ON_RED}ERROR:${NO_COLOR} When -e|--e2e is specified, exactly one of -f|--fd2, -x|--examples or -s|--school must be included."
    echo "Use test.bash --help for usage information"
    exit 255
  fi

  if ! xor "$DEV_SERVER" "$PREVIEW_SERVER" "$LIVE_FARMOS_SERVER"; then
    echo -e "${ON_RED}ERROR:${NO_COLOR} When -e|--e2e is specified, exactly one of -d|--dev, -p|--prev or -l|--live must be included."
    echo "Use test.bash --help for usage information"
    exit 255
  fi
fi

# Setup to run e2e or component/unit tests.
if [ -n "$E2E_TESTS" ]; then
  echo "End-to-end testing requested."
  CYPRESS_TEST_TYPE="e2e"
  if [ -n "$TEST_FD2" ]; then
    echo "  Testing the farm_fd2 module."
    CYPRESS_PROJECT="modules/farm_fd2"
  elif [ -n "$TEST_EXAMPLES" ]; then
    echo "  Testing the farm_fd2_examples module."
    CYPRESS_PROJECT="modules/farm_fd2_examples"
  else
    echo "  Testing the farm_fd2_schoool module."
    CYPRESS_PROJECT="modules/farm_fd2_school"
  fi
else
  CYPRESS_TEST_TYPE="component"
  CYPRESS_PROJECT="modules/farm_fd2"
  if [ -n "$COMPONENT_TESTS" ]; then
    echo "Component testing requested."
  else
    echo "Unit testing requested."
  fi
fi

# Setup to run e2e tests on the requested type of server.
if [ -n "$DEV_SERVER" ]; then
  echo "Development tests requested..."
  echo "  Checking that the dev server is running on port 5173..."
  if [ "$(check_url localhost:5173/fd2/main/)" == "" ]; then
    echo "    Dev server not found."
    echo "    Starting dev server..."
    npx vite --config ./modules/farm_fd2/vite.config.js > /dev/null &

    DEV_PID=$!
    DEV_GID=$(ps --pid "$DEV_PID" -h -o pgid | xargs)

    if [ "$(wait_for_url localhost:5173/fd2/main/)" == "" ]; then
      echo -e "    ${ON_RED}ERROR:${NO_COLOR} Unable to start dev server."
      exit 255
    else
      echo "    Dev server started in process group $DEV_GID."
    fi
  else
    echo "  Found dev server on port 5173."
  fi

  BASE_URL="http://localhost:5173/"

elif [ -n "$PREVIEW_SERVER" ]; then
  echo "Preview tests requested..."

  echo "  Starting builder for the distribution..."
  npx vite --config modules/farm_fd2/vite.config.js build --watch > /dev/null &
  BUILDER_PID=$!
  BUILDER_GID=$(ps --pid "$BUILDER_PID" -h -o pgid)
  echo "    Builder running in process group $BUILDER_GID."

  echo "  Checking that the preview server is running on port 4173..."
  if [ "$(check_url localhost:4173/fd2/main/)" == "" ]; then
    echo "    Preview server not found."
    echo "    Starting preview server..."
    npx vite --config ./modules/farm_fd2/vite.config.js preview > /dev/null &

    PREVIEW_PID=$!
    PREVIEW_GID=$(ps --pid "$PREVIEW_PID" -h -o pgid | xargs)

    if [ "$(wait_for_url localhost:4173/fd2/main/)" == "" ]; then
      echo -e "    ${ON_RED}ERROR:${NO_COLOR} Unable to start preveiw server."
      exit 255
    else
      echo "    Preview server started in process group $PREVIEW_GID."
    fi
  else
    echo "  Found preview server on port 4173."
  fi

  BASE_URL="http://localhost:4173"

elif [ -n "$LIVE_FARMOS_SERVER" ]; then
  echo "Live tests within farmOS requested..."

  echo "  Starting builder for the distribution..."
  npx vite --config modules/farm_fd2/vite.config.js build --watch > /dev/null &
  LIVE_PID=$!
  LIVE_GID=$(ps --pid "$LIVE_PID" -h -o pgid | xargs)
  echo "    Builder running in process group $LIVE_GID."

  BASE_URL="http://farmos"
fi

# Set environment variables to override the defaults as necessary.

# If a glob was specified, use it to override the default set above.
if [ -n "$SPEC_GLOB" ]; then
  FULL_GLOB="$REPO_ROOT_DIR/$SPEC_GLOB"
  export CYPRESS_SPEC_PATTERN="$FULL_GLOB"
fi

if [ -n "$BASE_URL" ]; then
  export CYPRESS_BASE_URL="$BASE_URL"
fi

# Run the tests...
safe_cd $CYPRESS_PROJECT

if [ -n "$CYPRESS_GUI" ]; then
  echo "Running test in the Cypress GUI."
  npx cypress open --"$CYPRESS_TEST_TYPE" > /dev/null
else
  echo "Running tests headless."
  npx cypress run --"$CYPRESS_TEST_TYPE"
fi

echo "Tests complete."

# If we brought up a server, then take it back down.
if [ -n "$DEV_PID" ]; then
  echo "Terminating the dev server."
  # NOTE: Normal kill without -INT or using -TERM leaves shell
  # in mode where up/down arrows give control sequences instead
  # of command history.
  kill -INT -- -"$DEV_GID"

elif [ -n "$PREVIEW_GID" ]; then
  echo "Terminating the builder and preview server."
  kill -INT -- -"$PREVIEW_GID"

elif [ -n "$LIVE_GID" ]; then
  echo "Terminating the builder."
  kill -INT -- -"$LIVE_GID"
fi