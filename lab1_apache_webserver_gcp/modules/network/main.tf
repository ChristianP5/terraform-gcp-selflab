# Create a VPC network with custom MTU and routing mode
resource "google_compute_network" "vpc_network" {
  name                         = var.vpc_network_name
  auto_create_subnetworks      = false
  mtu                          = 1460
  routing_mode                 = "REGIONAL"
  bgp_best_path_selection_mode = "STANDARD"
}

# Create a subnetwork
resource "google_compute_subnetwork" "subnetwork" {
  name                     = var.subnetwork_name
  ip_cidr_range            = var.subnetwork_cidr
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