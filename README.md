# MinIO Multi-Node Multi-Drive with Equinix Metal

[![Experimental](https://img.shields.io/badge/Stability-Experimental-red.svg)](https://github.com/equinix-labs/standards#about-uniform-standards)
[![terraform](https://github.com/equinix-labs/terraform-equinix-metal-vrf/actions/workflows/integration.yaml/badge.svg)](https://github.com/equinix-labs/terraform-equinix-metal-vrf/actions/workflows/integration.yaml)

## Disclaimer

This repository is highly active with frequent breaking changes, do not base anything long lived of this repo as long as this disclaimer stands.

# "Operationalized" MNMD with Metal
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


![](https://github.com/dlotterman/metal_mnmd/blob/dlott_initial3/docs/assets/minio.PNG)
![](https://github.com/dlotterman/metal_mnmd/blob/dlott_initial3/docs/assets/node.PNG)

This repository aims to be a tool for operators looking to get a quick evaluation of MinIO or Object Storage on Equinix Metal in an "Operationalized" way, where the intent of that is to broadly cover the scope of things needed to run an Object Stoage platform, based on MinIO, on Equinix Metal.

That is not to say it is "Production Ready", but using this, an operator can jumptstart their understanding of running object storage at scale, with things like failure recovery, monitoring, schema backups and such toil in mind.

Read before getting started:
- [Tag based operations with Equinix Metal]()
- [Using cloud-init to "appliance-afy" MinIO]()
- [Networking with metal_mnmd]()
At the core of this tool is an idea to use
![Metal-VRF-Github-0928-2023](https://github.com/equinix-labs/terraform-equinix-metal-vrf/assets/46980377/f3f2718c-bb53-4744-b1f1-e5f4a0116017)





The following is the Terraform flow of this script:

1. Create metal nodes <br />
2. Create a VLAN (or using an existing VLAN) <br />
3. Attach the VLAN to instances (Metal nodes are setup as Layer 2 bonded mode) <br />
4. Specify IP blocks to be used (both BGP IPs and Network IPs) <br />
5. Create a VRF instance (with the Project ID, VLAN created, local ASN assigned, IP blocks etc.) <br />
6. Allocate IPs for the gateway and its associated server nodes (from the IP pools in step 5) <br />
7. Create a Metal Gateway instance using ip_reservation_id from step 6, & project ID, VLAN IDs etc. <br />
8. Create and Attach VCs from your Metal's dedicated fabric ports to the VRF instance <br />

After the Metal nodes and VRF are sucessfully deployed, the following behaviors are expected: <br />

1. A Metal node can reach to the metal gateway via the gateway's IP 192.168.100.1
2. Metal nodes can reach to each anoter via their IPs (192.168.100.x)
3. A Metal node can reach to the VRF's BGP neighbor IP (for example, 169.254.100.1)
4. A Metal node can reach to the colo device's BGP neighbor IP (for example, 169.254.100.2)
5. Metal nodes and your colo servers can reach to each other if you have setup servers on VLAN1 behind your colo network devices and advertise routes via the BGP sessions established between your network devices and the Metal VRF

This repository is [Experimental](https://github.com/packethost/standards/blob/master/experimental-statement.md) meaning that it's based on untested ideas or techniques and not yet established or finalized or involves a radically new and innovative style! This means that support is best effort (at best!) and we strongly encourage you to NOT use this in production.

## Install Terraform

Terraform is just a single binary.  Visit their [download page](https://www.terraform.io/downloads.html), choose your operating system, make the binary executable, and move it into your path.

Here is an example for **macOS**:

```bash
curl -LO https://releases.hashicorp.com/terraform/0.12.18/terraform_0.12.18_darwin_amd64.zip
unzip terraform_0.12.18_darwin_amd64.zip
chmod +x terraform
sudo mv terraform /usr/local/bin/
```

## Download this project

To download this project, run the following command:

```bash
git clone https://github.com/equinix-labs/terraform-metal-vrf.git
cd terraform-metal-vrf
```

## Initialize Terraform

Terraform uses modules to deploy infrastructure. In order to initialize the modules you simply run: `terraform init`. This should download modules into a hidden directory `.terraform`

## Modify your variables

See `variables.tf` for a description of each variable. You will need to set all the variables at a minimum in terraform.tfvars:

```
cp example.tfvars terraform.tfvars
vim terraform.tfvars
```

#### Note - Currently only Ubuntu has been tested

## Deploy terraform template

```bash
terraform apply --auto-approve
```

Once this is complete you should get output similar to this:

```console
Apply complete! Resources: 17 added, 0 changed, 0 destroyed.

Outputs:
dedicated_ports = {
  "metro" = "ny"
  "name" = "NY-Metal-to-Fabric-Dedicated-Redundant-Port"
  "port_id" = "06726413-c565-4173-82be-9a9562b9a69b"
  "redundancy" = "redundant"
}
metal_gateway = [
  {
    "id" = "928fd880-3245-4118-aeee-a10946ba80a5"
    "ip_reservation_id" = "29a51565-737d-407d-8f53-f5071b32a58c"
    "private_ipv4_subnet_size" = 8
    "project_id" = "81666c08-3823-4180-832f-1ce1f13e1662"
    "state" = "ready"
    "vlan_id" = "8446cf2c-60d9-4370-9be1-ecb351165cd2"
    "vrf_id" = "450812ad-4e5b-43ac-9cfd-1c18dde8c5ac"
  },
]
metal_vrf = [
  {
    "description" = "VRF with ASN 65100 and a pool of address space that includes a subnet for your BGP and subnets for each of your Metal Gateways"
    "id" = "450812ad-4e5b-43ac-9cfd-1c18dde8c5ac"
    "ip_ranges" = toset([
      "169.254.100.0/24",
      "192.168.100.0/24",
    ])
    "local_asn" = 65100
    "metro" = "ny"
    "name" = "my-vrf"
    "project_id" = "81666c08-3823-4180-832f-1ce1f13e1662"
    "timeouts" = null /* object */
  },
]
metrovlan_ids = [
  1008,
  1009,
]
server_name = [
  "mymetal-node-1",
  "mymetal-node-2",
]
ssh_private_key = "/Users/usrname/terraform-equinix-metal-vrf/ssh_key_name"
virtual_connection_primary = {
  "metal_ip" = "169.254.100.1"
  "name" = "virtual_connection_pri"
  "nni_vlan" = 999
  "peer_asn" = 100
  "peer_ip" = "169.254.100.2"
  "vc_id" = "195891bb-83ec-4faa-86ae-25ac434e5deb"
}
virtual_connection_secondary = {
  "metal_ip" = "169.254.100.9"
  "name" = "virtual_connection_sec"
  "nni_vlan" = 999
  "peer_asn" = 100
  "peer_ip" = "169.254.100.10"
  "vc_id" = "47086fe1-9323-4bed-8237-20f161932a29"
}

```
