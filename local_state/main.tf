output "My_Project_ID" {
  value = "Hello"
}

resource "google_service_account" "my_temp_service_account" {
  account_id   = "temp-tf-sa"
  display_name = "Temporary Service Account for Terraform"
}