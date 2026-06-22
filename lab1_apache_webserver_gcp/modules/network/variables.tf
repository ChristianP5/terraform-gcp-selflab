variable "vpc_network_name" {
  type        = string
  description = "The name of the VPC network to be created"
}

variable "subnetwork_name" {
  type        = string
  description = "The name of the subnetwork to be created"
}

variable "subnetwork_cidr" {
  type        = string
  description = "The CIDR range for the subnetwork"
  default     = "10.0.0.0/24"
}