output "ec2_arn" {
  value = aws_instance.my-machine.arn     # Value depends on resource name and type ( same as that of main.tf)
}  