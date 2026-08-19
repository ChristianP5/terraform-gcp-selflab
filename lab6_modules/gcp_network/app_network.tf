# Create the VPC Network
# VPC-PRIMARY (Application)
resource "google_compute_network" "app_network" {
  provider = google.app_project

  name                    = "${local.prefix}-vpc-primary"
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "app_subnetwork" {
  provider = google.app_project

  name          = "${google_compute_network.app_network.name}-subnetwork"
  ip_cidr_range = "10.229.1.0/24"
  region        = "asia-southeast2"
  network       = google_compute_network.app_network.id
}

resource "google_compute_subnetwork" "app_proxy_subnetwork" {
  provider = google.app_project

  name          = "${google_compute_network.app_network.name}-proxy-subnetwork"
  ip_cidr_range = "10.255.254.0/24"
  region        = "asia-southeast2"
  network       = google_compute_network.app_network.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

# Create the Cloud Router
resource "google_compute_router" "app_vpc_router" {
  provider = google.app_project

  name    = "${google_compute_network.app_network.name}-router"
  network = google_compute_network.app_network.id
  bgp {
    asn               = 64515
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
  }
}

# Create the Cloud NAT
resource "google_compute_router_nat" "app_vpc_nat" {
  provider = google.app_project

  name                               = "${google_compute_network.app_network.name}-nat"
  router                             = google_compute_router.app_vpc_router.name
  region                             = google_compute_router.app_vpc_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}