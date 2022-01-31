locals {
  use_nsx_t  = var.vcd_network_stack == "NSX-T"
  use_nsx_v  = var.vcd_network_stack == "NSX-v"
  edge       = local.use_nsx_t ? data.vcd_nsxt_edgegateway.edge-gw[0] : data.vcd_edgegateway.edge-gw[0]
  extenal_ip = local.use_nsx_t ? tolist(local.edge.subnet)[0].primary_ip : local.edge.external_network_ips[0]

}

data "vcd_nsxt_edgegateway" "edge-gw" {
  count = local.use_nsx_t ? 1 : 0
  name  = var.vcd_edge_name
  org   = var.vcd_org
  vdc   = var.vcd_vdc
}

data "vcd_edgegateway" "edge-gw" {
  count = local.use_nsx_v ? 1 : 0
  name  = var.vcd_edge_name
  org   = var.vcd_org
  vdc   = var.vcd_vdc
}

output "edge" {
  value = local.extenal_ip
}

resource "vcd_vapp_org_network" "gitlab-runners" {
  vapp_name        = vcd_vapp.gitlab-runners.name
  org_network_name = vcd_network_routed_v2.gitlab-runners.name
}

resource "vcd_network_routed_v2" "gitlab-runners" {
  org        = var.vcd_org
  vdc        = var.vcd_vdc
  name       = "gitlab-runners"
  depends_on = [vcd_vapp.gitlab-runners]

  edge_gateway_id = local.edge.id
  dns1            = "8.8.8.8"
  dns2            = "8.8.4.4"
  dns_suffix      = ""
  gateway         = "192.168.100.254"
  prefix_length   = 24
  static_ip_pool {
    start_address = "192.168.100.1"
    end_address   = "192.168.100.100"
  }
}

resource "vcd_nsxt_firewall" "gitlab-runners-allow-all" {
  count = local.use_nsx_t ? 1 : 0
  org   = var.vcd_org
  vdc   = var.vcd_vdc

  edge_gateway_id = local.edge.id

  rule {
    action      = "ALLOW"
    name        = "allow all IPv4 traffic"
    direction   = "IN_OUT"
    ip_protocol = "IPV4"
  }
}

resource "vcd_nsxt_nat_rule" "gitlab-runners-snat-all" {
  count = local.use_nsx_t ? 1 : 0

  org = var.vcd_org
  vdc = var.vcd_vdc

  edge_gateway_id = local.edge.id

  name             = "SNAT all traffic info gitlab-runners vapp"
  rule_type        = "SNAT"
  description      = "SNAT rule for all internal trafic"
  external_address = tolist(local.edge.subnet)[0].primary_ip
  internal_address = "192.168.100.0/24"
}

resource "vcd_nsxv_snat" "gitlab-runners-snat-all" {
  count = local.use_nsx_v ? 1 : 0
  org   = var.vcd_org
  vdc   = var.vcd_vdc

  edge_gateway = local.edge.name
  network_type = "org"
  network_name = vcd_network_routed_v2.gitlab-runners.name

  original_address   = "192.168.100.0/24"
  translated_address = local.extenal_ip
}