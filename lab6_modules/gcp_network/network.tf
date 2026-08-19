# Create the VPC Network
# VPC-INTERNET-UNTRUST
resource "google_compute_network" "internet_untrust_network" {
  provider = google.hub_project

  name                    = "${local.prefix}-vpc-internet-untrust"
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "internet_untrust_subnetwork" {
  provider = google.hub_project

  name          = "${google_compute_network.internet_untrust_network.name}-subnetwork"
  ip_cidr_range = "10.229.123.0/24"
  region        = "asia-southeast2"
  network       = google_compute_network.internet_untrust_network.id
}

resource "google_compute_subnetwork" "internet_untrust_proxy_subnetwork" {
  provider = google.hub_project

  name          = "${google_compute_network.internet_untrust_network.name}-proxy-subnetwork"
  ip_cidr_range = "10.255.255.0/24"
  region        = "asia-southeast2"
  network       = google_compute_network.internet_untrust_network.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

# Create the Cloud Router
resource "google_compute_router" "internet_untrust_router" {
  provider = google.hub_project

  name    = "${google_compute_network.internet_untrust_network.name}-router"
  network = google_compute_network.internet_untrust_network.id
  bgp {
    asn               = 64515
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
  }
}

# Create the Cloud NAT
resource "google_compute_router_nat" "internet_untrust_nat" {
  provider = google.hub_project

  name                               = "${google_compute_network.internet_untrust_network.name}-nat"
  router                             = google_compute_router.internet_untrust_router.name
  region                             = google_compute_router.internet_untrust_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# VPC-INTERNET-TRUST
resource "google_compute_network" "internet_trust_network" {
  provider = google.hub_project

  name                    = "${local.prefix}-vpc-internet-trust"
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "internet_trust_subnetwork" {
  provider = google.hub_project

  name          = "${google_compute_network.internet_trust_network.name}-subnetwork"
  ip_cidr_range = "10.229.125.0/24"
  region        = "asia-southeast2"
  network       = google_compute_network.internet_trust_network.id
}

# VPC-INTERNAL-UNTRUST
resource "google_compute_network" "internal_untrust_network" {
  provider = google.hub_project

  name                    = "${local.prefix}-vpc-internal-untrust"
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "internal_untrust_subnetwork" {
  provider = google.hub_project

  name          = "${google_compute_network.internal_untrust_network.name}-subnetwork"
  ip_cidr_range = "10.229.124.0/24"
  region        = "asia-southeast2"
  network       = google_compute_network.internal_untrust_network.id
}

# Create the Cloud Router
resource "google_compute_router" "internal_untrust_router" {
  provider = google.hub_project

  name    = "${google_compute_network.internal_untrust_network.name}-router"
  network = google_compute_network.internal_untrust_network.id
  lifecycle {
    ignore_changes = [bgp[0].advertised_ip_ranges]
  }
  bgp {
    asn               = 64515
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
  }
}

# Resources for Cloud VPN Tunnel
resource "google_compute_ha_vpn_gateway" "gcp_vpn_gateway" {
  provider = google.hub_project

  region  = "asia-southeast2"
  name    = "${google_compute_network.internal_untrust_network.name}-vpn-gateway"
  network = google_compute_network.internal_untrust_network.id
}

locals {
  secret = "toor"
  peer_ip = {
    a = {
      ip_address = "34.153.44.140"
    },
    b = {
      ip_address = "34.101.26.55"
    }
  }

  vpn_tunnels = {
    a = {
      name                  = "${google_compute_network.internal_untrust_network.name}-tunnel-1"
      peer_ip               = local.peer_ip["a"].ip_address
      shared_secret         = local.secret
      vpn_gateway_interface = 0
      # peer_external_gateway = google_compute_external_vpn_gateway.external_gateway["a"].id
    },
    b = {
      name                  = "${google_compute_network.internal_untrust_network.name}-tunnel-2"
      peer_ip               = local.peer_ip["b"].ip_address
      shared_secret         = local.secret
      vpn_gateway_interface = 1
      # peer_external_gateway = google_compute_external_vpn_gateway.external_gateway["b"].id
    }
  }
}

# resource "google_compute_external_vpn_gateway" "external_gateway" {
#   for_each = local.peer_ip
#   provider = google.hub_project

#   name            = "${google_compute_network.internal_untrust_network.name}-external-gateway-${each.key}"
#   redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
#   description     = "An externally managed VPN gateway"
#   interface {
#     id         = 0
#     ip_address = each.value.ip_address
#   }
# }

data "google_compute_ha_vpn_gateway" "onprem_gateway" {
  provider = google.hub_project

  name = "lab6-tf-vpc-onprem-vpn-gateway"
}

resource "google_compute_vpn_tunnel" "gcp_vpn_tunnel" {
  for_each = local.vpn_tunnels
  provider = google.hub_project

  name          = each.value.name
  shared_secret = each.value.shared_secret

  vpn_gateway = google_compute_ha_vpn_gateway.gcp_vpn_gateway.id
  # peer_external_gateway           = each.value.peer_external_gateway
  peer_gcp_gateway                = data.google_compute_ha_vpn_gateway.onprem_gateway.id
  peer_external_gateway_interface = 0
  vpn_gateway_interface           = each.value.vpn_gateway_interface

  router = google_compute_router.internal_untrust_router.name
  region = "asia-southeast2"
}

# Configure BGP Peerings for the VPN Tunnels
locals {
  peer_asn = 16550
  router_interfaces = {
    0 = {
      name       = "${google_compute_router.internal_untrust_router.name}-interface0"
      router     = google_compute_router.internal_untrust_router.name
      region     = "asia-southeast2"
      ip_range   = "169.254.0.2/30"
      vpn_tunnel = google_compute_vpn_tunnel.gcp_vpn_tunnel["a"].name
    },
    1 = {
      name       = "${google_compute_router.internal_untrust_router.name}-interface1"
      router     = google_compute_router.internal_untrust_router.name
      region     = "asia-southeast2"
      ip_range   = "169.254.1.2/30"
      vpn_tunnel = google_compute_vpn_tunnel.gcp_vpn_tunnel["b"].name
    }
  }
  router_peers = {
    0 = {
      name                      = "${google_compute_router.internal_untrust_router.name}-peer1"
      router                    = google_compute_router.internal_untrust_router.name
      region                    = "asia-southeast2"
      peer_ip_address           = "169.254.0.1"
      peer_asn                  = local.peer_asn
      advertised_route_priority = 100
      interface                 = google_compute_router_interface.router_interface["0"].name
    },
    1 = {
      name                      = "${google_compute_router.internal_untrust_router.name}-peer2"
      router                    = google_compute_router.internal_untrust_router.name
      region                    = "asia-southeast2"
      peer_ip_address           = "169.254.1.1"
      peer_asn                  = local.peer_asn
      advertised_route_priority = 100
      interface                 = google_compute_router_interface.router_interface["1"].name
    }
  }
}

resource "google_compute_router_interface" "router_interface" {
  for_each = local.router_interfaces
  provider = google.hub_project

  name       = each.value.name
  router     = google_compute_router.internal_untrust_router.name
  region     = "asia-southeast2"
  ip_range   = each.value.ip_range
  vpn_tunnel = each.value.vpn_tunnel
}

resource "google_compute_router_peer" "router_peer" {
  for_each = local.router_peers
  provider = google.hub_project

  name                      = each.value.name
  router                    = each.value.router
  region                    = each.value.region
  peer_ip_address           = each.value.peer_ip_address
  peer_asn                  = each.value.peer_asn
  advertised_route_priority = each.value.advertised_route_priority
  interface                 = each.value.interface
}