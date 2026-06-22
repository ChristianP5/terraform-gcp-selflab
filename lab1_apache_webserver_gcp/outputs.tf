output "apache_webserver_instance_ip" {
  description = "The public IP address of the Apache web server instance"
  value       = "http://${module.apache_webserver_instance.apache_webserver_instance_ip}:80"
}