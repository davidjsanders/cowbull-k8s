# Check namespace exists
temp=$(kubectl get namespaces cowbull 2> /dev/null)
ret_stat="$?"
if [ "$ret_stat" != "0" ]
then
    short_banner "Creating namespace: cowbull"
    kubectl apply -f setup/10-namespace.yaml &> /dev/null
    if [ "$?" != "0" ]
    then
        short_banner "Unable to apply namespace manifest!"
        exit 1
    fi
else
    short_banner "Using existing namespace: cowbull"
fi
