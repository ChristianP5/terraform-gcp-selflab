terraform {
  backend "gcs" {
    bucket = "c_terraform_remote_state_bucket"
    prefix = "lab5/state"
  }
}