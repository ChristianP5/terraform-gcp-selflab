resource "google_network_connectivity_policy_based_route" "pbr_to_nva" {
  name        = "${local.prefix}-pbr-to-nva"
  description = "Routing Policy to NVA"
  network     = google_compute_network.app_network.id
  priority    = 1000

  filter {
    protocol_version = "IPV4"
    src_range        = "0.0.0.0/0"
    dest_range       = "0.0.0.0/0"
  }
  next_hop_ilb_ip = google_compute_forwarding_rule.nva_passhtrough_nlb.ip_address
}


resource "google_network_connectivity_policy_based_route" "pbr_to_nva_exceptions" {
  count       = local.scenario_2
  name        = "${local.prefix}-pbr-to-nva-exceptions"
  description = "Routing Policy to NVA Except not being applied to the NVA-VM"
  network     = google_compute_network.app_network.id
  priority    = 300

  filter {
    protocol_version = "IPV4"
    src_range        = "0.0.0.0/0"
    dest_range       = "0.0.0.0/0"
  }

  next_hop_other_routes = "DEFAULT_ROUTING"

  virtual_machine {
    tags = ["nva-vm"]
  }
}