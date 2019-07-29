kubectl_action="apply"

source scripts/validate-namespace.sh
source scripts/validate-configmap.sh "cowbull-config"
source scripts/validate-configmap.sh "cowbull-webapp-config"
source scripts/pull-images.sh

yaml_files=$(ls -1 yaml/[0-9]*.yaml 2> /dev/null)
log_action="Applying"

temp=$(kubectl get namespaces cowbull 2> /dev/null)
ret_stat="$?"
if [ "$ret_stat" != "0" ]
then
    short_banner "Creating namespace cowbull"
    kubectl apply -f setup/10-namespace.yaml
else
    short_banner "Using namespace cowbull"
fi
