resource "google_compute_firewall" "fw_allow_http_health_checks_app" {
  provider = google.app_project
  for_each = local.vpc_full_allow_http_health_checks_app

  name        = "${each.value.name}-fw-allow-http-health-checks"
  network     = each.value.id
  description = "Creates firewall rule targeting tagged instances to allow HTTP health check traffic.  "

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }
  target_tags   = [local.network_tags.health_check]
  source_ranges = ["35.191.0.0/16"]
}

resource "google_compute_firewall" "fw_allow_iap_ssh_app" {
  provider = google.app_project
  for_each = local.vpc_full_allow_iap_ssh_app

  name        = "${each.value.name}-fw-allow-iap-ssh"
  network     = each.value.id
  description = "Creates firewall rule targeting tagged instances to allow IAP SSH traffic.  "

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags   = [local.network_tags.iap_ssh]
  source_ranges = ["35.235.240.0/20"]
}

resource "google_compute_firewall" "fw_allow_icmp_app" {
  provider = google.app_project
  for_each = local.vpc_full_allow_icmp_app

  name        = "${each.value.name}-fw-allow-icmp"
  network     = each.value.id
  description = "Creates firewall rule targeting tagged instances to allow ICMP traffic.  "

  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "fw_allow_http_from_lb_app" {
  provider = google.app_project
  for_each = local.vpc_full_allow_http_from_lb_app

  name        = "${each.value.name}-fw-allow-http-from-lb"
  network     = each.value.id
  description = "Creates firewall rule targeting tagged instances to allow HTTP traffic from Load Balancer.  "

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  target_tags   = [local.network_tags.load_balancer]
  source_ranges = [google_compute_subnetwork.app_proxy_subnetwork.ip_cidr_range]
}


resource "google_compute_firewall" "fw_allow_internal_to_app" {
  provider = google.app_project

  name        = "${google_compute_network.app_network.name}-fw-allow-internal-to-app"
  network     = google_compute_network.app_network.id
  description = "Creates firewall rule targeting the tagged App Server instances to allow traffic from Internal IP Ranges.  "

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "icmp"
  }

  target_tags   = [local.network_tags.app_server]
  source_ranges = ["0.0.0.0/0"]

  lifecycle {
    ignore_changes = [source_ranges]
  }
}