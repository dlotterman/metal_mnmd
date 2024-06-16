#!/bin/bash
logger "starting /opt/equinix/metal/bin/minio_schema_backup.sh"
source /opt/equinix/metal/bin/metal_mnmd_sharedlib.sh
mc --insecure admin cluster bucket export object_private
mv object_private-bucket-metadata.zip /opt/equinix/metal/tmp/"$CURRENT_TS"_object_private-bucket-metadata.zip
mc --insecure admin cluster iam export object_private
mv object_private-iam-info.zip /opt/equinix/metal/tmp/"$CURRENT_TS"_object_private-iam-info.zip
cp /etc/default/minio /opt/equinix/metal/tmp/"$CURRENT_TS"_minio_defaults
