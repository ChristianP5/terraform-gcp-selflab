terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.37.0"
    }
  }

  cloud {

    organization = "Christian_Labs"

    workspaces {
      name = "Lab_3"
    }
  }
}