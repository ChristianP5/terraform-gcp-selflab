locals {
  prefix = "lab6-tf"
}

# Create the VPC Network representing a On Premises Network
resource "google_compute_network" "onprem_network" {
  name                    = "${local.prefix}-vpc-onprem"
  auto_create_subnetworks = false
  mtu                     = 1460
}

# Create its Subnetwork
resource "google_compute_subnetwork" "onprem_subnetwork" {
  name          = "${google_compute_network.onprem_network.name}-subnet"
  ip_cidr_range = "192.168.0.0/16"
  region        = "asia-southeast2"
  network       = google_compute_network.onprem_network.id
}

# Create the Cloud Router
resource "google_compute_router" "onprem_router" {
  name    = "${google_compute_network.onprem_network.name}-router"
  network = google_compute_network.onprem_network.id
  bgp {
    asn               = 16550
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
  }
}

resource "google_compute_router_nat" "onprem_nat" {
  name                               = "${google_compute_network.onprem_network.name}-nat"
  router                             = google_compute_router.onprem_router.name
  region                             = google_compute_router.onprem_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}


# Resources for Cloud VPN Tunnel
# UNCOMMENT WHEN VPN GATEWAY IS CREATED
# data "google_compute_ha_vpn_gateway" "gcp_gateway" {
#   name = "lab6-tf-vpc-internal-untrust-vpn-gateway"
# }

# resource "google_compute_ha_vpn_gateway" "onprem_vpn_gateway" {
#   region  = "asia-southeast2"
#   name    = "${google_compute_network.onprem_network.name}-vpn-gateway"
#   network = google_compute_network.onprem_network.id
# }

locals {
  secret = "toor"
  peer_ip = {
    a = {
      ip_address = "34.153.44.18"
    },
    b = {
      ip_address = "34.184.110.255"
    }
  }
  vpn_tunnels = {
    a = {
      name                  = "${google_compute_network.onprem_network.name}-tunnel-1"
      peer_ip               = local.peer_ip["a"].ip_address
      shared_secret         = local.secret
      vpn_gateway_interface = 0
      # peer_external_gateway = google_compute_external_vpn_gateway.external_gateway["a"].id
    },
    b = {
      name                  = "${google_compute_network.onprem_network.name}-tunnel-2"
      peer_ip               = local.peer_ip["b"].ip_address
      shared_secret         = local.secret
      vpn_gateway_interface = 1
      # peer_external_gateway = google_compute_external_vpn_gateway.external_gateway["b"].id
    }
  }
}

# UNCOMMENT WHEN VPN GATEWAY IS CREATED
# resource "google_compute_vpn_tunnel" "onprem_vpc_tunnel" {
#   for_each = local.vpn_tunnels

#   name          = each.value.name
#   shared_secret = each.value.shared_secret

#   vpn_gateway = google_compute_ha_vpn_gateway.onprem_vpn_gateway.id
#   # peer_external_gateway           = each.value.peer_external_gateway
#   peer_gcp_gateway = data.google_compute_ha_vpn_gateway.gcp_gateway.id

#   peer_external_gateway_interface = 0
#   vpn_gateway_interface           = each.value.vpn_gateway_interface

#   router = google_compute_router.onprem_router.name
#   region = "asia-southeast2"
# }

# Configure BGP Peerings for the VPN Tunnels
locals {
  peer_asn = 64515
  router_interfaces = {
    0 = {
      name       = "${google_compute_router.onprem_router.name}-interface0"
      router     = google_compute_router.onprem_router.name
      region     = "asia-southeast2"
      ip_range   = "169.254.0.1/30"
      # UNCOMMENT WHEN VPN GATEWAY IS CREATED
      # vpn_tunnel = google_compute_vpn_tunnel.onprem_vpc_tunnel["a"].name
    },
    1 = {
      name       = "${google_compute_router.onprem_router.name}-interface1"
      router     = google_compute_router.onprem_router.name
      region     = "asia-southeast2"
      ip_range   = "169.254.1.1/30"
      # UNCOMMENT WHEN VPN GATEWAY IS CREATED
      # vpn_tunnel = google_compute_vpn_tunnel.onprem_vpc_tunnel["b"].name
    }
  }
  router_peers = {
    0 = {
      name                      = "${google_compute_router.onprem_router.name}-peer1"
      router                    = google_compute_router.onprem_router.name
      region                    = "asia-southeast2"
      peer_ip_address           = "169.254.0.2"
      peer_asn                  = local.peer_asn
      advertised_route_priority = 100
      # UNCOMMENT WHEN VPN GATEWAY IS CREATED
      # interface                 = google_compute_router_interface.router_interface["0"].name
    },
    1 = {
      name                      = "${google_compute_router.onprem_router.name}-peer2"
      router                    = google_compute_router.onprem_router.name
      region                    = "asia-southeast2"
      peer_ip_address           = "169.254.1.2"
      peer_asn                  = local.peer_asn
      advertised_route_priority = 100
      # UNCOMMENT WHEN VPN GATEWAY IS CREATED
      # interface                 = google_compute_router_interface.router_interface["1"].name
    }
  }
}

# UNCOMMENT WHEN VPN GATEWAY IS CREATED
# resource "google_compute_router_interface" "router_interface" {
#   for_each = local.router_interfaces

#   name       = each.value.name
#   router     = google_compute_router.onprem_router.name
#   region     = "asia-southeast2"
#   ip_range   = each.value.ip_range
#   vpn_tunnel = each.value.vpn_tunnel
# }

# resource "google_compute_router_peer" "router_peer" {
#   for_each = local.router_peers

#   name                      = each.value.name
#   router                    = each.value.router
#   region                    = each.value.region
#   peer_ip_address           = each.value.peer_ip_address
#   peer_asn                  = each.value.peer_asn
#   advertised_route_priority = each.value.advertised_route_priority
#   interface                 = each.value.interface
# }