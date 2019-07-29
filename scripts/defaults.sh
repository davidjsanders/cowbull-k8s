STORAGE_CLASS="local-storage"
SOURCE_REGISTRY="dsanderscan"
TARGET_REGISTRY="k8s-master:32081"
STORAGE="\/datadrive\/redis"
ACTION="load.sh"
COWBULL_WEBAPP_VERSION="2.0.10"
COWBULL_VERSION="2.1.24"
LBIP=$(cat ~/lbip.txt | grep "export LBIP" | cut -d'=' -f2)

# Define variables and defaults
host_number=$(cut -d'-' -f7 <<< `hostname`)
redis_uid=999
redis_gid=999
redis_tag="5.0.5-alpine3.10"

