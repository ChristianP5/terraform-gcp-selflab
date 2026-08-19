# Create the Service Accounts for the Application Instances
resource "google_service_account" "app_instance_sa" {
  provider = google.app_project

  account_id   = "${local.prefix}-app-instance-sa"
  display_name = "Custom SA for Application VM Instance for Lab 6 (Terraform)"
}

# Create the Application VMs
locals {
  application_instances = {
    a = {
      name = "${local.prefix}-application-a"
      zone = "asia-southeast2-a"
    }
    b = {
      name = "${local.prefix}-application-b"
      zone = "asia-southeast2-b"
    }
  }
}
resource "google_compute_instance" "application_instances" {
  provider   = google.app_project
  for_each   = local.application_instances
  depends_on = [google_compute_router_nat.app_vpc_nat]

  name         = each.value.name
  machine_type = "e2-micro"
  zone         = each.value.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.centos_image.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.app_subnetwork.name
  }

  metadata_startup_script = "sudo su && dnf install -y httpd && systemctl enable httpd && systemctl start httpd && echo '<h1>Welcome to Lab 6 Load Balancer - ${each.key}</h1>' > /var/www/html/index.html"
  tags                    = [local.network_tags.load_balancer, local.network_tags.health_check, local.network_tags.iap_ssh, local.network_tags.app_server]

  service_account {
    email  = google_service_account.app_instance_sa.email
    scopes = ["cloud-platform"]
  }

  allow_stopping_for_update = true
}