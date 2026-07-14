terraform {
  backend "gcs" {
    bucket = "c_terraform_remote_state_bucket"
    prefix = "templab/state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.37.0"
    }
  }
}