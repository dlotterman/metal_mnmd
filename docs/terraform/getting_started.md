- Clone Repository
```
$ git clone https://github.com/dlotterman/metal_mnmd.git
Cloning into 'metal_mnmd'...
remote: Enumerating objects: 372, done.
remote: Counting objects: 100% (171/171), done.
remote: Compressing objects: 100% (92/92), done.
remote: Total 372 (delta 118), reused 102 (delta 79), pack-reused 201
Receiving objects: 100% (372/372), 939.12 KiB | 6.02 MiB/s, done.
Resolving deltas: 100% (173/173), done.
```
- Init Terraform
```
dlotterman@devvm:/tmp/trash/metal_mnmd$ terraform init

Initializing the backend...
Initializing modules...
- c_nodes in modules/c_nodes
- equinix_metal_nodes in modules/d_nodes
- l_nodes in modules/l_nodes
- z_nodes in modules/z_nodes

Initializing provider plugins...
- Reusing previous version of equinix/equinix from the dependency lock file
- Reusing previous version of hashicorp/cloudinit from the dependency lock file
- Installing equinix/equinix v1.14.1...
- Installed equinix/equinix v1.14.1 (signed by a HashiCorp partner, key ID 1A65631C7288685E)
- Installing hashicorp/cloudinit v2.2.0...
- Installed hashicorp/cloudinit v2.2.0 (signed by HashiCorp)

Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/cli/plugins/signing.html

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```
- Copy example.tfvars to terraform.tfvars and edit
`cp example.tfvars terraform.tfvars`
