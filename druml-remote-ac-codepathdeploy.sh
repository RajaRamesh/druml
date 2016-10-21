#!/bin/bash

# Get Druml dir.
SCRIPT_DIR=$1
shift

# Load includes.
source $SCRIPT_DIR/druml-inc-init.sh

# Display help.
if [[ ${#ARG[@]} -lt 2 || -n $PARAM_HELP ]]
then
  echo "usage: druml remote-ac-codepathdeploy [--config=<path>] [--docroot=<path>]"
  echo "                                      [--server=<number>]"
  echo "                                      <environment> <branch>|tags/<tag>"

  exit 1
fi

# Read parameters.
SUBSITE=$PARAM_SITE
ENV=$(get_environment ${ARG[1]})
TAG=${ARG[2]}

# Set variables.
DRUSH=$(get_drush_command)
DRUSH_ALIAS=$(get_drush_alias $ENV)
SSH_ARGS=$(get_ssh_args $ENV $PARAM_SERVER)
PROXY_PARAM_SERVER=$(get_param_proxy "server")

# Say Hello.
echo "=== Deploy '$TAG' tag/branch to $ENV"
echo ""

OUTPUT=$(ssh -Tn $SSH_ARGS "$DRUSH $DRUSH_ALIAS ac-code-path-deploy $TAG" 2>&1)
RESULT="$?"
TASK=$(echo $OUTPUT | awk '{print $2}')

# Eixt upon an error.
if [[ $RESULT > 0 ]]; then
  echo "Error deploying code."
  exit 1
fi
echo "$OUTPUT"
echo "Code deployment scheduled."

# Check task status.
run_script remote-ac-status $PROXY_PARAM_SERVER $ENV $TASK
if [[ $? > 0 ]]; then
  echo "Code deployment failed!"
  exit 1
fi

echo "Code deployment completed!"
