locals {
  vpc-application = {
    name = google_compute_network.app_network.name,
    id   = google_compute_network.app_network.id,
  }

  vpc_full_allow_http_health_checks_app = {
    vpc-application = local.vpc-application
  }

  vpc_full_allow_iap_ssh_app = {
    vpc-application = local.vpc-application
  }

  vpc_full_allow_icmp_app = {
    vpc-application = local.vpc-application
  }

  vpc_full_allow_http_from_lb_app = {
    vpc-application = local.vpc-application
  }

}