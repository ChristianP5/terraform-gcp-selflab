locals {
  prefix = "c-temp-lab-publicvm"
}

# Create a VPC network with custom MTU and routing mode
resource "google_compute_network" "vpc_network" {
  name                         = "${local.prefix}-vpc-tf"
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
  account_id   = "${local.prefix}-tf-sa"
  display_name = "Temporary SA for Temporary VM Instance (Terraform)"
}

data "google_compute_image" "centos_image" {
  family  = "centos-stream-10"
  project = "centos-cloud"
}

data "google_compute_image" "debian_image" {
  family  = "debian-13"
  project = "debian-cloud"
}

locals {
  effective_os = var.os == "CentOS" ? data.google_compute_image.centos_image.self_link : data.google_compute_image.debian_image.self_link
  effective_allowed_predefined_inbound_ports = {
    80 : var.allow_http
    8080 : var.allow_http
    443 : var.allow_http
  }

  effective_allowed_custom_inbound_ports_list     = { for i, v in var.allow_custom_ports : v => true }
  effective_allowed_predefined_inbound_ports_list = { for k, v in local.effective_allowed_predefined_inbound_ports : k => v if v == true }
  effective_allowed_inbound_ports_list            = merge(local.effective_allowed_custom_inbound_ports_list, local.effective_allowed_predefined_inbound_ports_list)
}

resource "google_compute_address" "primary_instance_address" {
  count = var.vm_count
  name = "${local.prefix}-tf-instance-${count.index}-ip"
}

resource "google_compute_instance" "primary_instance" {
  count = var.vm_count
  name         = "${local.prefix}-tf-instance-${count.index}"
  machine_type = "e2-micro"
  zone         = "asia-southeast2-a"

  boot_disk {
    initialize_params {
      image = local.effective_os
      size  = 25
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnetwork.name

    access_config {
      // Ephemeral public IP
      nat_ip = google_compute_address.primary_instance_address[count.index].address
    }
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
    ports    = [22]
  }
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  priority      = 1000

}


resource "google_compute_firewall" "firewall_rule_allow_custom" {
  name    = "${google_compute_network.vpc_network.name}-allow-custom"
  network = google_compute_network.vpc_network.name



  dynamic "allow" {
    for_each = local.effective_allowed_inbound_ports_list
    content {
      protocol = "tcp"
      ports    = [allow.key]
    }
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  priority      = 1000

}