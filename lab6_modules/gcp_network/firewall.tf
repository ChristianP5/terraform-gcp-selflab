# FIREWALLS
resource "google_compute_firewall" "fw_allow_http_from_proxy_vpc_internet_untrust" {
  provider = google.hub_project

  name        = "${google_compute_network.internet_untrust_network.name}-fw-allow-http-from-proxy"
  network     = google_compute_network.internet_untrust_network.id
  description = "Creates firewall rule targeting tagged instances to allow HTTP traffic from Regional Managed Proxy Subnetwork.  "

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  target_tags   = [local.network_tags.load_balancer]
  source_ranges = [google_compute_subnetwork.internet_untrust_proxy_subnetwork.ip_cidr_range]
}


resource "google_compute_firewall" "fw_allow_http_health_checks" {
  provider = google.hub_project
  for_each = local.vpc_full_allow_http_health_checks

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

resource "google_compute_firewall" "fw_allow_tcp80_health_checks" {
  provider = google.hub_project
  for_each = local.vpc_full_allow_tcp80_health_checks

  name        = "${each.value.name}-fw-allow-tcp80-health-checks"
  network     = each.value.id
  description = "Creates firewall rule targeting tagged instances to allow TCP 80 health check traffic.  "

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }
  target_tags   = [local.network_tags.tcp80_health_check]
  source_ranges = ["35.191.0.0/16"]
}

resource "google_compute_firewall" "fw_allow_all" {
  provider = google.hub_project
  for_each = local.vpc_full_allow_all

  name        = "${each.value.name}-fw-allow-all"
  network     = each.value.id
  description = "Creates firewall rule targeting tagged instances to allow all traffic.  "

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  target_tags   = [local.network_tags.allow_all]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "fw_allow_iap_ssh" {
  provider = google.hub_project
  for_each = local.vpc_full_allow_iap_ssh

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

resource "google_compute_firewall" "fw_allow_icmp" {
  provider = google.hub_project
  for_each = local.vpc_full_allow_icmp

  name        = "${each.value.name}-fw-allow-icmp"
  network     = each.value.id
  description = "Creates firewall rule targeting tagged instances to allow ICMP traffic.  "

  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "fw_allow_http_from_lb" {
  provider = google.hub_project
  for_each = local.vpc_full_allow_http_from_lb

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

resource "google_compute_firewall" "fw_allow_internal_to_nva" {
  provider = google.hub_project

  name        = "${google_compute_network.internal_untrust_network.name}-fw-allow-internal-to-nva"
  network     = google_compute_network.internal_untrust_network.id
  description = "Creates firewall rule targeting the tagged Internal Inbound NVA Server instances to allow traffic from Internal IP Ranges.  "

  target_tags   = [local.network_tags.internal_inbound_nva]
  source_ranges = ["0.0.0.0/0"]

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
    ignore_changes = [source_ranges]
  }
}