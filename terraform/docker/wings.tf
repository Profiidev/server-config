resource "docker_network" "wings" {
  name   = "wings0"
  driver = "bridge"
  ipam_config {
    subnet = "192.168.202.0/24"
  }

  options = {
    "com.docker.network.bridge.name" = "wings0"
  }
}

resource "docker_container" "wings" {
  name    = "pterodactyl_wings"
  image   = "ghcr.io/pterodactyl/wings:latest"
  restart = "unless-stopped"
  networks_advanced {
    name         = docker_network.wings.name
    ipv4_address = "192.168.202.10"
  }
  ports {
    external = 594
    internal = 443
    ip       = "127.0.0.1"
  }
  tty = true
  env = [
    "TZ=UTC",
    "WINGS_UID=988",
    "WINGS_GID=988",
    "WINGS_USERNAME=wings",
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
    host_path      = "/etc/pterodactyl/"
    container_path = "/etc/pterodactyl/"
  }
  volumes {
    host_path      = "/var/lib/pterodactyl/"
    container_path = "/var/lib/pterodactyl/"
  }
  volumes {
    host_path      = "/var/log/pterodactyl/"
    container_path = "/var/log/pterodactyl/"
  }
  volumes {
    host_path      = "/tmp/pterodactyl/"
    container_path = "/tmp/pterodactyl/"
  }
  volumes {
    host_path      = "/etc/ssl/certs"
    container_path = "/etc/ssl/certs"
    read_only      = true
  }
}
