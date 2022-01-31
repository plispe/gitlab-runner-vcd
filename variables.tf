variable "vcd_url" {
  type = string
}

variable "vcd_org" {
  type = string
}

variable "vcd_vdc" {
  type = string
}

variable "vcd_user" {
  type = string
}

variable "vcd_password" {
  type = string
}

variable "vcd_network_stack" {
  type    = string
  default = "NSX-v"
}

variable "vcd_edge_name" {
  type = string
}

variable "upload_ova_image" {
  type    = bool
  default = false
}

variable "catalog_name" {
  type    = string
  default = "flatcar-linux"
}

variable "template_name" {
  type    = string
  default = "flatcar_production_vmware_ova"
}

variable "gitlab-runners" {
  type = map(object({
    hostname            = string
    memory              = number
    cpus                = number
    cpu_cores           = number
    disk_size_in_mb     = string
    ssh_authorized_keys = list(string)
    network = object({
      ip                 = string
      ip_allocation_mode = string
    })
    runner = object({
      registration_token = string
      gitlab_url         = string
      image              = string
    })
  }))

  default = {
    "geetoo-runner" = {
      hostname        = "geetoo-runner"
      memory          = 2048
      cpus            = 2
      cpu_cores       = 2
      disk_size_in_mb = "102400"
      ssh_authorized_keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDmiOncJ6e7/w+5ASoyHDJIbUbtyMzYDg9rqanOqyByuMP7Yo8SytujhUo4og56LUzHufzoJTXzMDorxd5qPyw5BaqiHvrIpT8/5iN1bkXFPCwUMzLIqsaksg5N5wyxSTviObWEjctItRelGdaxW2hQzHOX9pTgFop48Rdi+VvZi7uzFhWF9yRKYdswmTvyYEVLsZmJfNyL5YDeMPtkro4xh2YrqagI7clhWXZ4hNpGQK+/NZV4BpptzckXJeE/ulotVdEDk2dfy0bFhBePitj5c/++YAuP1bvoKhNygGm3GcqnQ+6tv/4pZDb2SzTehlU2KQs9PCLpdNOM/E+Mrjwn8v1Aj2X1SYr1I5dzXofIsoDA5/5zgLKAcDIt4MxGmavW9Ig+E6V7kmUVbYgCxojw/h7ynOltrRIAjUF0wAkQf2cNRbm59XHAD4XUHCRvlgdaM8/T6xIqz125jxe6N4paU1xon8WMqwdv3tZGB4o5HnnrZnyAzNC3O6RMEghRNMk= petrpliska1@Petr-MacBook-Pro.local"
      ]
      network = {
        ip                 = "192.168.100.1"
        ip_allocation_mode = "MANUAL"
      }
      runner = {
        gitlab_url         = "https://git.cognito.cz/"
        registration_token = "dV--nLCJsXX_MbxWzDxw"
        image              = "docker:latest"
      }
    }
  }
}