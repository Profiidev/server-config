resource "docker_network" "pl_panel" {
  name = "pelican_panel"
  ipam_config {
    subnet = "192.168.101.0/24"
  }
}

resource "docker_volume" "pl_var" {
  name = "pelican_var"
}

resource "docker_volume" "pl_logs" {
  name = "pelican_logs"
}

# copy caddyfile to /etc on remote host
resource "terraform_data" "pl_caddyfile" {
  triggers_replace = [
    filebase64sha256("${path.module}/Caddyfile"),
  ]

  connection {
    type  = "ssh"
    user  = "root"
    host  = var.k8s_api
    agent = true
  }

  provisioner "file" {
    source      = "${path.module}/Caddyfile"
    destination = "/tmp/Caddyfile-pelican"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /etc/pelican",
      "mv /tmp/Caddyfile-pelican /etc/pelican/Caddyfile",
    ]
  }
}

resource "docker_container" "pl_panel" {
  name    = "pelican_panel"
  image   = "ghcr.io/pelican-dev/panel:latest"
  restart = "unless-stopped"
  ports {
    internal = 80
    external = 793
  }
  volumes {
    volume_name    = docker_volume.pl_var.name
    container_path = "/pelican-data"
  }
  volumes {
    volume_name    = docker_volume.pl_logs.name
    container_path = "/var/www/html/storage/logs"
  }
  volumes {
    volume_name    = "/etc/pelican/Caddyfile"
    container_path = "/etc/caddy/Caddyfile"
  }
  networks_advanced {
    name         = docker_network.pl_panel.name
    ipv4_address = "192.168.101.10"
  }
  env = [
    "XDG_DATA_HOME=/pelican-data",
    "APP_URL=https://pelican.profidev.io",
    "ADMIN_EMAIL=${var.email}",
  ]

  depends_on = [terraform_data.pl_caddyfile]
}
