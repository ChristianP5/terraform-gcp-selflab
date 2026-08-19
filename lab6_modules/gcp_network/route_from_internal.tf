locals {
  route_from_internal_lb_backends = {
    a = {
      name = "${local.prefix}-route-from-internal-lb-instance-group-a"
      zone = "asia-southeast2-a"
      instances = [
        google_compute_instance.internal_inbound_nva_instances["a"].id,
      ]
    },
    b = {
      name = "${local.prefix}-route-from-internal-lb-instance-group-b"
      zone = "asia-southeast2-b"
      instances = [
        google_compute_instance.internal_inbound_nva_instances["b"].id,
      ]
    }
  }
}

# Create the Internal Passthrough Network Load Balancer
resource "google_compute_instance_group" "internal_inbound_unmig" {
  provider = google.hub_project
  for_each = local.route_from_internal_lb_backends

  name        = each.value.name
  description = "'Route from Internal' Load Balancer Instance Group for Zone ${each.value.zone}"

  instances = each.value.instances

  zone = each.value.zone
}

resource "google_compute_region_health_check" "route_from_internal" {
  provider = google.hub_project

  name               = "${google_compute_network.internal_untrust_network.name}-route-from-internal-hc"
  region             = "asia-southeast2"
  timeout_sec        = 1
  check_interval_sec = 1

  tcp_health_check {
    port = "80"
  }
}

resource "google_compute_region_backend_service" "route_from_internal" {
  provider = google.hub_project

  name                  = "${google_compute_network.internal_untrust_network.name}-route-from-internal-bs"
  region                = "asia-southeast2"
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  health_checks         = [google_compute_region_health_check.route_from_internal.id]

  dynamic "backend" {
    for_each = google_compute_instance_group.internal_inbound_unmig
    content {
      group          = backend.value.id
      balancing_mode = "CONNECTION"
    }
  }
}

resource "google_compute_forwarding_rule" "route_from_internal" {
  provider = google.hub_project

  name                  = "${google_compute_network.internal_untrust_network.name}-route-from-internal-frule"
  backend_service       = google_compute_region_backend_service.route_from_internal.id
  region                = "asia-southeast2"
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL"
  all_ports             = true
  allow_global_access   = true
  network               = google_compute_network.internal_untrust_network.id
  subnetwork            = google_compute_subnetwork.internal_untrust_subnetwork.id
}