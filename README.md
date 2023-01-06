# Create an Ubuntu EC2 instance for dev in AWS 

## Prerequisites 

- Terraform v0.13.7. Use [tfenv](https://github.com/tfutils/tfenv) for installation. If you're working with an M1 Mac laptop, try installing Terraform v1.0.11.
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
make sync
```

### To connect with SSH
```shell
make connect
```

To install Kommander and Insights backend, run:
```
./boostrap.sh
```

## Destroy and cleanup
```shell
make destroy clean
```
