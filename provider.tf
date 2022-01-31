terraform {
  required_providers {
    vcd = {
      source  = "vmware/vcd"
      version = "3.5.0"
    }
    ct = {
      source  = "poseidon/ct"
      version = "0.9.1"
    }
  }
}

provider "vcd" {
  url                  = var.vcd_url
  org                  = var.vcd_org
  vdc                  = var.vcd_vdc
  user                 = var.vcd_user
  password             = var.vcd_password
  auth_type            = "integrated"
  allow_unverified_ssl = true
  max_retry_timeout    = 60
}
