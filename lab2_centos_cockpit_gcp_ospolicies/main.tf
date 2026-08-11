data "google_compute_image" "ubuntu_2404" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}

locals {
  prefix_name = "c-lab58"
}

# Create a VPC Network, Subnetwork, Router, and NAT for the Ubuntu VM
resource "google_compute_network" "main_vpc" {
  name                         = "${local.prefix_name}-main-vpc"
  auto_create_subnetworks      = false
  routing_mode                 = "REGIONAL"
  bgp_best_path_selection_mode = "LEGACY"
  mtu                          = 1460
}

resource "google_compute_subnetwork" "main_subnetwork" {
  name          = "${local.prefix_name}-main-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.main_vpc.id
}

resource "google_compute_router" "main_router" {
  name    = "${local.prefix_name}-cr"
  network = google_compute_network.main_vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${local.prefix_name}-nat"
  router                             = google_compute_router.main_router.name
  region                             = google_compute_router.main_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  type                               = "PUBLIC"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Configure Firewall rules to allow SSH access from IAP to the Ubuntu VM
resource "google_compute_firewall" "fw_allow_iap" {
  name      = "${local.prefix_name}-fw-allow-iap"
  network   = google_compute_network.main_vpc.name
  direction = "INGRESS"
  priority  = 200

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges           = ["35.235.240.0/20"]
  target_service_accounts = [google_service_account.ubuntu_vm_sa.email]
}

# Configure Firewall rules to allow Cockpit access to the Ubuntu VM
resource "google_compute_firewall" "fw_allow_cockpit" {
  name      = "${local.prefix_name}-fw-allow-cockpit"
  network   = google_compute_network.main_vpc.name
  direction = "INGRESS"
  priority  = 300

  allow {
    protocol = "tcp"
    ports    = ["9090"]
  }

  source_ranges           = ["0.0.0.0"]
  target_service_accounts = [google_service_account.ubuntu_vm_sa.email]
}



# Create Service Account for the Ubuntu VM
resource "google_service_account" "ubuntu_vm_sa" {
  account_id   = "${local.prefix_name}-ubuntu-vm-sa"
  display_name = "Custom SA for Ubuntu VM Instance"
}

# Create the Ubuntu VM Instance
resource "google_compute_instance" "main_instance" {
  name         = "${local.prefix_name}-ubuntu-vm"
  machine_type = "e2-medium"
  zone         = "asia-southeast2-a"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu_2404.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main_subnetwork.name

    access_config {
      // Ephemeral public IP
    }
  }

  metadata_startup_script = "sudo useradd -m -s /bin/bash ${var.admin_user} && sudo passwd ${var.admin_user} <<< \"${var.admin_password}\n${var.admin_password}\" && sudo usermod -aG wheel ${var.admin_user}"

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.ubuntu_vm_sa.email
    scopes = ["cloud-platform"]
  }

  labels = {
    "role" = "cockpit-vm"
  }
}


# OS Policy for Ubuntu VM
data "local_file" "os_policy_file" {
  filename = "${path.module}/files/os_policy.yaml"
}

# Storage Bucket to store the OS Policy file
resource "google_storage_bucket" "os_policy_bucket" {
  name          = "${local.prefix_name}-os-policy-bucket"
  location      = "ASIA-SOUTHEAST2"
  force_destroy = true

  uniform_bucket_level_access = true
}

# Upload the OS Policy file to the Storage Bucket
resource "google_storage_bucket_object" "os_policy_object" {
  name   = "os_policy.yaml"
  source = data.local_file.os_policy_file.filename
  bucket = google_storage_bucket.os_policy_bucket.name
}