output "apache_webserver_instance_ip" {
  description = "The public IP address of the Apache web server instance"
  value       = google_compute_instance.apache_webserver_instance.network_interface.0.access_config.0.nat_ip
}