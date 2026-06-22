output "subnetwork_name" {
  description = "The name of the subnetwork to which the Apache web server instance is connected"
  value       = google_compute_subnetwork.subnetwork.name
}

output "network_name" {
  description = "The name of the VPC network to which the Apache web server instance is connected"
  value       = google_compute_network.vpc_network.name
}