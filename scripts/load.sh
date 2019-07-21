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
    short_banner "load.sh -s source -t target -l lbip -c storage-class -d path"
    short_banner "  -s source-registry (--source)"
    short_banner "  -t target-registry (--target)"
    short_banner "  -l load-balancer-ip (--lbip)"
    short_banner "  -c storage-class (--storage-class)"
    short_banner "  -d directory (--directory)"
}

# Call getopt to validate the provided input. 
options=$(getopt -o "s:t:l:c:d:" -l "source:,target:,lbip:,storage-class:,directory:" -- "$@")
[ $? -eq 0 ] || { 
    short_banner "Incorrect options provided"
    usage
    exit 1
}

STORAGE_CLASS="local-storage"
DIRECTORY="/datadrive/export/cowbull-2/redis-data"
NFS_DIRECTORY="/datadrive/cowbull-2/redis-data"
random_num=$(cut -d'-' -f7 <<< `hostname`)
redis_uid=999
redis_gid=999
redis_tag="5.0.5-alpine3.10"


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
    -d | --directory)
        DIRECTORY="$2"
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
    --)
        shift
        break
        ;;
    esac
done

short_banner "Source registry : "$SOURCE_REGISTRY
short_banner "Target registry : "$TARGET_REGISTRY
short_banner "Directory path  : "$DIRECTORY
short_banner "NFS Directory   : "$NFS_DIRECTORY
short_banner "Load Balancer IP: "$LBIP
short_banner "Storage Class   : "$STORAGE_CLASS
short_banner "Hostname Number : "$random_num
short_banner "Redis GID       : "$redis_gid
short_banner "Redis UID       : "$redis_uid
short_banner "Redis tag       : "$redis_tag

if [ -z ${LBIP+x} ] || \
   [ -z ${SOURCE_REGISTRY+x} ] || \
   [ -z ${TARGET_REGISTRY+x} ] || \
   [ -z ${STORAGE_CLASS+x} ]
then
    short_banner "Unable to proceed: missing arguments"
    usage
    exit 1
fi

echo

source_registry="$SOURCE_REGISTRY"
target_registry="$TARGET_REGISTRY"
storage_class="$STORAGE_CLASS"

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

# echo
# if [ "$STORAGE_CLASS" == "local-storage" ]
# then
#     short_banner "Set permissions on persistent volume: "$DIRECTORY
#     sudo chown -R $redis_uid:$redis_gid $DIRECTORY
# fi

echo
yaml_files=$(ls -1 yaml/[0-9]*.yaml 2> /dev/null)
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
            s/\${DIRECTORY}/'"$DIRECTORY"'/g;
            s/\${NFS_DIRECTORY}/'"$NFS_DIRECTORY"'/g;
            s/\${target_registry}/'"$target_registry"'/g;
            s/\${random_num}/'"$random_num"'/g;
            s/\${redis_gid}/'"$redis_gid"'/g;
            s/\${redis_uid}/'"$redis_uid"'/g;
            s/\${redis_tag}/'"$redis_tag"'/g;
            s/\${docker_hub}//g
        ' $file | kubectl apply -f - &> /dev/null
        if [ "$?" != "0" ]
        then
            short_banner "There was an error applying $file"
        fi
    done
fi

echo
short_banner "Access ingress at cowbull.${LBIP}.xip.io"
echo

log_banner "load.sh" "Done."
echo
