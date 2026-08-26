locals {
  scenario_1     = var.scenario == 1 ? 1 : 0
  scenario_2     = var.scenario == 2 ? 1 : 0
  nva_network    = var.scenario == 1 ? google_compute_network.nva_network[0] : google_compute_network.app_network
  nva_subnetwork = var.scenario == 1 ? google_compute_subnetwork.nva_subnetwork[0] : google_compute_subnetwork.app_subnetwork
}
resource "google_compute_network" "nva_network" {
  count                        = local.scenario_1
  name                         = "${local.prefix}-nva-vpc"
  auto_create_subnetworks      = false
  mtu                          = 1460
  routing_mode                 = "REGIONAL"
  bgp_best_path_selection_mode = "STANDARD"
}

# Create a subnetwork
resource "google_compute_subnetwork" "nva_subnetwork" {
  count                    = local.scenario_1
  name                     = "${google_compute_network.nva_network[0].name}-ase2-subnet1"
  ip_cidr_range            = "10.255.0.0/24"
  region                   = "asia-southeast2"
  network                  = google_compute_network.nva_network[0].id
  private_ip_google_access = true
}

# Create a Cloud NAT Gateway
resource "google_compute_router" "nva_router" {
  count   = local.scenario_1
  name    = "${google_compute_network.nva_network[0].name}-router"
  region  = google_compute_subnetwork.nva_subnetwork[0].region
  network = google_compute_network.nva_network[0].id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nva_nat" {
  count                              = local.scenario_1
  name                               = "${google_compute_network.nva_network[0].name}-natgw"
  router                             = google_compute_router.nva_router[0].name
  region                             = google_compute_router.nva_router[0].region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

}

resource "google_compute_address" "nva_forwarded_nat_ip" {
  count = 2
  name   = "${local.prefix}-nva-forwarded-nat-ip-${count.index}"
  region = "asia-southeast2"

}

# Configure VPC Firewall rules
resource "google_compute_firewall" "nva_network_firewall_rule_allow_iap_ssh" {
  count   = local.scenario_1
  name    = "${google_compute_network.nva_network[0].name}-allow-iap-ssh"
  network = google_compute_network.nva_network[0].name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  priority      = 1000

}

# Configure VPC Firewall rules
resource "google_compute_firewall" "nva_network_firewall_rule_allow_icmp" {
  count   = local.scenario_1
  name    = "${google_compute_network.nva_network[0].name}-allow-icmp"
  network = google_compute_network.nva_network[0].name

  allow {
    protocol = "icmp"
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  priority      = 1000

}



resource "google_compute_instance" "nva_instance" {
  name         = "${local.prefix}-nva-instance"
  machine_type = "e2-micro"
  zone         = "asia-southeast2-a"
  tags         = ["nva-vm"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.centos_image.self_link
      size  = 25
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = local.nva_subnetwork.name
  }

  can_ip_forward = true

  service_account {
    # Google recommends custom service accounts that have
    # cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.primary_sa.email
    scopes = ["cloud-platform"]
  }
}


# Internal Passthrough Network Load Balancer
resource "google_compute_region_health_check" "nva_passhtrough_nlb" {
  name   = "${local.prefix}-nva-nlb-hc"
  region = "asia-southeast2"

  tcp_health_check {
    port = "80"
  }
}

resource "google_compute_instance_group" "nva_passhtrough_nlb" {
  name        = "${local.prefix}-nva-instances-a"
  description = "Terraform test instance group for NVA"

  instances = [
    google_compute_instance.nva_instance.id
  ]

  zone = "asia-southeast2-a"
}

resource "google_compute_forwarding_rule" "nva_passhtrough_nlb" {
  name                  = "${local.prefix}-nva-nlb-forwarding-rule"
  backend_service       = google_compute_region_backend_service.nva_passhtrough_nlb.id
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL"
  all_ports             = true
  network               = local.nva_network.id
  subnetwork            = local.nva_subnetwork.id
}

resource "google_compute_region_backend_service" "nva_passhtrough_nlb" {
  name                  = "${local.prefix}-nva-nlb-backend-service"
  region                = "asia-southeast2"
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  health_checks         = [google_compute_region_health_check.nva_passhtrough_nlb.id]
  backend {
    group          = google_compute_instance_group.nva_passhtrough_nlb.id
    balancing_mode = "CONNECTION"
  }
}



# allow all access from health check ranges
resource "google_compute_firewall" "nva_network_firewall_rule_allow_hc" {
  name          = "${local.nva_network.name}-allow-hc"
  direction     = "INGRESS"
  network       = local.nva_network.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16", "35.235.240.0/20"]
  allow {
    protocol = "tcp"
  }
}