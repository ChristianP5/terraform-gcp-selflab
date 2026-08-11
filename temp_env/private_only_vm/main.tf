# Create a VPC network with custom MTU and routing mode
resource "google_compute_network" "vpc_network" {
  name                         = "c-temp-vpc-tf"
  auto_create_subnetworks      = false
  mtu                          = 1460
  routing_mode                 = "REGIONAL"
  bgp_best_path_selection_mode = "STANDARD"
}

# Create a subnetwork
resource "google_compute_subnetwork" "subnetwork" {
  name                     = "${google_compute_network.vpc_network.name}-ase2-subnet1"
  ip_cidr_range            = "10.0.0.0/24"
  region                   = "asia-southeast2"
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = true
}

# Create a Cloud NAT Gateway
resource "google_compute_router" "router" {
  name    = "${google_compute_network.vpc_network.name}-router"
  region  = google_compute_subnetwork.subnetwork.region
  network = google_compute_network.vpc_network.id

  bgp {
    asn = 64514
  }
}


resource "google_compute_router_nat" "nat" {
  name                               = "${google_compute_network.vpc_network.name}-natgw"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Create Service Account to be used by the Apache web server instance
resource "google_service_account" "primary_sa" {
  account_id   = "c-temp-tf-sa"
  display_name = "Temporary SA for Temporary VM Instance (Terraform)"
}

data "google_compute_image" "centos_image" {
  family  = "centos-stream-10"
  project = "centos-cloud"
}

resource "google_compute_instance" "primary_instance" {
  name         = "c-temp-tf-instance"
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
    subnetwork = google_compute_subnetwork.subnetwork.name
  }
  service_account {
    # Google recommends custom service accounts that have
    # cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.primary_sa.email
    scopes = ["cloud-platform"]
  }
}

# Configure VPC Firewall rules
resource "google_compute_firewall" "firewall_rule_allow_iap_ssh" {
  name    = "${google_compute_network.vpc_network.name}-allow-iap-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  priority      = 1000

}
