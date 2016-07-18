#!/bin/bash

# Save script dir.
SCRIPT_DIR=$(cd $(dirname "$0") && pwd -P)

# Load includes.
source $SCRIPT_DIR/druml-inc-init.sh

# Display help.
if [[ ${#ARG[@]} -lt 2 || -n $PARAM_HELP ]]
then
  echo "usage: druml remote-ac-command [--config=<path>] [--docroot=<path>]"
  echo "                               [--delay=<seconds>]"
  echo "                               <environment> <command>"
  exit 1
fi

# Read parameters.
SUBSITE=$PARAM_SITE
ENV=$(get_environment ${ARG[1]})
COMMAND=${ARG[2]}
DRUSH=$(get_drush_command)
DRUSH_ALIAS=$(get_drush_alias $ENV)
SSH_ARGS=$(get_ssh_args $ENV)

# Say Hello.
echo "=== Executing AC commands on $ENV"
echo ""

echo "Command to be executed:"
echo "$COMMAND"

OUTPUT=$(ssh -Tn $SSH_ARGS "$DRUSH $DRUSH_ALIAS $COMMAND" 2>&1)
RESULT="$?"
TASK=$(echo $OUTPUT | awk '{print $2}')
echo "$OUTPUT"

# Eixt upon an error.
if [[ $RESULT > 0 ]]; then
  echo "Error executing command."
  exit 1
fi
echo "$OUTPUT"
echo "Command execution scheduled."

# Check task status.
OUTPUT=$(run_script remote-ac-status $ENV $TASK 2>&1)
RESULT="$?"
echo "$OUTPUT"
if [[ $RESULT > 0 ]]; then
  echo "Command execution failed!"
  exit 1
fi

echo "Command execution completed!"