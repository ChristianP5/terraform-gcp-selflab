resource "google_compute_address" "lb_ip_address" {
  name         = "${local.prefix}-lb-ip-address"
  address_type = "EXTERNAL"
  network_tier = "STANDARD"
  region       = "asia-southeast2"
}


resource "google_compute_region_health_check" "lb_hc" {
  name               = "${local.prefix}-lb-health-check-http80"
  check_interval_sec = 5
  healthy_threshold  = 2
  http_health_check {
    port_specification = "USE_SERVING_PORT"
    proxy_header       = "NONE"
    request_path       = "/"
  }
  region              = "asia-southeast2"
  timeout_sec         = 5
  unhealthy_threshold = 2
}

resource "google_compute_instance_group" "lb_unmanaged_instance_group" {
  for_each    = local.instances
  name        = "${local.prefix}-lb-unmanaged-instance-group"
  description = "Unamanged instance group for lab5 load balancer for Zone ${each.value}"

  instances = [
    "${google_compute_instance.primary_instance[each.key].id}"
  ]

  named_port {
    name = "http"
    port = "80"
  }

  zone = each.value

  lifecycle {
    # create_before_destroy = true
    postcondition {
        condition     = length(google_compute_instance.primary_instance) > 0
        error_message = "No instances found for the unmanaged instance group."
    }
  }
}

resource "google_compute_region_backend_service" "lb_backend_service" {
  name                  = "${local.prefix}-lb-backend-service"
  region                = "asia-southeast2"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_region_health_check.lb_hc.id]
  protocol              = "HTTP"
  session_affinity      = "NONE"
  timeout_sec           = 30

  dynamic "backend" {
    for_each = google_compute_instance_group.lb_unmanaged_instance_group
    content {
      group          = backend.value.id
      balancing_mode = "UTILIZATION"
      capacity_scaler = 1.0
    }
  }
}

resource "google_compute_region_url_map" "lb_urlmap" {
  name            = "${local.prefix}-lb-map"
  region          = "asia-southeast2"
  default_service = google_compute_region_backend_service.lb_backend_service.id
}

resource "google_compute_region_target_http_proxy" "lb_proxy" {
  name    = "${local.prefix}-lb-proxy"
  region  = "asia-southeast2"
  url_map = google_compute_region_url_map.lb_urlmap.id
}

resource "google_compute_forwarding_rule" "lb_forwarding_rule" {
  name       = "${local.prefix}-lb-forwarding-rule"
  depends_on = [google_compute_subnetwork.proxy_subnetwork]
  region     = "asia-southeast2"

  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_region_target_http_proxy.lb_proxy.id
  network               = google_compute_network.main_network.id
  ip_address            = google_compute_address.lb_ip_address.address
  network_tier          = "STANDARD"
}