logger "starting /opt/equinix/metal/bin/metal_tag_extend.sh"
touch /opt/equinix/metal/etc/metal_tag_extend.env
touch /opt/equinix/metal/tmp/updates.tombstone
if curl http://metadata.platformequinix.com &> /dev/null; then
    true
    else
    logger "could not reach / resolve metadata, exiting1"
    exit 1
fi
curl -s https://metadata.platformequinix.com/metadata -o /opt/equinix/metal/tmp/.metadata_update
rm /opt/equinix/metal/tmp/.tmp_metal_tag_extend.env > /dev/null 2>&1
touch /opt/equinix/metal/tmp/.tmp_metal_tag_extend.envs
TAGS=$(jq -r '.tags[]' /opt/equinix/metal/tmp/.metadata_update)
for TAG in $TAGS; do
    echo "export TAG_""${TAG}""" >> /opt/equinix/metal/tmp/.tmp_metal_tag_extend.env
done
mkdir -p /opt/equinix/metal/etc/
mv /opt/equinix/metal/tmp/.tmp_metal_tag_extend.env /opt/equinix/metal/etc/metal_tag_extend.env > /dev/null 2>&1
rm /opt/equinix/metal/tmp/.metadata_update > /dev/null 2>&1
for TAG in $TAGS; do
    if [[ "$TAG" =~ "MMNMD_UPDATE_" ]]; then
        logger "entering update context for $TAG"
        if grep -Fxq "$TAG" /opt/equinix/metal/tmp/updates.tombstone; then
            logger "tag $TAG found in tombstone, passing"
            exit 0
        else
            bash /opt/equinix/metal/bin/metal_mnmd_deploy.sh
            bash /opt/equinix/metal/bin/minio_restart_manage.sh
            bash /opt/equinix/metal/bin/object_private_bootstrap.sh
            echo "$TAG" >> /opt/equinix/metal/tmp/updates.tombstone
        fi
    elif [[ "$TAG" =~ "MMNMD_DEPLOY_" ]]; then
        logger "entering deploy tag context $TAG"
        if grep -Fxq "$TAG" /opt/equinix/metal/tmp/updates.tombstone; then
            logger "tag $TAG found in tombstone, passing"
            exit 0
        else
            logger "found deploy tag $TAG, deploying"
            bash /opt/equinix/metal/bin/metal_mnmd_deploy.sh
			echo "$TAG" >> /opt/equinix/metal/tmp/updates.tombstone
        fi
    fi
done
