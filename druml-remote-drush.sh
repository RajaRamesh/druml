#!/bin/bash

# Save script dir.
SCRIPT_DIR=$(cd $(dirname "$0") && pwd -P)

# Load includes.
source $SCRIPT_DIR/druml-inc-init.sh

# Display help.
if [[ ${#ARG[@]} -lt 2 || -z $PARAM_SITE || -n $PARAM_HELP ]]
then
  echo "usage: druml remote-drush [--config=<path>] [--delay=<seconds>]"
  echo "                         [--site=<subsite> | --list=<list>]"
  echo "                         <environment> <commands>"
  exit 1
fi

# Load config.
source $SCRIPT_DIR/druml-inc-config.sh

# Read parameters.
SUBSITE=$PARAM_SITE
ENV=$(get_environment ${ARG[1]})
SSH_ARGS=$(get_ssh_args $ENV)
DRUSH_ALIAS=$(get_drush_alias $ENV)
DRUSH_SUBSITE_ARGS=$(get_drush_subsite_args $SUBSITE)
shift && shift && shift

# Read commands to execute.
echo "=== Execute drush commands for '$SUBSITE' subsite on the '$ENV' environment"
echo "Commands to be executed:"

COMMANDS=""
I=1
for CMD in ${ARG[@]}
do
  if [[ $I -gt 1 && -n ${ARG[$I]} ]]
  then
    if [[ -z $COMMANDS ]]; then
      COMMANDS="drush $DRUSH_ALIAS $DRUSH_SUBSITE_ARGS ${ARG[$I]}"
    else
      COMMANDS="$COMMANDS && drush $DRUSH_ALIAS $DRUSH_SUBSITE_ARGS ${ARG[$I]}"
    fi
    echo "${ARG[$I]}"
  fi
  I=$((I+1))
done
COMMANDS="$COMMANDS;"

echo "$COMMANDS"
echo ""

# Execute drush commands.
OUTPUT=$(ssh -Tn $SSH_ARGS "$COMMANDS" 2>&1)
RESULT="$?"

echo "Result:"
echo "$OUTPUT"

# Eixt upon an error.
if [[ $RESULT > 0 ]]; then
  exit 1
fi