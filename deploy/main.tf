module "vpc" {
  source = "../module/vpc/"

  name       = "custom"
  project_id = var.mproject_id
  auto_create_subnetworks = false

  subnets = [{

    ip_cidr_range="10.0.0.0/24"
    name="custom-subnet"
    region="us-central1"
    secondary_ip_range =null

  }]
}
module "firewall_rules_1" {
  depends_on = [module.vpc]
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  project_id   = var.mproject_id
  network_name = module.vpc.name

  rules = [{
    name                    = "allow-ssh-ingress"
    description             = null
    direction               = "INGRESS"
    priority                = null
    ranges                  = ["0.0.0.0/0"]
    source_tags             = null
    source_service_accounts = null
    target_tags             = null
    target_service_accounts = null
    allow = [{
      protocol = "tcp"
      ports    = ["22"]
    }]
    deny = []
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
  },
  {
    name                    = "allow-all-ingress"
    description             = null
    direction               = "INGRESS"
    priority                = null
    ranges                  = ["0.0.0.0/0"]
    source_tags             = null
    source_service_accounts = null
    target_tags             = null
    target_service_accounts = null
    allow = [{
      protocol = "tcp"
      ports    = ["0-65535"]
    },{
      protocol="udp"
      ports=["0-65535"]
    }]
    deny = []
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
  },
  {
    name                    = "allow-all-rdp-icmp"
    description             = null
    direction               = "INGRESS"
    priority                = null
    ranges                  = ["0.0.0.0/0"]
    source_tags             = null
    source_service_accounts = null
    target_tags             = null
    target_service_accounts = null
    allow = [{
      protocol = "tcp"
      ports    = ["3389"]
    },{
      protocol="icmp"
      ports=null
    }]
    deny = []
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
  }]
}

module "vm" {
  source = "../module/vm/"
  depends_on = [module.vpc]
  name               = "nat-vm"
  tags = ["http-server","no-public-ip"]
  metadata = {
    ssh-keys="${var.muser}:${file(var.mpublic_key)}"
  }
  network_interfaces = [{
    network=module.vpc.self_link
    subnetwork=module.vpc.subnet_self_links["us-central1/custom-subnet"]
    nat=false
    addresses=null
  }]
  project_id         = var.mproject_id
  zone               = var.mzone
}
resource "google_compute_router" "router" {
  depends_on = [module.vpc]
  project = var.mproject_id
  name    = "nat-router"
  network = module.vpc.name
  region  = "us-central1"
}
module "cloud-nat" {
  depends_on = [module.vpc,google_compute_router.router]
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 1.2"
  project_id = var.mproject_id
  region     = var.mregion
  router     = var.mrouter_name
}

resource "null_resource" "null" {
  depends_on = [module.vm,module.cloud-nat]
  connection {
    type="ssh"
    user=var.muser
    host = "nat-vm.${var.mzone}.c.${var.mproject_id}.internal"
    private_key="${file(var.mprivatekeypath)}"
    timeout = "180s"
  }
   provisioner "file" {
    source ="${var.mpath}"
    destination ="/home/${var.muser}/script.sh"
  }
  provisioner "remote-exec" {

    inline = [
    "cd /home/${var.muser}/",
      "sudo chmod +x script.sh",
      "./script.sh"
    ]
  }
}