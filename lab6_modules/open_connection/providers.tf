provider "google" {
  alias   = "app_project"
  project = "c-gcp-project"
  region  = "asia-southeast2"
}

provider "google" {
  alias   = "hub_project"
  project = "c-host-project"
  region  = "asia-southeast2"
}