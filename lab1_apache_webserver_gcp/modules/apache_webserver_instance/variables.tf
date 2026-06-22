variable "prefix" {
  type        = string
  description = "A prefix to append to resource names for uniqueness"
  default     = ""
}

variable "message" {
  description = "Message to display on the web server"
  type        = string
  default     = "Hello, World!"
}

variable "subnetwork_name" {
  type        = string
  description = "The name of the subnetwork to which the Apache web server instance will be connected"
}

variable "network_name" {
  type        = string
  description = "The name of the VPC network to which the Apache web server instance will be connected"
}