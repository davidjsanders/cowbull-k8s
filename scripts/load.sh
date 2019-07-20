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

# Include the log_banner functions for logging purposes (see 
# scripts/log_banner.sh)
#
source scripts/banner.sh

log_banner "load.sh" "Loading cowbull"
usage() 
{ 
    short_banner "-s source registry (--source)"
    short_banner "-t target registry (--target)"
    short_banner "-l load-balancer-ip (--lbip)"
}

# Call getopt to validate the provided input. 
options=$(getopt -o s:t:l: -l source:target:lbip: -- "$@")
[ $? -eq 0 ] || { 
    short_banner "Incorrect options provided"
    usage
    exit 1
}

eval set -- "$options"
while true; do
    case "$1" in
    -s)
        SOURCE_REGISTRY="$2"
        shift
        ;;
    -t)
        TARGET_REGISTRY="$2"
        shift
        ;;
    -l)
        LBIP="$2"
        shift
        ;;
    --source)
        SOURCE_REGISTRY=$2
        shift
        ;;
    --target)
        TARGET_REGISTRY=$2
        shift
        ;;
    --lbip)
        LBIP=$1
        shift
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done

echo "Source registry : "$SOURCE_REGISTRY
echo "Target registry : "$TARGET_REGISTRY
echo "Load Balancer IP: "$LBIP

if [ -z ${LBIP+x} ] || [ -z ${SOURCE_REGISTRY} ] || [ -z ${TARGET_REGISTRY} ]
then
    short_banner "Unable to proceed: missing arguments"
    usage
    exit 1
fi

exit 0

echo
echo "Preparing images"
echo
source_registry="dsanderscan"
target_registry="k8s-master:32081"
images=("cowbull:2.0.119 cowbull_webapp:1.0.193")
for image in $images
do
    image_name="$source_registry/$image"
    echo "Pull $image_name from local registry"
    sudo docker pull ${target_registry}/$image
    ret_stat="$?"

    if [ "$ret_stat" != "0" ]
    then
	echo "Not found, pulling $image_name from Docker Hub"
        sudo docker pull $image_name
        echo "Tagging as $target_registry/$image"
        sudo docker tag $image_name $target_registry/$image
        echo "Pushing as $target_registry/$image"
        sudo docker push $target_registry/$image
        echo
    else
	echo
    fi
done

yaml_files=$(ls -1 /datadrive/azadmin/cowbull/[0-9]*.yaml &> /dev/null)
if [ "$?" != "0" ]
then
    short_banner "No yaml files found; skipping yaml."
else
    log_banner "load.sh" "Load cowbull yaml files"
    for file in $yaml_files
    do
        echo "Applying yaml for: $file"
        kubectl apply -f $file
        echo
    done
fi

echo
short_banner "Applying Ingress"
echo
sed 's/\${LBIP}/'"$LBIP"'/g' /datadrive/azadmin/cowbull/ingress.yaml.env | kubectl apply -f -
echo

echo
echo "Access ingress at cowbull.${LBIP}.xip.io"
echo
echo "Done."
echo

yaml_files=$(ls -1 ../yaml/[0-9]*.yaml &> /dev/null)

for file in $yaml_files
do
    short_banner "Applying yaml for: $file"
    kubectl apply -f $file
    echo
done
short_banner "Done."
echo
