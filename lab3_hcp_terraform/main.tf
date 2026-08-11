locals {
  prefix = "c-lab59"
}

resource "google_storage_bucket" "main-bucket" {
  name                        = "${local.prefix}-bucket"
  location                    = "ASIA-SOUTHEAST2"
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "main-object" {
  name    = "hello.txt"                             
  content = "This file was made using HCP Terraform" 
  bucket  = google_storage_bucket.main-bucket.name
}