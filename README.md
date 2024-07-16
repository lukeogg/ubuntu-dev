# Create an Ubuntu EC2 instance for dev in AWS 

## Prerequisites 

- Latest [OpenTofu](https://opentofu.org/). Use `brew` for [installation](https://opentofu.org/docs/intro/install/homebrew/). Or standalone [installer](https://opentofu.org/docs/intro/install/standalone/).
- rsync
- fswatch
- Set the `login` and `password` in the [.netrc](dotfiles/.netrc) file with your Github user and token
- Set the `GITHUB_TOKEN`, `DOCKER_USERNAME` and `DOCKER_PASSWORD` in the [.bashrc](dotfiles/.bashrc) file

## Creation
Edit the `terraform.tfvars` file and adjust owner, instance_type and iam_instance_profile values.
Make sure to refresh AWS credentials before running the following command.

```shell
make create
```

The command will output the public dns of the machine as well as an SSH connection string. It is recommended to use tmux to prevent commands from failing due to connection.

### Set up the repo
Adjust the `TARGET_REPO` variable in the [Makefile](Makefile) to set the local path the target repository.
The local changes will be synchronized to the remote dev instance automatically.

To copy the repo to the remote instance and start the watcher:
```shell
make sync-repo
```

### To connect with SSH
```shell
make connect
```

To install Kommander and Insights backend, run:
```
./boostrap.sh
```

### Open Kommander dashboard
it is possible to access Kommander Dashboard from the local browser via SSH tunnel and SOCKS proxy. 
Configure SOCKS proxy in the network settings (the default port is 1337) and then run the following target to obtain 
the credentials and open Kommander UI:

```shell
make dashboard
```

## Destroy and cleanup
```shell
make destroy clean
```
