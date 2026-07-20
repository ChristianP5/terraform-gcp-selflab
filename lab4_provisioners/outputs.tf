output "instance_ip" {
  description = "The external IP address of the main instance"
  value = google_compute_instance.main_instance.network_interface.0.access_config.0.nat_ip
}