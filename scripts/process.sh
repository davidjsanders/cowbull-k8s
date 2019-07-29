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

# Set fail on pipeline
set -o pipefail

# Include the log_banner
source scripts/banner.sh

# Include the definition of the usage function
source scripts/usage.sh

# Include the get options routines
args="$@"
source scripts/get-options.sh
# options=$(getopt -o "s:t:l:c:v:w:" -l "load,delete,source:,target:,lbip:,storage-class:,cowbull-version:,webapp-version:" -- "$@")
# ret_stat=$?
# if [ "$ret_stat" != "0" ]
# then 
#     short_banner "Incorrect options provided; exit code $ret_stat"
#     usage
#     exit 1
# fi

# Set the default values.
source scripts/defaults.sh

# Parse the command arguments
source scripts/parse-args.sh

if [ "$ACTION" == "load.sh" ]
then
    source scripts/preflight-load.sh
else
    source scripts/preflight-delete.sh
fi

# Display the values after argument processing
source scripts/dump-values.sh

# Apply/delete the yaml manifests
source scripts/load-manifests.sh

storage_class="$STORAGE_CLASS"

# Display the values after argument processing
source scripts/dump-values.sh

log_banner "$ACTION" "Done."
echo
