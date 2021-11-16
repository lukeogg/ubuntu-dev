variable "ami" {                       # We are declaring the variable ami here which we used in main.tf
  type = string      
}

variable "instance_type" {             # We are declaring the variable instance_type here which we used in main.tf
  type = string 
}

variable "owner" {
  type = string 
}

variable "expiration" {
  type = string
  default = "1h"
}