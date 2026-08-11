variable "admin_user" {
  description = "The admin user for the VM"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "The admin password for the VM"
  type        = string
  sensitive   = true
}