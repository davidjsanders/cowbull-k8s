config_map=$(kubectl -n cowbull get configmaps --no-headers $1 2> /dev/null)
ret_stat=$?
if [ "$ret_stat" != "0" ]
then
    if [ -f .local/$1.yaml ]
    then
        short_banner "Loading cowbull configuration from local manifest"
        kubectl apply -n cowbull -f .local/$1.yaml &> /dev/null
        if [ "$?" != "0" ]
        then
            short_banner "Unable to apply configuration map manifest!"
            exit 1
        fi
    else
        short_banner "Local manifest for $1 was not found."
        short_banner "It needs to exist before running the loader as a configmap or a file: .local/$1.yaml"
        short_banner "It must contain..."
        cat examples/$1.example
        exit $ret_stat
    fi
else
    short_banner "Found configmap $1"
fi

