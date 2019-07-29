short_banner "Preparing images; pulling from $SOURCE_REGISTRY and pushing to $TARGET_REGISTRY"
images=("cowbull:${COWBULL_VERSION} cowbull_webapp:${COWBULL_WEBAPP_VERSION}")
for image in $images
do
    image_name="$SOURCE_REGISTRY/$image"
    short_banner "Pull $TARGET_REGISTRY/$image from local registry"
    sudo docker pull ${TARGET_REGISTRY}/$image &> /dev/null
    ret_stat="$?"

    if [ "$ret_stat" != "0" ]
    then
        short_banner "Not found; Pulling $image_name from $SOURCE_REGISTRY"
        sudo docker pull $image_name &> /dev/null
        short_banner "Tagging as $TARGET_REGISTRY/$image"
        sudo docker tag $image_name $TARGET_REGISTRY/$image &> /dev/null
        short_banner "Pushing as $TARGET_REGISTRY/$image"
        sudo docker push $TARGET_REGISTRY/$image
        if [ "$?" != "0" ]
        then
            short_banner "Problem pushing image; are you logged in to docker?"
            short_banner "Try: sudo docker login -u <theuser> k8s-master:32081"
        fi
        echo
    fi
done
