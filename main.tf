resource "aws_instance" "my-machine" {          # This is Resource block where we define what we need to create

  ami = var.ami                                 # ami is required as we need ami in order to create an instance
  instance_type = var.instance_type             # Similarly we need instance_type
  tags = {
    owner = var.owner
    AWS_EXPIRATION = var.expiration
    # map(
    #   "Name", "${local.cluster_name}-bastion-${count.index}",
    #   "konvoy/nodeRoles", "bastion"
    # )
  }
  key_name = "deployer-key"
  vpc_security_group_ids = [aws_security_group.main.id]

  # connection {
  #   type        = "ssh"
  #   host        = self.public_ip
  #   user        = "ubuntu"
  #   private_key = file("/home/rahul/Jhooq/keys/aws/aws_key")
  #   timeout     = "4m"
  # }
}

resource "aws_security_group" "main" {
  egress = [
    {
      cidr_blocks      = [ "0.0.0.0/0", ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    }
  ]
 ingress                = [
   {
     cidr_blocks      = [ "0.0.0.0/0", ]
     description      = ""
     from_port        = 22
     ipv6_cidr_blocks = []
     prefix_list_ids  = []
     protocol         = "tcp"
     security_groups  = []
     self             = false
     to_port          = 22
  }
  ]
}


resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = ""
}