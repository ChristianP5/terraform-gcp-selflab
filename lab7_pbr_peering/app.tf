locals {
  host_instances = {
    a = {
      az = "asia-southeast2-a"
    },
    b = {
      az = "asia-southeast2-b"
    }
  }

  prefix = "c-lab7-tf"
}

# Create Service Account to be used by the Apache web server instance
resource "google_service_account" "primary_sa" {
  account_id   = "${local.prefix}-vm-sa"
  display_name = "Temporary SA for Temporary VM Instance (Terraform)"
}

data "google_compute_image" "centos_image" {
  family  = "centos-stream-10"
  project = "centos-cloud"
}

resource "google_compute_network" "app_network" {
  name                         = "${local.prefix}-app-vpc"
  auto_create_subnetworks      = false
  mtu                          = 1460
  routing_mode                 = "REGIONAL"
  bgp_best_path_selection_mode = "STANDARD"
}

# Create a subnetwork
resource "google_compute_subnetwork" "app_subnetwork" {
  name                     = "${google_compute_network.app_network.name}-ase2-subnet1"
  ip_cidr_range            = "10.0.0.0/24"
  region                   = "asia-southeast2"
  network                  = google_compute_network.app_network.id
  private_ip_google_access = true
}

# Create a Cloud NAT Gateway
resource "google_compute_router" "app_router" {
  name    = "${google_compute_network.app_network.name}-router"
  region  = google_compute_subnetwork.app_subnetwork.region
  network = google_compute_network.app_network.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "app_nat" {
  name                               = "${google_compute_network.app_network.name}-natgw"
  router                             = google_compute_router.app_router.name
  region                             = google_compute_router.app_router.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips = [ google_compute_address.nva_forwarded_nat_ip[0].self_link ]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  # Added to allow IP Forwarded IP Ranges to be NAT
  rules {
    rule_number = 1
    match       = "inIpRange(source.ip, '10.0.0.0/24')"
    action {
      source_nat_active_ips = [google_compute_address.nva_forwarded_nat_ip[1].self_link]
    }
  }
}



resource "google_compute_instance" "app_instance" {
  for_each     = local.host_instances
  name         = "${local.prefix}-app-instance-${each.key}"
  machine_type = "e2-micro"
  zone         = each.value.az

  boot_disk {
    initialize_params {
      image = data.google_compute_image.centos_image.self_link
      size  = 25
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.app_subnetwork.name
  }
  service_account {
    # Google recommends custom service accounts that have
    # cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.primary_sa.email
    scopes = ["cloud-platform"]
  }
}

# Configure VPC Firewall rules
resource "google_compute_firewall" "app_network_firewall_rule_allow_iap_ssh" {
  name    = "${google_compute_network.app_network.name}-allow-iap-ssh"
  network = google_compute_network.app_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  priority      = 1000
}

resource "google_compute_firewall" "app_network_firewall_rule_allow_icmp" {
  name    = "${google_compute_network.app_network.name}-allow-icmp"
  network = google_compute_network.app_network.name

  allow {
    protocol = "icmp"
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  priority      = 1000

}