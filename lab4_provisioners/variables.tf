variable "user_name" {
  description = "The username for the new user"
  type        = string
}

variable "user_password" {
  description = "The password for the new user"
  type        = string
  sensitive   = true
}