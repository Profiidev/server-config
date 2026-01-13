resource "docker_network" "pl_wings" {
  name   = "pl_wings0"
  driver = "bridge"
  ipam_config {
    subnet = "192.168.102.0/24"
  }

  options = {
    "com.docker.network.bridge.name" = "pl_wings0"
  }
}

resource "docker_container" "pl_wings" {
  name    = "pelican_wings"
  image   = "ghcr.io/pelican-dev/wings:latest"
  restart = "unless-stopped"
  networks_advanced {
    name         = docker_network.pl_wings.name
    ipv4_address = "192.168.102.10"
  }
  ports {
    external = 794
    internal = 443
  }
  tty = true
  env = [
    "TZ=UTC",
    "WINGS_UID=988",
    "WINGS_GID=988",
    "WINGS_USERNAME=pelican",
  ]
  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }
  volumes {
    host_path      = "/var/lib/docker/containers/"
    container_path = "/var/lib/docker/containers/"
  }
  volumes {
    host_path      = "/etc/pelican/"
    container_path = "/etc/pelican/"
  }
  volumes {
    host_path      = "/var/lib/pelican/"
    container_path = "/var/lib/pelican/"
  }
  volumes {
    host_path      = "/var/log/pelican/"
    container_path = "/var/log/pelican/"
  }
  volumes {
    host_path      = "/tmp/pelican/"
    container_path = "/tmp/pelican/"
  }
  volumes {
    host_path      = "/mnt/ssl"
    container_path = "/etc/ssl/certs"
    read_only      = true
  }
}
