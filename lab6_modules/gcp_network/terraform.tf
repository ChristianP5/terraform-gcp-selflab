terraform {
  backend "gcs" {
    bucket = "c_terraform_remote_state_bucket"
    prefix = "lab6/network/state"
  }
}