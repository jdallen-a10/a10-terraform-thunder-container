##
##  Thunder Container Terraform file
##
##  John D. Allen
##  Sr. Solutions Engineer
##  A10 Networks, Inc.
##  September, 2020
##
##  Licensed under Apache-2.0 for private use.
##  All other Rights Reserved.
##
##  Version:
##  - 0.1.0:  Initial version using Thunder Container v5.2.0

resource "docker_image" "thunder" {
  name         = "acos_docker_5_2_0-p1_31:latest"
  keep_locally = true
}
#resource "docker_image" "thunder" {
#  name         = "acos_docker_5_2_0_154:latest"
#  keep_locally = true
#}
# resource "docker_image" "thunder" {
#   name         = "acos_docker_5_1_0-p4_23:latest"
#   keep_locally = true
# }

resource "docker_container" "thunder" {
  depends_on = [
    docker_network.slb-outside-net,
    docker_network.slb-inside-net
  ]
  image = docker_image.thunder.latest
  name  = "thunder-5-2"
  ports {
    # SSH Port
    internal = 22
    external = 222
  }
  networks_advanced {
    name = "bridge"
  }
  networks_advanced {
    name = "slb-inside-net"
  }
  networks_advanced {
    name = "slb-outside-net"
  }
  restart = "always"
  #
  # Container Resources
  memory  = 4096
  cpu_set = "0-3"
  sysctls = map(
    "net.ipv6.conf.all.disable_ipv6", 0
  )
  privileged = true
  capabilities {
    add = [
      "NET_ADMIN",
      "SYS_ADMIN",
      "IPC_LOCK"
    ]
  }
  #
  # cThunder Startup Environment Variables
  env = [
    "ACOS_CTH_SUPPORT_MGMT=y",
    "ACOS_CTH_PRODUCT=ADC",
    "ACOS_CTH_CONFIG_PATH=/tmp/demo.cfg",
    "ACOS_CTH_VETH_DRIVER_LST=veth,macvlan"
  ]
  # Our startup configuration
  upload {
    content = file("./cthunder/demo.cfg")
    file    = "/tmp/demo.cfg"
  }
  upload {
    content = file("./cthunder/lb-down.tcl")
    file    = "/a10data/aflex/lb-down.arl"
  }
}

locals {
  depends_on = [docker_container.thunder]
  cth_ips = {
    for net in docker_container.thunder.network_data :
    net.network_name => net.ip_address
  }
}

output "outside-net" {
  depends_on = [docker_container.thunder]
  value      = "${local.cth_ips["slb-outside-net"]}"
}