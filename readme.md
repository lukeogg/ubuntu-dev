# Create an ubuntu machine for dev in aws 

## Prerequisites 
Requires Terraform v0.13.7. Use (tfenv)[https://github.com/tfutils/tfenv] for installation.

## Creation
Edit the `terraform.tfvars` file and adjust owner and instance_type values.

To install apply the terraform files. This will generate a key pair and create the machine.

``` shell
terraform init
terraform apply
```

The command will output the public dns of the machine as well as an SSH connection string. It is recommended to use tmux to prevent commands from failing due to connection.

## Multiple Workspaces
You can create multiple machines this way:

```
$ terraform workspace new dev-machine2
$ terraform init
$ terraform apply
```

## Set up repo and dev env

``` shell
# Run script to checkout kaptain repo and set env vars
./local-setup.sh
```
