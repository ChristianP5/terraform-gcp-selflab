locals {
  onprem_ranges = ["192.168.0.0/24"]
  gcp_ranges    = ["10.229.1.0/24", "10.229.125.0/24"]
}

# For Route Advertisements
# Import the Router
import {
  identity = {
    name    = "lab6-tf-vpc-internal-untrust-router"
    region  = "asia-southeast2"
    project = "c-host-project"
  }
  to = google_compute_router.internal_untrust_router
}

resource "google_compute_router" "internal_untrust_router" {
  provider = google.hub_project

  name    = "lab6-tf-vpc-internal-untrust-router"
  network = data.google_compute_network.internal_untrust.id

  lifecycle {
    ignore_changes = [name, network, bgp[0].asn, bgp[0].advertise_mode, bgp[0].advertised_groups]
  }

  bgp {
    asn               = 64515
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]

    dynamic "advertised_ip_ranges" {
      for_each = toset(local.gcp_ranges)
      content {
        range = advertised_ip_ranges.value
      }
    }
  }
}

# Import the VPC Networks
data "google_compute_network" "internal_untrust" {
  provider = google.hub_project

  name = "lab6-tf-vpc-internal-untrust"
}

data "google_compute_network" "internet_trust" {
  provider = google.hub_project

  name = "lab6-tf-vpc-internet-trust"
}

# For Static Routes (Internal to App)
# UNCOMMENT WHEN VPC NETWORK AND FORWARDING RULE IS CREATED
# data "google_compute_forwarding_rule" "internal_untrust" {
#   provider = google.hub_project
#   name     = "lab6-tf-vpc-internal-untrust-route-from-internal-frule"
# }

# resource "google_compute_route" "internal_untrust" {
#   for_each = toset(local.gcp_ranges)
#   provider = google.hub_project

#   name         = "from-untrust-to-${replace(split("/", each.value)[0], ".", "-")}"
#   dest_range   = each.value
#   network      = data.google_compute_network.internal_untrust.id
#   next_hop_ilb = data.google_compute_forwarding_rule.internal_untrust.ip_address
#   priority     = 100
# }

# For Firewall Rules
# Import Firewall Rule used by INTERNAL INBOUND NVA
import {
  identity = {
    name    = "lab6-tf-vpc-internal-untrust-fw-allow-internal-to-nva"
    project = "c-host-project"
  }

  to = google_compute_firewall.internal_untrust_nva_vm
}

resource "google_compute_firewall" "internal_untrust_nva_vm" {
  provider = google.hub_project

  name        = "lab6-tf-vpc-internal-untrust-fw-allow-internal-to-nva"
  network     = data.google_compute_network.internal_untrust.id
  description = "Creates firewall rule targeting the tagged Internal Inbound NVA Server instances to allow traffic from Internal IP Ranges.  "

  target_tags   = ["internal-inbound-nva"]
  source_ranges = local.onprem_ranges

  allow {
    protocol = "TCP"
  }

  allow {
    protocol = "UDP"
  }

  allow {
    protocol = "ICMP"
  }

  lifecycle {
    ignore_changes = [name, network, description, target_tags, allow]
  }
}

# For Firewall Rules
# Import Firewall Rule used by APP VM
# import {
#   identity = {
#     name    = "lab6-tf-vpc-internal-untrust-fw-allow-internal-to-nva"
#     project = "c-host-project"
#   }

#   to = google_compute_firewall.internal_untrust_app_vm
# }

# resource "google_compute_firewall" "internal_untrust_app_vm" {
#   provider = google.hub_project

#   name        = "lab6-tf-vpc-internal-untrust-fw-allow-internal-to-nva"
#   network     = data.google_compute_network.internal_untrust.id
#   description = "Creates firewall rule targeting the tagged Internal Inbound NVA Server instances to allow traffic from Internal IP Ranges.  "

#   target_tags   = ["internal-inbound-nva"]
#   source_ranges = local.onprem_ranges

#   allow {
#     protocol = "TCP"
#   }

#   allow {
#     protocol = "UDP"
#   }

#   allow {
#     protocol = "ICMP"
#   }

#   lifecycle {
#     ignore_changes = [name, network, description, target_tags, allow[0], allow[1], allow[2]]
#   }
# }


# For Static Routes (App to Internal)
# UNCOMMENT WHEN VPC NETWORK AND FORWARDING RULE IS CREATED
# data "google_compute_forwarding_rule" "to_internal" {
#   provider = google.hub_project
#   name     = "fe-route-to-internal-forwarding-rule"
# }

# resource "google_compute_route" "to_internal" {
#   for_each = toset(local.onprem_ranges)
#   provider = google.hub_project

#   name         = "from-app-to-${replace(split("/", each.value)[0], ".", "-")}"
#   dest_range   = each.value
#   network      = data.google_compute_network.internet_trust.id
#   next_hop_ilb = data.google_compute_forwarding_rule.to_internal.ip_address
#   priority     = 100
# }