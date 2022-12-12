# Create an ubuntu EC2 instance for dev in AWS 

## Prerequisites 
Requires Terraform v0.13.7. Use (tfenv)[https://github.com/tfutils/tfenv] for installation.

If you're working with an M1 Mac laptop, try installing Terraform v1.0.11.

## Creation
Edit the `terraform.tfvars` file and adjust owner, instance_type and iam_instance_profile values.

To install apply the terraform files. This will generate a key pair and create the machine.

Create a [github certificate](https://docs.github.com/en/enterprise-server@3.2/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)

### Set path for setup script and repo to clone

``` shell
export GITHUB_CERT_PATH=~/.ssh/<name_of_my_cert>  # no .pub here
export GITHUB_REPO=git@github.com:<path-to-my-repo.git>
```

### Start the dev machine

``` shell
terraform init
# optional
# cat <<EOF > .terraform.version
# <semvar_value_of_the_version_you_just_installed>
# EOF
terraform apply -var owner="$(whoami)" -auto-approve
```

The command will output the public dns of the machine as well as an SSH connection string. It is recommended to use tmux to prevent commands from failing due to connection.

### To connect with ssh

``` shell
./connect.sh
```

### Set up repo and dev env

``` shell
# Run script to checkout dev repo and set env vars
./local-setup.sh
```

## Multiple Workspaces
You can create multiple machines this way:

```
$ terraform workspace new dev-machine2
$ terraform init
$ terraform apply -auto-approve
```
