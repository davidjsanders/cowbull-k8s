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

# Set fail on pipeline
set -o pipefail

# Include the log_banner functions for logging purposes (see 
# scripts/log_banner.sh)
#
source scripts/banner.sh

log_banner "load.sh" "Loading cowbull"
usage() 
{ 
    short_banner "load.sh -s source -t target -l lbip"
    short_banner "  -s source-registry (--source)"
    short_banner "  -t target-registry (--target)"
    short_banner "  -l load-balancer-ip (--lbip)"
}

# Call getopt to validate the provided input. 
options=$(getopt -o "s:t:l:" -l "source:,target:,lbip:" -- "$@")
[ $? -eq 0 ] || { 
    short_banner "Incorrect options provided"
    usage
    exit 1
}

eval set -- "$options"
while true; do
    case "$1" in
    -s | --source)
        SOURCE_REGISTRY="$2"
        shift 2
        ;;
    -t | --target)
        TARGET_REGISTRY="$2"
        shift 2
        ;;
    -l | --lbip)
        LBIP="$2"
        shift 2
        ;;
    --)
        shift
        break
        ;;
    esac
done

short_banner "Source registry : "$SOURCE_REGISTRY
short_banner "Target registry : "$TARGET_REGISTRY
short_banner "Load Balancer IP: "$LBIP
echo

if [ -z ${LBIP+x} ] || [ -z ${SOURCE_REGISTRY} ] || [ -z ${TARGET_REGISTRY} ]
then
    short_banner "Unable to proceed: missing arguments"
    usage
    exit 1
fi

echo
source_registry="$SOURCE_REGISTRY"
target_registry="$TARGET_REGISTRY"
short_banner "Preparing images; pulling from $source_registry and pushing to $target_registry"
images=("cowbull:2.0.119 cowbull_webapp:1.0.193")
for image in $images
do
    image_name="$source_registry/$image"
    short_banner "Pull $target_registry/$image from local registry"
    sudo docker pull ${target_registry}/$image &> /dev/null
    ret_stat="$?"

    if [ "$ret_stat" != "0" ]
    then
	    short_banner "Not found, pulling $image_name from Docker Hub"
        sudo docker pull $image_name &> /dev/null
        short_banner "Tagging as $target_registry/$image"
        sudo docker tag $image_name $target_registry/$image &> /dev/null
        short_banner "Pushing as $target_registry/$image"
        sudo docker push $target_registry/$image
        echo
    fi
done

yaml_files=$(ls -1 yaml/[0-9]*.yaml 2> /dev/null)
if [ "$?" != "0" ]
then
    short_banner "No yaml files found; skipping yaml."
else
    short_banner "Processing: $yaml_files"
    for file in $yaml_files
    do
        short_banner "Applying yaml for: $file"
        sed '
            s/\${LBIP}/'"$LBIP"'/g;
            s/\${STORAGE_CLASS}/local-storage/g;
            s/\${LBIP}/'"$LBIP"'/g
        ' $file |
        kubectl apply -f $file &> /dev/null
        # if [ "$?" != "0" ]
        # then
        #     short_banner "There was an error applying $file"
        # fi
        echo
    done
fi

echo
short_banner "Applying Ingress"
ingress_file="yaml/ingress.yaml.env"
if [ ! -f $ingress_file ]
then
    short_banner "No ingress file ($ingress_file) found; skipping"
else
    sed 's/\${LBIP}/'"$LBIP"'/g' yaml/ingress.yaml.env | kubectl apply -f -
    if [ "$?" != "0" ]
    then
        short_banner "Couldn't apply Ingress; skipping"
    fi
fi
echo

echo
short_banner "Access ingress at cowbull.${LBIP}.xip.io"
echo

log_banner "load.sh" "Done."
echo
