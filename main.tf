# input vars

variable "number_workers" {
  type    = string
  default = "3"
}

variable "control_plane_flavor" {
  type    = string
  default = "m1.medium"
}

variable "worker_flavor" {
  type    = string
  default = "m1.medium"
}

variable "public_network" {
  type    = string
  default = "ext-net"
}

variable "rke2_version" {
  type    = string
  default = "v1.31.1+rke2r1"
}

variable "install_rke2" {
  type        = bool
  default     = true
  description = "Whether to install RKE2 on the nodes. Set to false to only provision base infrastructure."
}

resource "random_string" "rke2_token" {
  length  = 12
  special = false
}

# gather some data

data "openstack_networking_network_v2" "public_network" {
  name = var.public_network
}

data "openstack_images_image_v2" "image" {
  most_recent = true

  visibility = "public"
  properties = {
    os_distro  = "ubuntu"
    os_version = "24.04"
  }
}

resource "openstack_networking_floatingip_v2" "k8s_floating_ip" {
  pool = var.public_network
}

resource "openstack_compute_instance_v2" "control_plane" {
  name            = "control_plane"
  image_id        = data.openstack_images_image_v2.image.id
  flavor_name     = var.control_plane_flavor
  security_groups = [openstack_networking_secgroup_v2.k8s_secgroup.name]
  key_pair        = "ds"

  user_data = var.install_rke2 ? templatefile("server.cfg", {
    server_host_external = openstack_networking_floatingip_v2.k8s_floating_ip.address,
    token                = random_string.rke2_token.result,
    rke2_version         = var.rke2_version
  }) : null

  network {
    uuid = openstack_networking_network_v2.k8s_network.id
  }
}

resource "openstack_compute_instance_v2" "worker" {
  count           = var.number_workers
  name            = "worker${count.index}"
  image_id        = data.openstack_images_image_v2.image.id
  flavor_name     = var.worker_flavor
  security_groups = [openstack_networking_secgroup_v2.k8s_secgroup.name]
  key_pair        = "ds"

  user_data = var.install_rke2 ? templatefile("agent.cfg", {
    server_host  = openstack_compute_instance_v2.control_plane.access_ip_v4
    token        = random_string.rke2_token.result,
    rke2_version = var.rke2_version
  }) : null

  network {
    uuid = openstack_networking_network_v2.k8s_network.id
  }
}

data "openstack_networking_port_v2" "control_plane_port" {
  fixed_ip = openstack_compute_instance_v2.control_plane.access_ip_v4
}

resource "openstack_networking_floatingip_associate_v2" "control_plane_associate_ip" {
  floating_ip = openstack_networking_floatingip_v2.k8s_floating_ip.address
  port_id     = data.openstack_networking_port_v2.control_plane_port.id
}

output "instance_ip" {
  value = openstack_networking_floatingip_v2.k8s_floating_ip.address
}

output "rke2_token" {
  value = random_string.rke2_token.result
}

