##
##  main.tf
##  -- Basic Thunder Container SLB Demo
##
##  Required:
##  - cthunder.tf
##
##  John D. Allen
##  Sr. Solutions Engineer
##  A10 Networks, Inc.
##  August, 2020
##
##  Licensed under Apache-2.0 for private use.
##  All other Rights Reserved.
##
terraform {
  required_version = ">= 0.12"
  required_providers {
    docker = ">= 2.7.2"
  }
}

provider "docker" {
  host = "tcp://192.168.99.99:2375/"
}

# Network where server(s) are located
resource "docker_network" "slb-inside-net" {
  name   = "slb-inside-net"
  driver = "macvlan"
}

# Network accessible from outside nodes
resource "docker_network" "slb-outside-net" {
  name   = "slb-outside-net"
  driver = "bridge"
}

##
## Portainer
## - Docker Management GUI -- Highly Recommended!
##   https://www.portainer.io/
##
resource "docker_image" "portainer" {
  name         = "portainer/portainer:latest"
  keep_locally = true
}

resource "docker_container" "portainer" {
  image = docker_image.portainer.latest
  name  = "portainer"
  ports {
    internal = 8000
    external = 8000
  }
  ports {
    internal = 9000
    external = 9000
  }
  restart = "always"
  volumes {
    volume_name    = "portainer_data"
    container_path = "/data"
  }
  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }
}

##
## nginx Web Servers
##
resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = true
}

resource "docker_container" "nginx1" {
  depends_on = [docker_network.slb-inside-net]
  image      = docker_image.nginx.latest
  name       = "nginx1"
  ports {
    internal = 80
    external = 80
  }
  networks_advanced {
    name = "slb-inside-net"
  }
  restart = "always"
}

resource "docker_container" "nginx2" {
  depends_on = [docker_network.slb-inside-net]
  image      = docker_image.nginx.latest
  name       = "nginx2"
  ports {
    internal = 80
    external = 80
  }
  networks_advanced {
    name = "slb-inside-net"
  }
  restart = "always"
}

##
##  Syslog Server
##  - Simple Syslog server
##    https://github.com/jdallen-a10/syslog-ng
##
resource "docker_image" "syslog" {
  name         = "jdallen/syslog-ng:latest"
  keep_locally = true
}

resource "docker_container" "syslog" {
  depends_on = [docker_network.slb-outside-net]
  image      = docker_image.syslog.latest
  name       = "syslog"
  ports {
    protocol = "udp"
    internal = 514
    external = 514
  }
  ports {
    internal = 601
    external = 601
  }
  restart = "always"
  networks_advanced {
    name = "slb-outside-net"
  }
  volumes {
    host_path      = "/root/terraform/basic-slb/syslog/log"
    container_path = "/var/log"
  }
  upload {
    content = file("./syslog/syslog-ng.conf")
    file    = "/etc/syslog-ng/syslog-ng.conf"
  }
}

##
## revproxy
## - Simple HTTP Reverse Proxy
##   Not necessarily needed, but nice to have for accessing web pages
##   https://github.com/john2exonets/http-reverse-proxy
##
resource "docker_image" "revproxy" {
  name = "jdallen/revproxy:latest"
  keep_locally = true
}

resource "docker_container" "revproxy" {
  depends_on = [
    docker_container.cthunder,
    docker_network.slb-outside-net
  ]
  image = docker_image.revproxy.latest
  name = "revproxy"
  ports {
    protocol = "tcp"
    internal = 8080
    external = 8080
  }
  networks_advanced {
    name = "bridge"
  }
  networks_advanced {
    name = "slb-outside-net"
  }
  env = [
    "REVPROX_PORT=8080",
    "REVPROX_LOCAL_IP=0.0.0.0",
    "REVPROX_REMOTE=${local.cth_ips["slb-outside-net"]}:881"
  ]
  restart="always"
}
