locals {
  prefix = "lab6-tf"

  vpc-internet-untrust = {
    name = google_compute_network.internet_untrust_network.name,
    id   = google_compute_network.internet_untrust_network.id,
  }
  vpc-internet-trust = {
    name = google_compute_network.internet_trust_network.name,
    id   = google_compute_network.internet_trust_network.id,
  }
  vpc-internal-untrust = {
    name = google_compute_network.internal_untrust_network.name,
    id   = google_compute_network.internal_untrust_network.id,
  }
  vpc_full_allow_iap_ssh = {
    vpc-internet-untrust = local.vpc-internet-untrust,
    vpc-internet-trust   = local.vpc-internet-trust,
    vpc-internal-untrust = local.vpc-internal-untrust
  }

  vpc_full_allow_icmp = {
    vpc-internet-untrust = local.vpc-internet-untrust,
    vpc-internet-trust   = local.vpc-internet-trust,
    vpc-internal-untrust = local.vpc-internal-untrust
  }

  vpc_full_allow_http_health_checks = {
    vpc-internet-untrust = local.vpc-internet-untrust,
  }

  vpc_full_allow_all = {
    vpc-internet-untrust = local.vpc-internet-trust,
  }

  vpc_full_allow_tcp80_health_checks = {
    vpc-internet-trust   = local.vpc-internet-trust,
    vpc-internal-untrust = local.vpc-internal-untrust
  }

  vpc_full_allow_http_from_lb = {
    vpc-internet-untrust = local.vpc-internet-untrust,
  }


  nva_internet_inbound_instances = {
    a = {
      name                 = "${local.prefix}-nva-internet-inbound-a"
      zone                 = "asia-southeast2-a"
      primary_subnetwork   = google_compute_subnetwork.internet_untrust_subnetwork.name
      secondary_subnetwork = google_compute_subnetwork.internet_trust_subnetwork.name
    }
    b = {
      name                 = "${local.prefix}-nva-internet-inbound-b"
      zone                 = "asia-southeast2-b"
      primary_subnetwork   = google_compute_subnetwork.internet_untrust_subnetwork.name
      secondary_subnetwork = google_compute_subnetwork.internet_trust_subnetwork.name
    }
  }

  nva_internet_outbound_instances = {
    a = {
      name                 = "${local.prefix}-nva-internet-outbound-a"
      zone                 = "asia-southeast2-a"
      primary_subnetwork   = google_compute_subnetwork.internet_trust_subnetwork.name
      secondary_subnetwork = google_compute_subnetwork.internet_untrust_subnetwork.name
    }
    b = {
      name                 = "${local.prefix}-nva-internet-outbound-b"
      zone                 = "asia-southeast2-b"
      primary_subnetwork   = google_compute_subnetwork.internet_trust_subnetwork.name
      secondary_subnetwork = google_compute_subnetwork.internet_untrust_subnetwork.name
    }
  }

  nva_internal_inbound_instances = {
    a = {
      name                 = "${local.prefix}-nva-internal-inbound-a"
      zone                 = "asia-southeast2-a"
      primary_subnetwork   = google_compute_subnetwork.internal_untrust_subnetwork.name
      secondary_subnetwork = google_compute_subnetwork.internet_trust_subnetwork.name
    }
    b = {
      name                 = "${local.prefix}-nva-internal-inbound-b"
      zone                 = "asia-southeast2-b"
      primary_subnetwork   = google_compute_subnetwork.internal_untrust_subnetwork.name
      secondary_subnetwork = google_compute_subnetwork.internet_trust_subnetwork.name
    }
  }

  network_tags = {
    load_balancer        = "allow-http-from-lb"
    health_check         = "allow-health-checks"
    iap_ssh              = "allow-iap-ssh"
    tcp80_health_check   = "allow-tcp80-health-checks"
    allow_all            = "allow-all"
    app_server           = "app-server"
    internal_inbound_nva = "internal-inbound-nva"
  }
}