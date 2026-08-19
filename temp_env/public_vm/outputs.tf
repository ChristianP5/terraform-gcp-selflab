output "vm_address" {
  value       = google_compute_address.primary_instance_address[*].address
  description = "IP Address of the Virtual Machine"
}