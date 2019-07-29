#!/usr/bin/env bash
# -------------------------------------------------------------------
#
# Module:         cowbull-k8s
# Submodule:      scripts/load-cowbull.sh
# Environments:   all
# Purpose:        Bash shell script to apply any yaml files found in
#                 the yaml sub-directory.
#
# Created on:     20 July 2019
# Created by:     David Sanders
# Creator email:  dsanderscanada@nospam-gmail.com
#
# -------------------------------------------------------------------
# Modifed On   | Modified By                 | Release Notes
# -------------------------------------------------------------------
# 20 Jul 2019  | David Sanders               | First release.
# -------------------------------------------------------------------
# 28 Jul 2019  | David Sanders               | Refactor and add 
#              |                             | support for app 
#              |                             | versions as args.
# -------------------------------------------------------------------

args="$@"                       # Get the command line arguments
set -o pipefail                 # Set fail on pipeline
source scripts/banner.sh        # Include the log_banner
source scripts/usage.sh         # Include the definition of the usage function
source scripts/get-options.sh   # Include the get options routines
source scripts/defaults.sh      # Set the default values.
source scripts/parse-args.sh    # Parse the command arguments

if [ "$ACTION" == "load.sh" ]
then
    source scripts/preflight-load.sh    # Preflight setup for load
else
    source scripts/preflight-delete.sh  # Preflight setup for delete
fi


source scripts/load-manifests.sh # Apply/delete the yaml manifests

storage_class="$STORAGE_CLASS"

echo
if [ "$ACTION" == "delete.sh" ]
then
    short_banner "Remember the namespace and configmaps have not been deleted!"
    short_banner "If required, delete them with: kubectl delete namespaces cowbull"
else
    source scripts/dump-values.sh   # Display the values after argument processing
fi
echo

log_banner "$ACTION" "Done."
echo
