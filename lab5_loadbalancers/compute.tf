resource "google_service_account" "primary_instance_sa" {
  account_id   = "${local.prefix}-instance-sa"
  display_name = "Custom SA for VM Instance for Lab 5 (Terraform)"
}

locals {
  instances = {
    a = "asia-southeast2-a"
    b = "asia-southeast2-b"
    c = "asia-southeast2-c"
  }

  network_tags = {
    load_balancer = "allow-http-from-lb"
    health_check  = "allow-health-checks"
    iap_ssh       = "allow-iap-ssh"
  }
}

data "google_compute_image" "centos_image" {
  family  = "centos-stream-10"
  project = "centos-cloud"
}

resource "google_compute_instance" "primary_instance" {
  for_each     = local.instances
  name         = "${local.prefix}-lb-instance-${each.key}"
  machine_type = "e2-micro"
  zone         = each.value

  boot_disk {
    initialize_params {
      image = data.google_compute_image.centos_image.self_link
    }
  }

  network_interface {
    network = google_compute_network.main_network.id
    subnetwork = google_compute_subnetwork.main_subnetwork.name
  }

  metadata_startup_script = "sudo su && dnf install -y httpd && systemctl enable httpd && systemctl start httpd && echo '<h1>Welcome to Lab 5 Load Balancer - ${each.key}</h1>' > /var/www/html/index.html"
  depends_on              = [google_compute_router_nat.main_nat]
  tags                    = [local.network_tags.load_balancer, local.network_tags.health_check, local.network_tags.iap_ssh]

  lifecycle {
    # create_before_destroy = true
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.primary_instance_sa.email
    scopes = ["cloud-platform"]
  }
}


resource "google_compute_firewall" "fw_allow_http_from_proxy" {
  name        = "${google_compute_network.main_network.name}-fw-allow-http-from-proxy"
  network     = google_compute_network.main_network.id
  description = "Creates firewall rule targeting tagged instances to allow HTTP traffic from Regional Managed Proxy Subnetwork.  "

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  target_tags   = [local.network_tags.load_balancer]
  source_ranges = [google_compute_subnetwork.proxy_subnetwork.ip_cidr_range]
}


resource "google_compute_firewall" "fw_allow_health_checks" {
  name        = "${google_compute_network.main_network.name}-fw-allow-health-checks"
  network     = google_compute_network.main_network.id
  description = "Creates firewall rule targeting tagged instances to allow health check traffic.  "

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }
  target_tags   = [local.network_tags.health_check]
  source_ranges = ["35.191.0.0/16"]
}


resource "google_compute_firewall" "fw_allow_iap_ssh" {
  name        = "${google_compute_network.main_network.name}-fw-allow-iap-ssh"
  network     = google_compute_network.main_network.id
  description = "Creates firewall rule targeting tagged instances to allow IAP SSH traffic.  "

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags   = [local.network_tags.iap_ssh]
  source_ranges = ["35.235.240.0/20"]
}