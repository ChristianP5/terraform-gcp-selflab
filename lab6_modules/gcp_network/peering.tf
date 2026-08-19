# VPC Network Peering
resource "google_compute_network_peering" "peering_app_to_internet_trust" {
  provider = google.app_project

  name                 = "${local.prefix}-peering-app-to-internet-trust"
  network              = google_compute_network.app_network.self_link
  peer_network         = google_compute_network.internet_trust_network.self_link
  export_custom_routes = true
  import_custom_routes = true
}

resource "google_compute_network_peering" "peering_internet_trust_to_app" {
  provider   = google.hub_project
  depends_on = [google_compute_network_peering.peering_app_to_internet_trust]

  name                 = "${local.prefix}-peering-internet-trust-to-app"
  network              = google_compute_network.internet_trust_network.self_link
  peer_network         = google_compute_network.app_network.self_link
  export_custom_routes = true
  import_custom_routes = true
}