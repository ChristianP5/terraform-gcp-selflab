# Route to Non-Peered VPC Networks
locals {
  non_peered_ip_ranges = ["10.229.123.0/24", "10.229.124.0/24"]
}

# UNCOMMENT WHEN VPC NETWORK IS PROVISIONED
# data "google_compute_forwarding_rule" "app_to_internal_gcp" {
#   provider = google.hub_project
#   name     = "fe-route-to-internal-forwarding-rule"
# }

# resource "google_compute_route" "app_to_internal_gcp" {
#   for_each = toset(local.non_peered_ip_ranges)
#   provider = google.hub_project

#   name         = "from-app-to-${replace(split("/", each.value)[0], ".", "-")}"
#   dest_range   = each.value
#   network      = google_compute_network.internet_trust_network.id
#   next_hop_ilb = data.google_compute_forwarding_rule.app_to_internal_gcp.ip_address
#   priority     = 100
# }