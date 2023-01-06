resource "random_pet" "name" {}

locals {
  machine_name = "${var.owner}-${random_pet.name.id}-dev-machine"
  generated_key_name = "${var.owner}-${random_pet.name.id}-dev-key-pair"
}

resource "aws_instance" "ubuntu-dev-machine" {
  ami = var.ami
  instance_type = var.instance_type
  availability_zone = "us-west-2c"
  iam_instance_profile = var.iam_instance_profile
  # for insights only
  subnet_id = "subnet-0f04bbe3fcbf3ad1c"
  tags = {
    owner = var.owner
    expiration = var.expiration
    Name = local.machine_name
  }
  key_name = local.generated_key_name
  vpc_security_group_ids = [aws_security_group.main.id]

  # use this to increase the ebs volume size and iops
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type               = "gp3"
    volume_size =  var.base_volume_size
    iops                      = 16000
    throughput                = 1000
  }

  provisioner "file" {
      source      = "dotfiles/"
      destination = "/home/ubuntu"

      connection {
        type = "ssh"
        user = "ubuntu"
        agent = false
        host = self.public_dns
        private_key = tls_private_key.dev_key.private_key_pem
        timeout = "2m"
      }
  }

  provisioner "file" {
        source      = "bootstrap.sh"
        destination = "/home/ubuntu/bootstrap.sh"

        connection {
          type = "ssh"
          user = "ubuntu"
          agent = false
          host = self.public_dns
          private_key = tls_private_key.dev_key.private_key_pem
          timeout = "2m"
        }
    }

  provisioner "file" {
    source      = "install.bash"
    destination = "/home/ubuntu/install.bash"

    connection {
      type = "ssh"
      user = "ubuntu"
      agent = false
      host = self.public_dns
      private_key = tls_private_key.dev_key.private_key_pem
      timeout = "2m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/install.bash",
      "sudo /home/ubuntu/install.bash"
    ]

    connection {
      type = "ssh"
      user = "ubuntu"
      agent = false
      host = self.public_dns
      private_key = tls_private_key.dev_key.private_key_pem
      timeout = "5m"
    }
  }
}


### Second Drive
# resource "aws_ebs_volume" "ubuntu-dev-machine-volume" {
#   #count             = var.control_plane_imagefs_volume_enabled ? var.control_plane_count : 0
#   availability_zone = "us-west-2c"
#   type              = var.volume_type
#   size              = var.volume_size

#   #encrypted  = var.control_plane_kms_key_id != "" ? true : false
#   #kms_key_id = var.control_plane_kms_key_id

#   tags = {
#     owner = var.owner
#     expiration = var.expiration
#     Name = "${local.machine_name}-volume"
#   }
# }

# resource "aws_volume_attachment" "control_plane_imagefs" {
#   #count        = var.control_plane_imagefs_volume_enabled ? var.control_plane_count : 0
#   device_name  = "/dev/${var.volume_device}"
#   volume_id    = aws_ebs_volume.ubuntu-dev-machine-volume.id
#   instance_id  = aws_instance.ubuntu-dev-machine.id
#   force_detach = true
# }

resource "aws_security_group" "main" {
  name = "${local.machine_name}-sg"
  description = "Allow inbound SSH to manage machine"
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

resource "tls_private_key" "dev_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = local.generated_key_name
  public_key = tls_private_key.dev_key.public_key_openssh

  provisioner "local-exec" {    # Generate "terraform-key-pair.pem" in current directory
    command = <<-EOT
      echo '${tls_private_key.dev_key.private_key_pem}' > ./'${local.generated_key_name}'.pem
      chmod 400 ./'${local.generated_key_name}'.pem
    EOT
  }
}

### The Ansible inventory 
resource "local_file" "AnsibleInventory" {
  content = templatefile("inventory.tmpl", {
      private-dns = aws_instance.ubuntu-dev-machine.*.public_dns,  
      private-ip = aws_instance.ubuntu-dev-machine.*.public_ip,  
      private-id = aws_instance.ubuntu-dev-machine.*.id 
      key-file-path = "${local.generated_key_name}.pem"
      }
  )
  filename = "inventory"
}
