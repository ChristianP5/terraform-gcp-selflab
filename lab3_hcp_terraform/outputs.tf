output "file" {
  description = "The GCS file path"
  value       = "gs://${google_storage_bucket.main-bucket.name}/${google_storage_bucket_object.main-object.name}"
}