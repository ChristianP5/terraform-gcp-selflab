# Create Service Account to be used by the Apache web server instance
resource "google_service_account" "apache_webserver_sa" {
  account_id   = "apache-webserver-sa"
  display_name = "Custom SA for VM Instance"
}

data "google_compute_image" "centos_image" {
  family  = "centos-stream-10"
  project = "centos-cloud"
}

resource "google_compute_instance" "apache_webserver_instance" {
  name         = "${var.prefix}-apache-webserver-instance"
  machine_type = "e2-micro"
  zone         = "asia-southeast2-a"
  tags         = ["web-server"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.centos_image.self_link
      size  = 25
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = var.subnetwork_name

    access_config {
      // Ephemeral public IP
    }
  }

  metadata_startup_script = "sudo su && dnf install httpd -y && echo \"${var.message}\" > /var/www/html/index.html && systemctl enable httpd && systemctl start httpd"

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.apache_webserver_sa.email
    scopes = ["cloud-platform"]
  }
}

# Configure VPC Firewall rules
resource "google_compute_firewall" "firewall_rule_allow_web_traffic" {
  name    = "${var.network_name}-allow-web-traffic"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  priority      = 1000

  target_tags = google_compute_instance.apache_webserver_instance.tags
}

# Configure VPC Firewall rules
resource "google_compute_firewall" "firewall_rule_allow_iap_ssh" {
  name    = "${var.network_name}-allow-iap-ssh"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  priority      = 1000

}
