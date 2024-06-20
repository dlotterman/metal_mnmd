# MinIO Multi-Node Multi-Drive with Equinix Metal

[![Experimental](https://img.shields.io/badge/Stability-Experimental-red.svg)](https://github.com/equinix-labs/standards#about-uniform-standards)

[![terraform](https://github.com/equinix-labs/terraform-equinix-metal-vrf/actions/workflows/integration.yaml/badge.svg)](https://github.com/equinix-labs/terraform-equinix-metal-vrf/actions/workflows/integration.yaml)

## Disclaimer

This repository is highly active with frequent breaking changes, do not base anything long lived of this repo as long as this disclaimer stands.

This repository is Experimental meaning that it's based on untested ideas or techniques and not yet established or finalized or involves a radically new and innovative style! This means that support is best effort (at best!) and we strongly encourage you to NOT use this in production.

# "Operationalized" MNMD with Metal
![](https://github.com/dlotterman/metal_mnmd/blob/dlott_initial3/docs/assets/minio.PNG)
![](https://github.com/dlotterman/metal_mnmd/blob/dlott_initial3/docs/assets/node.PNG)

```
root@c-2:~# mc --insecure admin info object_private
●  c-2.private:9000
   Uptime: 38 minutes
   Version: 2024-06-13T22:53:53Z
   Network: 3/3 OK
   Drives: 2/2 OK
   Pool: 1

●  c-3.private:9000
   Uptime: 38 minutes
   Version: 2024-06-13T22:53:53Z
   Network: 3/3 OK
   Drives: 2/2 OK
   Pool: 1

●  c-4.private:9000
   Uptime: 38 minutes
   Version: 2024-06-13T22:53:53Z
   Network: 3/3 OK
   Drives: 2/2 OK
   Pool: 1

┌──────┬──────────────────────┬─────────────────────┬──────────────┐
│ Pool │ Drives Usage         │ Erasure stripe size │ Erasure sets │
│ 1st  │ 1.9% (total: 10 TiB) │ 6                   │ 1            │
└──────┴──────────────────────┴─────────────────────┴──────────────┘

0 B Used, 5 Buckets, 0 Objects
6 drives online, 0 drives offline, EC:3
```
```
warp mixed --insecure --tls --host=c-{2...4}.248.private:9000 --warp-client=z-{2...4}.private --access-key= --secret-key= --duration 10m
warp: Benchmark data written to "warp-remote-2024-06-16[000436]-N1Lj.csv.zst"
Mixed operations.
Operation: DELETE, 10%, Concurrency: 60, Ran 9m59s.
 * Throughput: 170.61 obj/s

Operation: GET, 45%, Concurrency: 60, Ran 9m59s.
 * Throughput: 7676.16 MiB/s, 767.62 obj/s

Operation: PUT, 15%, Concurrency: 60, Ran 9m59s.
 * Throughput: 2558.81 MiB/s, 255.88 obj/s

Operation: STAT, 30%, Concurrency: 60, Ran 9m59s.
 * Throughput: 511.77 obj/s

Cluster Total: 10234.84 MiB/s, 1705.87 obj/s over 10m0s.
```
```
# bash /etc/cron.hourly/minio_schema_backup.sh
mc: Bucket metadata successfully downloaded as object_private-bucket-metadata.zip
mc: IAM info successfully downloaded as object_private-iam-info.zip
root@c-2:~# ls -al /opt/equinix/metal/tmp/
total 40
drwxr-xr-x 3 root root 4096 Jun 16 00:22 .
drwxr-xr-x 5 root root 4096 Jun 15 23:25 ..
-rwxr-x--- 1 root root  251 Jun 16 00:22 1718497368_minio_defaults
-rw-r--r-- 1 root root 3515 Jun 16 00:22 1718497368_object_private-bucket-metadata.zip
-rw-r--r-- 1 root root 1630 Jun 16 00:22 1718497368_object_private-iam-info.zip
```

This repository aims to be a "launchpad" for operators looking to get a quick evaluation of MinIO or Object Storage on Equinix Metal in an "Operationalized" way, where the intent of that is to broadly cover the scope of things needed to run an Object Stoage platform, based on MinIO, on Equinix Metal.

That is not to say this repository is "Production Ready", but using this starting place, an operator can jumptstart their understanding of running object storage at scale on Equinix Metal, complete with operational toil like failure recovery, scale up (and down,) monitoring, and schema backups.


## Read **before** getting started:

- [Tag based operations with metal_mnmd](docs/tag_based_operations.md)
- [Using cloud-init to "appliance-afy" MinIO](docs/minio_as_an_appliance.md)
- [Networking with metal_mnmd]()
- [Grafana / Prometheus / Alertmanager Walkthrough]()

## Getting Started

- [Provisioning via MetalUI / web console]()
- [Provisioning via Metal CLI / shell]()
- [Provisioning via Terrarfom (suggested)]()
- [Provisioning via Ansible (comming)]()


## day-1+
- [Accessing Grafana, Prometheus and Alertmanager]()
- [Expanding a MinIO cluster]()
- [Recovering from a node failure]()
- [Decommisioning a MinIO node from a cluster]()
- [Setting up tiering between MinIO node types]()
- [Setting up load balancing "l_node" tier]()
- [Benchmarking with warp]()

## Outside documentation
- [Minio Erasure Code Calculator]()
