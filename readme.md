# Create an ubuntu machine for dev in aws 

## Prerequisites 
Requires Terraform v0.13.7.


## Creation
To install apply the terraform files. This will generate a key pair and create the machine.

``` shell
terraform init
terraform apply
```

The command will output the public dns of the machine as well as an SSH connection string. It is recommended to use tmux to prevent commands from failing due to connection.