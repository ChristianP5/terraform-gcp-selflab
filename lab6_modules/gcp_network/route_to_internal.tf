locals {
  route_to_internal_lb_backends = {
    a = {
      name = "${local.prefix}-route-to-internal-lb-instance-group-a"
      zone = "asia-southeast2-a"
      instances = [
        google_compute_instance.internal_inbound_nva_instances["a"].id,
      ]
    },
    b = {
      name = "${local.prefix}-route-to-internal-lb-instance-group-b"
      zone = "asia-southeast2-b"
      instances = [
        google_compute_instance.internal_inbound_nva_instances["b"].id,
      ]
    }
  }
}

# Create the Internal Passthrough Network Load Balancer
locals {
  unmigs = { for k, v in google_compute_instance_group.internal_inbound_unmig : k => v }
}

resource "google_compute_region_health_check" "route_to_internal" {
  provider = google.hub_project

  name               = "${google_compute_network.internet_trust_network.name}-route-to-internal-hc"
  region             = "asia-southeast2"
  timeout_sec        = 1
  check_interval_sec = 1

  tcp_health_check {
    port = "80"
  }
}

resource "google_compute_region_backend_service" "route_to_internal" {
  provider = google.hub_project

  name                  = "${google_compute_network.internet_trust_network.name}-route-to-internal-backend-service"
  region                = "asia-southeast2"
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  health_checks         = [google_compute_region_health_check.route_to_internal.id]

  dynamic "backend" {
    for_each = local.unmigs
    content {
      group          = backend.value.id
      balancing_mode = "CONNECTION"
    }
  }
}

# resource "google_compute_forwarding_rule" "route_to_internal" {
#   provider = google.hub_project

#   name                  = "${google_compute_network.internet_trust_network.name}-route-to-internal-frule"
#   backend_service       = google_compute_region_backend_service.route_to_internal.id
#   region                = "asia-southeast2"
#   ip_protocol           = "TCP"
#   load_balancing_scheme = "INTERNAL"
#   all_ports             = true
#   allow_global_access   = true
#   network               = google_compute_network.internet_trust_network.id
#   subnetwork            = google_compute_subnetwork.internet_trust_subnetwork.id
# }