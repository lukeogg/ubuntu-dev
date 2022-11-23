variable "ami" {
  type = string
}

variable "iam_instance_profile" {
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

variable "volume_type" {
  description = "[The type for the dedicated volume. Should be gp2 or io1"
  default     = "gp2"
}

variable "base_volume_size" {
  description = "The size for the dedicated volume"
  default     = "250"
}

variable "volume_size" {
  description = "The size for the dedicated volume"
  default     = "160"
}

variable "volume_device" {
  description = "The device to mount the volume at."
  default     = "xvdb"
}