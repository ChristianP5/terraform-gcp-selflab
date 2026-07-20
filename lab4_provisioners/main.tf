locals {
    prefix = "c-lab59"
    region = "asia-southeast2"
}

data "google_compute_image" "centos_image" {
  family  = "centos-stream-10"
  project = "centos-cloud"
}

resource "google_service_account" "main_instance_service_account" {
  account_id   = "${local.prefix}-instance-sa"
  display_name = "Custom SA for VM Instance"
}

module "network" {
  source  = "terraform-google-modules/network/google"
  version = "18.1.2"

  # insert the 3 required variables here
  network_name = "${local.prefix}-vpc"
  project_id   = "c-gcp-project"
  subnets = [
    {
      subnet_name   = "${local.prefix}-subnet"
      subnet_ip     = "10.0.0.0/24"
      subnet_region = "asia-southeast2"
      
    }
  ]
  routing_mode = "REGIONAL"
  ingress_rules = [
    {
      name        = "allow-ssh"
      description = "Allow SSH from anywhere"
      source_ranges = ["0.0.0.0/0"]
      allow = [{
        protocol = "tcp"
        ports    = ["22"]
      }]
    },
    {
      name        = "allow-cockpit"
      description = "Allow Cockpit from anywhere"
      source_ranges = ["0.0.0.0/0"]
      allow = [{
        protocol = "tcp"
        ports    = ["9090"]
      }]
    }
  ]
}

# Create a Cloud NAT Gateway
resource "google_compute_router" "router" {
  name    = "${local.prefix}-router"
  region  = module.network.subnets["${local.region}/${local.prefix}-subnet"].region
  network = module.network.network_id

  bgp {
    asn = 64514
  }
}


resource "google_compute_router_nat" "nat" {
  name                               = "${local.prefix}-natgw"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_instance" "main_instance" {
  name         = "${local.prefix}-instance"
  machine_type = "e2-micro"
  zone         = "asia-southeast2-a"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.centos_image.self_link
    }
  }

  network_interface {
    subnetwork = module.network.subnets["${local.region}/${local.prefix}-subnet"].id

    access_config {
      // Ephemeral public IP
    }
  }

  metadata_startup_script = "sudo su && sed -i -e 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config && systemctl restart sshd && sudo useradd -m -s /bin/bash ${var.user_name} && sudo passwd ${var.user_name} <<< \"${var.user_password}\n${var.user_password}\" && sudo usermod -aG google-sudoers ${var.user_name}"

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.main_instance_service_account.email
    scopes = ["cloud-platform"]
  }

  connection {
    type        = "ssh"
    host        = self.network_interface.0.access_config.0.nat_ip
    user        = var.user_name
    password    = var.user_password
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y cockpit",
      "sudo systemctl start cockpit.socket",
      "sudo systemctl enable --now cockpit.socket"
    ]
  }
}