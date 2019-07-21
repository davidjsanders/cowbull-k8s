#!/usr/bin/env bash
# -------------------------------------------------------------------
#
# Module:         cowbull-k8s
# Submodule:      scripts/load-cowbull.sh
# Environments:   all
# Purpose:        Bash shell script to apply any yaml files found in
#                 the yaml sub-directory.
#
# Created on:     21 July 2019
# Created by:     David Sanders
# Creator email:  dsanderscanada@nospam-gmail.com
#
# -------------------------------------------------------------------
# Modifed On   | Modified By                 | Release Notes
# -------------------------------------------------------------------
# 21 Jul 2019  | David Sanders               | First release.
# -------------------------------------------------------------------

# Set fail on pipeline
set -o pipefail

# Include the log_banner functions for logging purposes (see 
# scripts/log_banner.sh)
#
source scripts/banner.sh

log_banner "delete.sh" "Loading cowbull"
source scripts/process.sh "$@" --delete