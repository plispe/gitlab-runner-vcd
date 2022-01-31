locals {
  catalog_name = var.upload_ova_image ? vcd_catalog.flatcar-linux[0].name : var.catalog_name
  template_name = var.upload_ova_image ? vcd_catalog_item.flatcar-linux-stable[0].name : var.template_name
}
resource "vcd_vapp" "gitlab-runners" {
  name = "gitlab-runners"
}

resource "vcd_catalog" "flatcar-linux" {
  count = var.upload_ova_image ? 1 : 0
  org   = var.vcd_org

  name             = var.catalog_name
  delete_recursive = "true"
  delete_force     = "true"
}

resource "vcd_catalog_item" "flatcar-linux-stable" {
  count   = var.upload_ova_image ? 1 : 0
  org     = var.vcd_org
  catalog = vcd_catalog.flatcar-linux[0].name

  name                 = var.template_name
  description          = "Stable channel template for flatcar linux"
  ova_path             = "${path.module}/images/flatcar_production_vmware_ova.ova"
  upload_piece_size    = 10
  show_upload_progress = true
}

resource "vcd_vapp_vm" "gitlab-runner" {
  for_each               = var.gitlab-runners
  vapp_name              = vcd_vapp.gitlab-runners.name
  name                   = each.value["hostname"]
  catalog_name           = local.catalog_name
  template_name          = local.template_name
  memory                 = each.value["memory"]
  cpus                   = each.value["cpus"]
  cpu_cores              = each.value["cpu_cores"]
  memory_hot_add_enabled = false
  cpu_hot_add_enabled    = false

  guest_properties = {
    "guestinfo.ignition.config.data"          = base64encode(data.ct_config.ignition-config[each.key].rendered)
    "guestinfo.ignition.config.data.encoding" = "base64"
  }

  network {
    type               = "org"
    name               = vcd_vapp_org_network.gitlab-runners.org_network_name
    ip_allocation_mode = each.value["network"].ip_allocation_mode
    ip                 = each.value["network"].ip
    is_primary         = true
    connected          = true
  }

  override_template_disk {
    bus_type    = "paravirtual"
    size_in_mb  = each.value["disk_size_in_mb"]
    bus_number  = 0
    unit_number = 0
    iops        = 0
  }
}

data "ct_config" "ignition-config" {
  for_each = var.gitlab-runners
  content = templatefile("${path.module}/templates/cloud-config.yaml.tpl", {
    machine     = each.value
    org_network = vcd_network_routed_v2.gitlab-runners
  })
  strict       = true
  pretty_print = true
}

// output "ignition" {
//   value = data.ct_config.ignition-config["master-1"].rendered
// }