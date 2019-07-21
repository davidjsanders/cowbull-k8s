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

log_banner "process.sh" "Processing cowbull"
usage() 
{ 
    short_banner "(load.sh|delete.sh) -s source -t target -l lbip -c storage-class -d path"
    short_banner "  -s source-registry (--source)"
    short_banner "  -t target-registry (--target)"
    short_banner "  -l load-balancer-ip (--lbip)"
    short_banner "  -c storage-class (--storage-class)"
}

# Call getopt to validate the provided input. 
options=$(getopt -o "s:t:l:c:" -l "load,delete,source:,target:,lbip:,storage-class:" -- "$@")
[ $? -eq 0 ] || { 
    short_banner "Incorrect options provided"
    usage
    exit 1
}

# Define defaults
#STORAGE_CLASS="local-storage"
STORAGE_CLASS="example-nfs"
DIRECTORY="/datadrive/export/cowbull/redis-data"
NFS_DIRECTORY="\/datadrive\/cowbull\/redis-data"
ACTION="load.sh"

# Define variables and defaults
host_number=$(cut -d'-' -f7 <<< `hostname`)
redis_uid=999
redis_gid=999
redis_tag="5.0.5-alpine3.10"
cowbull_webapp_version="1.0.193"
cowbull_version="2.0.119"

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
    -c | --storage-class)
        STORAGE_CLASS="$2"
        shift 2
        ;;
    --load)
        ACTION="load.sh"
        shift
        ;;
    --delete)
        ACTION="delete.sh"
        shift
        ;;
    --)
        shift
        break
        ;;
    esac
done

if [ -z ${LBIP+x} ] || \
   [ -z ${SOURCE_REGISTRY+x} ] || \
   [ -z ${TARGET_REGISTRY+x} ] || \
   [ -z ${STORAGE_CLASS+x} ]
then
    echo
    short_banner "Unable to proceed: missing required argument(s)"
    usage
    exit 1
fi

if [ "$ACTION" == "load.sh" ]
then
    kubectl_action="apply"
else
    kubectl_action="delete"
fi

echo

short_banner "Source registry : "$SOURCE_REGISTRY
short_banner "Target registry : "$TARGET_REGISTRY
short_banner "Directory path  : "$DIRECTORY
short_banner "NFS Directory   : "$NFS_DIRECTORY
short_banner "Load Balancer IP: "$LBIP
short_banner "Storage Class   : "$STORAGE_CLASS
short_banner "Hostname Number : "$host_number
short_banner "Redis GID       : "$redis_gid
short_banner "Redis UID       : "$redis_uid
short_banner "Redis tag       : "$redis_tag
short_banner "Cowbull ver.    : "$cowbull_version
short_banner "Web App ver.    : "$cowbull_webapp_version

source_registry="$SOURCE_REGISTRY"
target_registry="$TARGET_REGISTRY"
storage_class="$STORAGE_CLASS"

if [ "$ACTION" == "load.sh" ]
then
    short_banner "Preparing images; pulling from $source_registry and pushing to $target_registry"
    images=("cowbull:${cowbull_version} cowbull_webapp:${cowbull_webapp_version}")
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
fi

# echo
# if [ "$STORAGE_CLASS" == "local-storage" ]
# then
#     short_banner "Set permissions on persistent volume: "$DIRECTORY
#     sudo chown -R $redis_uid:$redis_gid $DIRECTORY
# fi

echo
if [ "$ACTION" == "load.sh" ]
then
    yaml_files=$(ls -1 yaml/[0-9]*.yaml 2> /dev/null)
else
    yaml_files=$(ls -r1 yaml/[0-9]*.yaml 2> /dev/null)
fi

if [ "$?" != "0" ]
then
    short_banner "No yaml files found; skipping yaml."
else
    for file in $yaml_files
    do
        short_banner "Applying yaml for: $file"
        sed '
            s/\${LBIP}/'"$LBIP"'/g;
            s/\${STORAGE_CLASS}/'"$storage_class"'/g;
            s/\${NFS_DIRECTORY}/'"$NFS_DIRECTORY"'/g;
            s/\${target_registry}/'"$target_registry"'/g;
            s/\${host_number}/'"$host_number"'/g;
            s/\${redis_gid}/'"$redis_gid"'/g;
            s/\${redis_uid}/'"$redis_uid"'/g;
            s/\${redis_tag}/'"$redis_tag"'/g;
            s/\${cowbull_version}/'"$cowbull_version"'/g;
            s/\${cowbull_webapp_version}/'"$cowbull_webapp_version"'/g;
            s/\${docker_hub}//g
        ' $file | kubectl $kubectl_action -f - &> /dev/null
        if [ "$?" != "0" ]
        then
            short_banner "There was an error applying $file"
        fi
    done
fi

if [ "$ACTION" == "load.sh" ]
then
    echo
    short_banner "Access ingress at cowbull.${LBIP}.xip.io"
    echo
fi

log_banner "$ACTION" "Done."
echo
