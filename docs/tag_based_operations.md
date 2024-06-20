# Tag Based Operations of Equinix Metal

`metal_mnmd` is a self contained deployment toolchain. While it can be driven with a tool like `terraform` or `ansible`, it's just a collection of short idempotent scripts executed in order to produce a specific result, MinIO running with a correct configuration on an instance of Equinix Metal.

It does this primarily by heavy usafe of Equinix Metal's [device tagging](https://deploy.equinix.com/developers/docs/metal/server-metadata/device-tagging/) feature. Rather than trying to manage any kind of long running distributed state on the instance side ([Zookeeper, etcd]()), instances will periodically poll the [metadata](https://deploy.equinix.com/developers/docs/metal/server-metadata/metadata/), and on detection of certain magical strings present in the form of `tags`, will update itself in place according to the desired intent of the tag.

For example, to tell an instance what [Metal VLAN](https://deploy.equinix.com/developers/docs/metal/layer2-networking/vlans/) to run MinIO in, we give the instance the tag: `"MMNMD_VLAN_248"`, which when an instance provisioned with the included [cloud-init]() detects as a tag applied to it, that instance will proceed to configure itself with VLAN `248` for it's networking turnup. Or for another example, when an instance find itself tagged with `MMNMD_FIREWALL_HOLE_209.98.42.38`, the install will configure a firewall rule to allow all traffic from `209.98.42.38`.

## metal_tag_extend.sh

The primary execution of desired state is managed by the script [bin/metal_tag_extend.sh](https://github.com/dlotterman/metal_mnmd/blob/main/bin/metal_tag_extend.sh). This script is called every minute by a [systemd timer](https://wiki.archlinux.org/title/systemd/Timers) that is installed by the original [cloud-init](). `metal_tag_extend` gets the most recent tags from Metal metadata, writes them as a "tag per line" file for use by [other scripts](https://github.com/dlotterman/metal_mnmd/blob/main/bin/metal_mnmd_sharedlib.sh), and then looks for the presence of certain key tags, where if that tag is deteceted, do the things that are intended by the presence of that tag.

If a common tag is applied to multiple nodes, and each does the correct thing based on that tag, over a semi-eventual period of time, all nodes will be in the correct state based on that tag.

## Deploy Idempotency

Each script script of the deploy process, including the deploy script itself, is meant to achieve the same state regardless of how many times or from what state it's run, that is to say, it is intended to enforce the correct state as of the time it is ran, and it can be re-ran as needed without impacting a running / healthy system.

## How scripts get called

Scripts get executed in three places.
- `metal_mnmd_deploy.sh`, which is called by cloud-init and also `metal_tag_extend.sh`
- `metal_tag_extend.sh`, which is called every 1 min, will update the system to current tags and call a deploy on `MMNMD_UPDATE_` or `MMND_DEPLOY_` tags being found (see below)
- `object_private_bootstrap.sh`, which is called after `metal_mnmd_deploy.sh`, calls the monitoring manage script. This is just for lack of another place to put it currently.

## List of metal_mnmd tags

### Operational Tags


- `MMNMD_BRANCH_`: If present, this tag will instruct nodes to checkout a branched version of this repository instead of the `main` the is cloned by default during the "[deploy()". This is useful if say a bug fix or feature change needs to be tested before being committed to master. Cannot contain `_` or "underbars".
  - Optional: yes
  - Toggleable post deployment: Yes
  - Multiple allowed: No
  - Complete example: `MMNMD_BRANCH=cluster_scale_052024`
- `MMNMD_FIREWALL_HOLE`: If present, this tag will instruct nodes to open up and "allow all" from the IP included in this tag, allowing that IP access to Grafana / Prometheus and other services. Can be multiple
  - Optional: yes
  - Toggleable post deployment: Yes
  - Multiple allowed: Yes
  - Complete example: `MMNMD_FIREWALL_HOLE1_209.98.98.98,MMND_FIREWALL_HOLE2_208.42.42.42`

### MinIO Tags:

- `MMNMD_SUBNET_`: Required to be present, this will set the `/24` network the instance configures on the inside of it's Metal VLAN. This will be the primary network for that MinIO deployment, and the MinIO services themselves will be started on this network. It must NOT include the trailing `.0`, so if your network is `192.168.202.0/24`, then your tag should end with the string `192.168.202`. Each instance will taken it's magic number IP from the /24, so a node provisioned as `d-2` will self assign `.2` from the block, or `d-48` would assign `.48`.
  - Optional: No, required
  - Toggleable post deployment: No
  - Multiple allowed: No, (see `ANETWORKS` below)
  - Complete example: `MMNMD_SUBNET_172.16.249`
- `MMNMD_VLAN_`: Required to be present, this will set the VLAN for the `MMNMD_SUBNET_` tag above, and is expected to be paired with a Metal VLAN with the same integer, so if the MinIO network should live in Metal VLAN `3870`, then this should be `MMNMD_VLAN_3870`
  - Optional: No, required
  - Toggleable post deployment: No, (see `ANETWORKS` below)
  - Multiple allowed: No
  - Complete example: `MMNMD_VLAN_249`
- `MMNMD_VGW_`: If present, will change the MinIO network gateway away from the presumed `.1` to the specified ending it. So if you need a GW IP of `192.168.202.249` instead of `192.168.202.1`, specify `.249` here
  - Optional: Yes
  - Toggleable post deployment: No, (see `ANETWORKS` below)
  - Multiple allowed: No
  - Complete example: `MMNMD_VGW_249`
- `MMNMD_UPDATE_`: When present, this will instruct the instance to "start or restart" MinIO at the time of the [Unix or "epoch" timestamp](https://en.wikipedia.org/wiki/Unix_time) present at the end of the tag. So a tag of `MMNMD_UPDATE_1718753896` will instruct each instance to schedule a "start or restart" of MinIO at `1718753896`, which equates to **"Tue Jun 18 2024 23:38:16 GMT+0000"**. Sites like [Unix Timestamp](https://www.unixtimestamp.com/) or shell shorthands like `date -d 1718753896` or `date +%s  -d  "+10 minutes"`. There should never be more than one **"Update"** present at a time, and Update should be exclusive with `Deploy`. One a `MMNMD_UPDATE` tag has been processed and the "start or restart" of MinIO scheduled, the instance will add the tag to a list of tombstones to ignore while present, and while present will ignore all other tags until removed. New update tags can be added as needed, there is no limit to the number of times a new update tag can be applied so long as old tags are removed as well.
  - Optional: Yes
  - Toggleable post deployment: Yes
  - Multiple allowed: No
  - Complete example: `MMNMD_UPDATE_1718753896`
- `MMND_DEPLOY_`: When present, this will instruct the instance to "deploy" from Github, that is clone the `metal_mnmd` repo and copy scripts and artifacts to their correct locations, and any mangling needed to update the instance to a new intended state. Explicitly does not touch MinIO state, but WILL update the MinIO `/etc/default/minio` file, so this can have consequences if new tags are present on the box since it's last **"deploy"**. Once processed, `DEPLOY` tags will be tombstoned and ignored, and this tag is also incompatible with `UPDATE` tags being present at the same time.
  - Optional: Yes
  - Toggleable post deployment: Yes
  - Multiple allowed: No
  - Complete example: `MMNMD_UPDATE_1718753896`
- `MMNMD_GROUP_`: Required to be present, this tag informs the instance of a grouping of instances intended to be considered a group for the purposes of MinIO [server pools](https://min.io/docs/minio/linux/operations/concepts.html#how-does-minio-link-multiple-server-pools-into-a-single-minio-cluster). The first number in the string is the lowest count of instances in the group, the last number is the highest. So if provisioning 4x nodes that would MinIO as a cluster, the tag would be `MMNMD_GROUP_2_5`, which would give us `{2 3 4 5}` or 4x instances. MinIO thinks of each instance in the cluster as a member of a group, where the group is intended to be fixed for the liftime of the current size of the deployment. That is to say, if you provision 4x MinIO nodes as an initial cluster (`MMNMD_GROUP_2-5`), MinIO will think of those four instances as part of a "Server Pool" or "Group". When the cluster needs to be sized up to say 8x nodes, rather than adding 4x nodes (`MMNMD_GROUP_6_9`) to the original group of 4x (creating a single group of 8x), [instead two lists of 4x nodes are maintained](https://blog.min.io/server-pools-streamline-storage-operations/) by MinIO(`["MMNMD_GROUP_2-5","MMNMD_GROUP_6-9"]`), each a seperate server pool, where both pools are then utilized by MinIO depending to the I/O pattern and the erasure coding settings. So rather than being a group of 8x nodes, you have 2x lists of 4x. If you go to expand that same cluster again by 16x nodes (`MMNMD_GROUP3_10_25`), rather than having one list of 24x nodes, you would have 3x lists, one of four, a second of four, and a third of sixteen, for a total of three groups totalling 24x nodes (`["MMNMD_GROUP_2-5","MMNMD_GROUP_6-9","MMNMD_GROUP_10_25"]`). MinIO will do the correct thing for parity and I/O according to the number of instances and drives available. Mulitple groups can be tagged at one time, and the tags for each group MUST be present before `UPDATE` or `DEPLOY` actions. For a single node cluster, this can be set to `MMND_GROUP_2_2`. Technically these can be removed, if the corrrect steps are taken to de-provision nodes before removing the tag.
  - Optional: Minimum one required
  - Toggleable post deployment: Yes
  - Multiple allowed: Yes
  - Complete example: `MMNMD_GROUP_2_5`

### Networking Tags

While `MMNMD_SUBNET_` and `MMNMD_VLAN_` dictate the primary MinIO service VLAN and subnet, the following tags can be used to augment the instance's networking over the lifetime of the deployment.

- `MMNMD_ANETWORK`: When present, an `MMNMD_ANETWORK` tag will add an "additional network" to the instance. An tag of `MMNMD_ANETWORK1_3860_172.16.240` will add an additional VLAN interface to the MinIO instance with VLAN `3860` and an a `/24` is assumed of the subnet `172.16.240` where the instance number will be used for the IP, so an instance `c-4` will self-assign `172.16.240.4` on VLAN `3860`. Multiple of these networks can be specified. A gateway IP of `.1` is assumed.
  - Optional: Yes
  - Toggleable post deployment: Yes
  - Multiple allowed: Yes
  - Complete example: `MMNMD_ANETWORK1_3860_172.16.240`
- `MMNMD_AROUTE`: When present, will add an additional route to a VLAN and subnet added by the above `MMNMD_ANETWORK` tag. A tag of `MMNMD_AROUTE_3860_172.16.104` will add a route of `172.16.104.0/24` to the gateway associated with VLAN `3860`, which would have been defined by the `MMNMD_ANETWORK_3860_172.16.240` tag.
  - Optional: Yes
  - Toggleable post deployment: Yes
  - Multiple allowed: Yes
  - Complete example: `MMNMD_ANETWORK1_3860_172.16.240`
- `MMNMD_ADNS`: When present, will add an additional DNS server for the given domain to the list of `dnsmasq` upstreams. A tag of `MMNMD_ADNS1_172.16.248.2-172.16.248.3:248.private` will add two DNS servers, `172.16.248.2` and `172.16.248.3` as upstream servers for the name `248.private`. If added, an instance with this tag will send any DNS lookup for `248.private` to this server. Multiple of these tags can be specified and exist on an instance at the same time.
  - Optional: Yes
  - Toggleable post deployment: Yes
  - Multiple allowed: Yes
  - Complete example: `MMNMD_ANETWORK1_3860_172.16.240`
