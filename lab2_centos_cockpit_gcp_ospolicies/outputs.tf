output "os_policy" {
  description = "The OS policy file uploaded to the Storage Bucket."
  value       = "gs://${google_storage_bucket.os_policy_bucket.name}/${google_storage_bucket_object.os_policy_object.name}"
}

output "ubuntu_vm_instance" {
  description = "The Ubuntu VM instance IP Address."
  value       = google_compute_instance.main_instance.network_interface[0].access_config[0].nat_ip
}