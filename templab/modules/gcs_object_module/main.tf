variable "bucket_name" {
  description = "The name of the GCS bucket"
  type        = string
}

resource "google_storage_bucket_object" "module_file" {
  name     = "module_file.txt"
  content  = "This is the module file."
  bucket   = var.bucket_name
}