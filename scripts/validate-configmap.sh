config_map=$(kubectl -n cowbull get configmaps --no-headers $1)
ret_stat=$?
if [ "$ret_stat" != "0" ]
then
    if [ -f .local/$1.yaml ]
    then
        short_banner "Loading cowbull configuration from local manifest"
        kubectl apply -n cowbull -f .local/$1.yaml
    else
        short_banner "Local manifest for $1 was not found."
        short_banner "It needs to exist in .local before running the loader."
        short_banner "It must contain..."
        cat examples/$1.example
        exit $ret_stat
    fi
fi

