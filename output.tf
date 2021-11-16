output "ec2_arn" {
  value = aws_instance.ubuntu-dev-machine.arn     # Value depends on resource name and type ( same as that of main.tf)
}

output "machine_name" {
  value = local.machine_name
}

output "public_dns" {
  value = aws_instance.ubuntu-dev-machine.public_dns
}

output "connections" {
  value = "ssh -i ./'${local.generated_key_name}'.pem ubuntu@${aws_instance.ubuntu-dev-machine.public_dns}"
}