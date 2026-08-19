# Create Service Account to be used by the Apache web server instance
resource "google_service_account" "onprem_vm_sa" {
  account_id   = "${local.prefix}-onprem-vm-sa"
  display_name = "Temporary SA for On Prem VM Instance (Terraform)"
}

data "google_compute_image" "centos_image" {
  family  = "centos-stream-10"
  project = "centos-cloud"
}

resource "google_compute_instance" "onprem_instance" {
  name         = "${local.prefix}-onprem-instance"
  machine_type = "e2-micro"
  zone         = "asia-southeast2-a"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.centos_image.self_link
      size  = 25
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.onprem_subnetwork.name
  }
  service_account {
    # Google recommends custom service accounts that have
    # cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.onprem_vm_sa.email
    scopes = ["cloud-platform"]
  }
}

# Configure VPC Firewall rules
resource "google_compute_firewall" "firewall_rule_allow_iap_ssh" {
  name    = "${google_compute_network.onprem_network.name}-allow-iap-ssh"
  network = google_compute_network.onprem_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  priority      = 1000

}