if [ "$yaml_filesX" == "X" ]
then
    short_banner "*skipping* No manifests found; yaml files should exist in ./yaml"
else
    for file in $yaml_files
    do
        short_banner "${log_action} yaml for: $file"
        sed '
            s/\${LBIP}/'"$LBIP"'/g;
            s/\${STORAGE_CLASS}/'"$STORAGE_CLASS"'/g;
            s/\${STORAGE}/'"$STORAGE"'/g;
            s/\${target_registry}/'"$TARGET_REGISTRY"'/g;
            s/\${host_number}/'"$host_number"'/g;
            s/\${redis_gid}/'"$redis_gid"'/g;
            s/\${redis_uid}/'"$redis_uid"'/g;
            s/\${redis_tag}/'"$redis_tag"'/g;
            s/\${cowbull_version}/'"$COWBULL_VERSION"'/g;
            s/\${cowbull_webapp_version}/'"$COWBULL_WEBAPP_VERSION"'/g;
            s/\${docker_hub}//g
        ' $file | kubectl $kubectl_action -f - &> /dev/null
        if [ "$?" != "0" ]
        then
            short_banner "There was an error with manifest: $file"
        fi
    done
fi
if [ "$ACTION" == "delete.sh" ]
then
    short_banner "Remember the namespace and configmaps have not been deleted!"
    short_banner "If required, delete them with: kubectl delete namespaces cowbull"
fi