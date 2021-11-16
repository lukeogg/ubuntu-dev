variable "ami" {
  type = string      
}

variable "instance_type" {
  type = string 
}

variable "owner" {
  type = string 
}

variable "expiration" {
  type = string
  default = "8h"
  description = "Time before cloudkeeper cleans up resources"
}