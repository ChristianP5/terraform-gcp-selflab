module "webserver_network" {
  source           = "./modules/network"
  vpc_network_name = "${var.prefix}-webserver-vpc"
  subnetwork_name  = "${var.prefix}-webserver-subnet"
  subnetwork_cidr  = "10.0.255.0/24"
}

module "apache_webserver_instance" {
  source          = "./modules/apache_webserver_instance"
  message         = "Welcome to the Apache web server running on Google Cloud Platform!"
  subnetwork_name = module.webserver_network.subnetwork_name
  network_name    = module.webserver_network.network_name
  prefix          = var.prefix
}