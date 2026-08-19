# locals {
#     default_route_to_internet_lb_backends = {
#         a = {
#             name                 = "${local.prefix}-default-route-to-internet-lb-instance-group-a"
#             zone                 = "asia-southeast2-a"
#             instances = [
#                 google_compute_instance.application_instances["a"].id,
#             ]
#         },
#         b = {
#             name                 = "${local.prefix}-default-route-to-internet-lb-instance-group-b"
#             zone                 = "asia-southeast2-b"
#             instances = [
#                 google_compute_instance.application_instances["b"].id,
#             ]
#         }
#     }
# }

# # For Default Route to Internet
# resource "google_compute_instance_group" "default_route_to_internet" {
#   for_each = local.default_route_to_internet_lb_backends

#   name        = each.value.name
#   description = "Default Route to Internet Load Balancer Instance Group for Zone ${each.value.zone}"

#   instances = each.value.instances

#   zone = each.value.zone
# }

# resource "google_compute_region_health_check" "default_route_to_internet" {
#   name   = "${google_compute_network.internet_trust_network.name}-default-route-to-internet-hc"
#   region = "asia-southeast2"
#   timeout_sec        = 1
#   check_interval_sec = 1

#   tcp_health_check {
#     port = "80"
#   }
# }

# resource "google_compute_region_backend_service" "default_route_to_internet" {
#   name                  = "${google_compute_network.internet_trust_network.name}-default-route-to-internet-backend-service"
#   region                = "asia-southeast2"
#   protocol              = "TCP"
#   load_balancing_scheme = "INTERNAL"
#   health_checks         = [google_compute_region_health_check.default_route_to_internet.id]

#   dynamic "backend" {
#     for_each = google_compute_instance_group.default_route_to_internet
#     content {
#       group          = backend.value.id
#       balancing_mode = "UTILIZATION"
#       capacity_scaler = 1.0
#     }
#   }
# }

# resource "google_compute_forwarding_rule" "default_route_to_internet" {
#   name                  = "${google_compute_network.internet_trust_network.name}-default-route-to-internet-forwarding-rule"
#   backend_service       = google_compute_region_backend_service.default_route_to_internet.id
#   region                = "asia-southeast2"
#   ip_protocol           = "TCP"
#   load_balancing_scheme = "INTERNAL"
#   all_ports             = true
#   allow_global_access   = true
#   network               = google_compute_network.ilb_network.id
#   subnetwork            = google_compute_subnetwork.ilb_subnet.id
# }

# resource "google_compute_route" "default_route_to_internet_route" {
#   name        = "${google_compute_network.internet_trust_network.name}-default-route-to-internet"
#   dest_range  = "0.0.0.0/0"
#   network     = google_compute_network.internet_trust_network.name
#   next_hop_ip = "10.132.1.5"
#   priority    = 100
# }