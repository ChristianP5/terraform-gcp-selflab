locals {
  prefix                  = "c-lab5-tf"
  auto_create_subnetworks = false
}

resource "google_compute_network" "main_network" {
  name = "${local.prefix}-vpc-network"
  auto_create_subnetworks = false
}


resource "google_compute_subnetwork" "main_subnetwork" {
  name          = "${google_compute_network.main_network.name}-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  region        = "asia-southeast2"
  network       = google_compute_network.main_network.id

}

resource "google_compute_subnetwork" "proxy_subnetwork" {
  name          = "${google_compute_network.main_network.name}-proxy-subnetwork"
  ip_cidr_range = "10.255.255.0/24"
  region        = "asia-southeast2"
  network       = google_compute_network.main_network.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

resource "google_compute_router" "main_router" {
  name    = "${google_compute_network.main_network.name}-router"
  region  = google_compute_subnetwork.proxy_subnetwork.region
  network = google_compute_network.main_network.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "main_nat" {
  name                               = "${google_compute_network.main_network.name}-nat"
  router                             = google_compute_router.main_router.name
  region                             = google_compute_router.main_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}