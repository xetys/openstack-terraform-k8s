
# Network
resource "openstack_networking_network_v2" "k8s_network" {
  name = "k8s_network"
}

resource "openstack_networking_subnet_v2" "k8s_subnet" {
  name            = "k8s_subnet"
  network_id     = openstack_networking_network_v2.k8s_network.id
  cidr            = "192.168.1.0/24"
  ip_version      = 4
  allocation_pool {
    start = "192.168.1.10"
    end   = "192.168.1.100"
  }
  dns_nameservers = ["8.8.8.8"]
}

resource "openstack_networking_router_v2" "k8s_router" {
  name                = "k8s_router"
  external_network_id = data.openstack_networking_network_v2.public_network.id
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.k8s_router.id
  subnet_id = openstack_networking_subnet_v2.k8s_subnet.id
}

resource "openstack_networking_secgroup_v2" "k8s_secgroup" {
  name = "k8s_secgroup"
}

resource "openstack_networking_secgroup_rule_v2" "icmp" {
  security_group_id = openstack_networking_secgroup_v2.k8s_secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  security_group_id = openstack_networking_secgroup_v2.k8s_secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
}

resource "openstack_networking_secgroup_rule_v2" "k8s_api" {
  security_group_id = openstack_networking_secgroup_v2.k8s_secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
}

resource "openstack_networking_secgroup_rule_v2" "http" {
  security_group_id = openstack_networking_secgroup_v2.k8s_secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
}

resource "openstack_networking_secgroup_rule_v2" "https" {
  security_group_id = openstack_networking_secgroup_v2.k8s_secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
}

resource "openstack_networking_secgroup_rule_v2" "rke2" {
  security_group_id = openstack_networking_secgroup_v2.k8s_secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 9345
  port_range_max    = 9345
  remote_ip_prefix  = "192.168.1.0/24"
}