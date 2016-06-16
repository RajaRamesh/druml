#!/bin/bash

# Save script dir.
SCRIPT_DIR=$(cd $(dirname "$0") && pwd -P)

# Load includes.
source $SCRIPT_DIR/druml-inc-init.sh

# Display help.
if [[ ${#ARG[@]} -lt 2 || -z $PARAM_SITE || -n $PARAM_HELP ]]
then
  echo "usage: druml local-sitesync [--config=<path>] [--delay=<seconds>]"
  echo "                           [--site=<subsite> | --list=<list>]"
  echo "                           <environment from> <environment to>"
  exit 1
fi

# Load config.
source $SCRIPT_DIR/druml-inc-config.sh

# Read parameters.
SUBSITE=$PARAM_SITE
ENV_FROM=$(get_environment ${ARG[1]})
ENV_TO=$(get_environment ${ARG[2]})
DRUSH_ALIAS_FROM=$(get_drush_alias $ENV_FROM)
DRUSH_ALIAS_TO=$(get_drush_alias $ENV_TO)
SSH_ARGS=$(get_ssh_args $ENV_FROM)
DRUSH_SUBSITE_ARGS=$(get_drush_subsite_args $SUBSITE)

# Say Hello.
echo "=== Sync '$SUBSITE' DB from the $ENV_FROM to $ENV_TO"
echo ""

OUTPUT=$(ssh -Tn $SSH_ARGS "drush $DRUSH_ALIAS_FROM $DRUSH_SUBSITE_ARGS ac-database-copy $SUBSITE $ENV_TO" 2>&1)
RESULT="$?"
TASK=$(echo $OUTPUT | awk '{print $2}')

# Eixt upon an error.
if [[ $RESULT > 0 ]]; then
  echo "Error syncing DB."
  exit 1
fi
echo "$OUTPUT"
echo "Database sync is scheduled."

# Check task status every 20 seconds during 10 minutes.
I=0;
while [ $I -lt 120 ]; do
  OUTPUT=$(ssh -Tn $SSH_ARGS "drush $DRUSH_ALIAS_FROM ac-task-info $TASK" 2>&1)
  RESULT="$?"

  while read -r LINE; do
    KEY=$(echo $LINE | awk '{print $1}')
    VAL=$( echo $LINE | awk '{print $3}')

    if [[ "$KEY" = "state" ]]; then
        STATE=$VAL
        if [[ "$STATE" = "done" ]]; then
          echo "Database sync is complete!"
          exit 0
        fi
        if [ "$STATE" != "waiting" -a "$STATE" != "started" -a "$STATE" != "received" ]; then
          echo "Database sync is failed, state: $STATE."
          exit 1
        fi
    fi
  done <<< "$OUTPUT"
  let I=$I+20;
  sleep 20;
done

echo "Database sync is failed beause of timeout, last state: $STATE."
exit 1