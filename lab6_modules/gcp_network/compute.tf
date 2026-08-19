# Create the Service Accounts for the NVA Instances
resource "google_service_account" "nva_instance_sa" {
  provider = google.hub_project

  account_id   = "${local.prefix}-nva-instance-sa"
  display_name = "Custom SA for NVA VM Instance for Lab 6 (Terraform)"
}

# Create the NVA VMs
data "google_compute_image" "centos_image" {
  family  = "centos-stream-10"
  project = "centos-cloud"
}

resource "google_compute_instance" "internet_inbound_nva_instances" {
  provider = google.hub_project
  for_each = local.nva_internet_inbound_instances

  name         = each.value.name
  machine_type = "e2-micro"
  zone         = each.value.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.centos_image.self_link
    }
  }

  network_interface {
    subnetwork = each.value.primary_subnetwork
  }

  network_interface {
    subnetwork = each.value.secondary_subnetwork
  }

  metadata_startup_script = "sudo su && sysctl -w net.ipv4.ip_forward=1 && echo -e '1\trt_to_internal' >> /etc/iproute2/rt_tables && ip route add default via 10.229.125.1 dev ens5 table rt_to_internal && ip route add 10.229.125.1 src $(sudo ip -o -4 addr show dev ens5 | awk '$4 ~ /\\/32/ {print $4}' | sed 's#/32##') dev ens5 table rt_to_internal && ip rule add fto 10.229.125.0/24 table rt_to_internal && ip rule add to 10.229.1.0/24 table rt_to_internal"
  tags                    = [local.network_tags.load_balancer, local.network_tags.health_check, local.network_tags.iap_ssh]

  service_account {
    email  = google_service_account.nva_instance_sa.email
    scopes = ["cloud-platform"]
  }

  allow_stopping_for_update = true
  can_ip_forward            = true
}

resource "google_compute_instance" "internet_outbound_nva_instances" {
  provider = google.hub_project
  for_each = local.nva_internet_outbound_instances

  name         = each.value.name
  machine_type = "e2-micro"
  zone         = each.value.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.centos_image.self_link
    }
  }

  network_interface {
    subnetwork = each.value.primary_subnetwork
  }

  network_interface {
    subnetwork = each.value.secondary_subnetwork
  }

  metadata_startup_script = "sudo su && sysctl -w net.ipv4.ip_forward=1 && echo -e '1\trt_to_external' >> /etc/iproute2/rt_tables && ip route add default via 10.229.123.1 dev ens5 table rt_to_external && ip route add 10.229.123.1 src $(sudo ip -o -4 addr show dev ens5 | awk '$4 ~ /\\/32/ {print $4}' | sed 's#/32##') dev ens5 table rt_to_external && ip rule add to 10.229.0.0/16 lookup main priority 100 && ip rule add to 35.235.240.0/20 lookup main priority 100 && ip rule add lookup rt_to_external priority 200"
  tags                    = [local.network_tags.iap_ssh, local.network_tags.tcp80_health_check, local.network_tags.allow_all]

  service_account {
    email  = google_service_account.nva_instance_sa.email
    scopes = ["cloud-platform"]
  }

  allow_stopping_for_update = true
  can_ip_forward            = true
}

resource "google_compute_instance" "internal_inbound_nva_instances" {
  provider = google.hub_project
  for_each = local.nva_internal_inbound_instances

  name         = each.value.name
  machine_type = "e2-micro"
  zone         = each.value.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.centos_image.self_link
    }
  }

  network_interface {
    subnetwork = each.value.primary_subnetwork
  }

  network_interface {
    subnetwork = each.value.secondary_subnetwork
  }

  metadata_startup_script = "sudo su && sysctl -w net.ipv4.ip_forward=1 && echo -e '1\trt_to_internal' >> /etc/iproute2/rt_tables && ip route add default via 10.229.125.1 dev ens5 table rt_to_internal && ip route add 10.229.125.1 src $(sudo ip -o -4 addr show dev ens5 | awk '$4 ~ /\\/32/ {print $4}' | sed 's#/32##') dev ens5 table rt_to_internal && ip rule add from 192.168.0.0/16 to 10.229.125.0/24 table rt_to_internal && ip rule add from 192.168.0.0/16 to 10.229.1.0/24 table rt_to_internal"
  tags                    = [local.network_tags.iap_ssh, local.network_tags.tcp80_health_check, local.network_tags.internal_inbound_nva]

  service_account {
    email  = google_service_account.nva_instance_sa.email
    scopes = ["cloud-platform"]
  }

  allow_stopping_for_update = true
  can_ip_forward            = true
}