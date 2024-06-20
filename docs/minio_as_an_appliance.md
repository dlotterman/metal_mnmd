# MinIO as an appliance on Metal via cloud-init

 One of the best use cases for [cloud-init](https://cloudinit.readthedocs.io/en/latest/) with [Equinix](https://deploy.equinix.com/developers/docs/metal/server-metadata/user-data/#usage) [Metal](https://deploy.equinix.com/developers/guides/planning-your-first-server-deployment/) is using it as an easy path towards the "appliance-afication" or a service, for example creating a [bastion](https://github.com/dlotterman/metal_code_snippets/tree/main/virtual_appliance_host/no_code_with_guardrails), [iperf](https://github.com/dlotterman/metal_code_snippets/tree/main/iperf_appliance) and [smokeping](https://github.com/dlotterman/metal_code_snippets/tree/main/smokeping) appliances. Because **cloud-init** neatly places itself between the "i need an instance" and "my instance is provisioned" steps of operation, its an ideal spot to operationalize certain repetitive workflows.
 
 In this case, what the `cloud-init` and bash script files of this repository do is take the logical steps of provisioning an Equinix Metal instance or instances and networks, and combine them with the steps the steps MinIO describes for [deploying a multi-node multi-drive](https://min.io/docs/minio/linux/operations/install-deploy-manage/deploy-minio-multi-node-multi-drive.html) MinIO deployment, including the tasks required for any glue to integrate the two, an example of that here is the use of [dnsmasq](../bin/metal_dnsmasq_manage.sh) as a network glue.
 
 ## Walkthrough of toil
 
 1. An instance is provisioned with the [correct cloud-init](../modules/c_nodes/minio-node-cloud-init.yaml) and the following tags: `["MMNMD_SUBNET_172.16.249","MMNMD_VLAN_249","MMNMD_GROUP1_2-4"]`, and the following list of toils will be performed
    - The instance is updated to Ubuntu current including needed reboot
    - A `minio-user` is added, this will be the user that systemd runs MinIO under
    - A `adminuser` is added, this is primarily to move administrative (namely SSH) responsibility and exposure away from `root`
    - Necessary packages are installed
    - [smartmontools](https://www.smartmontools.org/) is installed and configured
    - [sshd]() is locked down and root is prohibited
    - [Ubuntu Automatic Updates](https://help.ubuntu.com/community/AutomaticSecurityUpdates) are enabled
    - The [host firewall](https://help.ubuntu.com/community/UFW) is turned up and enabled. ssh allowed in but with a limiter, all services allowed over the [Metal Private Network](https://deploy.equinix.com/developers/docs/metal/networking/ip-addresses/?_gl=1*qc89md*_up*MQ..*_ga*MTU2NDcyOTY4NS4xNzE4ODEyMTk3*_ga_KKD62NKFWY*MTcxODgxMjE5Ni4xLjAuMTcxODgxMjE5Ni4wLjAuMA..#private-ipv4-management-subnets)
2. The `metal_mnmd_deploy.sh` is written and executed by `cloud-init`.
        - `metal_mnmd_deploy.sh` should call everything needed to prepare the instance for clustered MinIO service, including networking, disks, stand-in SSL certificates etc. The `/etc/default/minio` file will be templated as configured by the `MMND_GROUP_` tag, and the system will stop just short of actually starting MinIO itself.
        - Grafana should now be accessible, though the MinIO dashboard will likely be unavailable due to empty data, this will be corrected after MinIO is started.
3. Once the `MMNMD_UPDATE_` tag with correct future timestamp is applied (for example `MMNMD_UPDATE_1718813406`), all instances will schedule a start of MinIO for the future timestamp. This is discussed more in it's own section below.
    - Once the event of the timestamp occurs, each instance will start it's MinIO service and the cluster will come up
    - The deploy script will enable certain toils via `object_private_bootstrap.sh` that had to wait for MinIO to be enabled, such as alias creation etc. MinIO should be available in the Grafana dashboard after this point.
    
## Undestanding MinIO  start / stop

The act of starting and stopping MinIO is consequential. 

While MinIO does a fantastic job of establishing and maintaining "service" quorum, I.E "Are my peers up and are their disks healthy and is my data parity ok?", MinIO provides minimal tooling around "operational quorum", that is "What nodes are in the pool, and how much automagic do I provide around configuration coordination?". Rather than mangling and writing configuration files and service state itself, MinIO prefers to defer that to the responsbility. Another way of putting this is that MinIO "will take over responsibility once the cluster is up", but the act of "getting the cluster up" is very much an operator responsibility.
    
Critically, certain configuration details such as "members of server pools" and "what server pools are part of the cluster" are determined only at start time, that is execution time of the MinIO binary, and cannot be updated while the service is running. This means "cluster resize" events **must** be cluster-wide "stop then start together" tasks. 

MinIO also has a strong anti-affinity for "rolling restarts", preferring to take the pain of a restart in one event across the environemnt in one large but fast restart. To put this again clearly, MinIO never wants a rolling restart, it will always prefer cluster-wide restart. Certain chores like reboots for kernel upgrades can be implemented in rolling fashion, but steps should be taken to validate cluster health and parity behavior between those restarts.

### Growing a cluster

Beyond the above preference for "cluster-wide restart events", there is also a nuance in adding MinIO nodes / server pools. Consider a deployment with 4x MinIO instances (`MMNMD_GROUP_2-5`), that is growing by adding another 4x MinIO instances (`MMNMD_GROUP_6-9`).

Once all of the configuration and operational toil is complete to setup the new 4x instances to join the existing, MinIO will want the entire cluster to reboot to incorporate the new server pool. If the start of the 4x new nodes is scheduled for the exact same time as the 4x existing begin their restart, a restart can / will take longer than a frest start, meaning a race condition can start where the new MinIO instances come up faster / before the original 4x nodes. This is non-ideal as for a clean cluster start, the new nodes should ideally have a clean "come up" seeing the existing clusters resources.

This means than when adding server pools to the cluster, we really want the original instances to restart and "come up" first, so they are ready and expecting of the connections from the new instances. When the new group then comes up, those MinIO instances will correctly see the existing server pool from their first start, ensuring the cleanest expansio service turnup.