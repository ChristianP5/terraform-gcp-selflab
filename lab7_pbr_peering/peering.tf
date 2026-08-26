resource "google_compute_network_peering" "app_nva_peering" {
  count        = local.scenario_1
  name         = "${local.prefix}-app-to-nva-peering"
  network      = google_compute_network.app_network.id
  peer_network = google_compute_network.nva_network[0].id

  import_custom_routes                = true
  export_custom_routes                = true
  import_subnet_routes_with_public_ip = true
  export_subnet_routes_with_public_ip = true
}

resource "google_compute_network_peering" "nva_app_peering" {
  count        = local.scenario_1
  name         = "${local.prefix}-nva-to-app-peering"
  network      = google_compute_network.nva_network[0].id
  peer_network = google_compute_network.app_network.id

  import_custom_routes                = true
  export_custom_routes                = true
  import_subnet_routes_with_public_ip = true
  export_subnet_routes_with_public_ip = true
}