variable "allow_http" {
  type        = bool
  description = "Allow Inbound HTTP (TCP 80 and 8080): true or false"
}

variable "allow_https" {
  type        = bool
  description = "Allow Inbound HTTPS (TCP 443): true or false"
}

variable "allow_custom_ports" {
  type        = list(number)
  description = "Custom TCP Ports to open"
}

variable "os" {
  type        = string
  description = "Acceptable values: CentOS, Debian"
}

variable "vm_count" {
  type        = number
  description = "Number of Virtual Machines"
}

variable "allow_custom_labels" {
  type        = map(string)
  description = "Custom Labels assigned to Compute Engine Instances"
}

variable "custom_assign_iam_roles" {
  type        = map
  description = "Custom IAM Role Assignments on the Service Account used by the Compute Engine Instances"
}