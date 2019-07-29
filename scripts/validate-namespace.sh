# Check namespace exists
temp=$(kubectl get namespaces cowbull 2> /dev/null)
ret_stat="$?"
if [ "$ret_stat" != "0" ]
then
    short_banner "Creating namespace cowbull"
    kubectl apply -f setup/10-namespace.yaml
else
    short_banner "Using existing namespace: cowbull"
fi
