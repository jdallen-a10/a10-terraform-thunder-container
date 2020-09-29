##
##  Thunder Container Terraform file
##
##  John D. Allen
##  Sr. Solutions Engineer
##  A10 Networks, Inc.
##  August, 2020
##
##  Licensed under Apache-2.0 for private use.
##  All other Rights Reserved.
##

 resource "docker_image" "cthunder" {
   name         = "acos_docker_5_2_0-p1_31:latest"
   keep_locally = true
 }

resource "docker_container" "cthunder" {
  depends_on = [
    docker_network.slb-outside-net,
    docker_network.slb-inside-net
  ]
  image = docker_image.cthunder.latest
  name  = "cthunder52"
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
}

#
#  Setup local vars for use by main.tf
locals {
  depends_on = [docker_container.cthunder]
  cth_ips = {
    for net in docker_container.cthunder.network_data :
    net.network_name => net.ip_address
  }
}

#
# Print out the Incoming IP address where connections to the SLB are made.
output "ips" {
  depends_on = [docker_container.cthunder]
  value = "${local.cth_ips["slb-outside-net"]}"
}
