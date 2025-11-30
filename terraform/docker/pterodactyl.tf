resource "docker_network" "pt_panel" {
  name = "pterodactyl_panel"
  ipam_config {
    subnet = "192.168.201.0/24"
  }
}

resource "docker_volume" "pt_db" {
  name = "pterodactyl_db"
}

resource "docker_volume" "pt_var" {
  name = "pterodactyl_var"
}

resource "docker_volume" "pt_nginx" {
  name = "pterodactyl_nginx"
}

resource "docker_volume" "pt_certs" {
  name = "pterodactyl_certs"
}

resource "docker_volume" "pt_logs" {
  name = "pterodactyl_logs"
}

resource "random_password" "pt_db_pw" {
  length  = 16
  special = true
}

resource "random_password" "pt_db_root_pw" {
  length  = 16
  special = true
}

resource "docker_container" "pt_db" {
  name    = "pterodactyl_db"
  image   = "mariadb:10.5"
  restart = "unless-stopped"
  command = [
    "--default-authentication-plugin=mysql_native_password",
  ]
  volumes {
    volume_name    = docker_volume.pt_db.name
    container_path = "/var/lib/mysql"
  }
  networks_advanced {
    name         = docker_network.pt_panel.name
    ipv4_address = "192.168.201.12"
  }
  env = [
    "MYSQL_DATABASE=panel",
    "MYSQL_USER=pterodactyl",
    "MYSQL_PASSWORD=${random_password.pt_db_pw.result}",
    "MYSQL_ROOT_PASSWORD=${random_password.pt_db_root_pw.result}",
  ]
}

resource "docker_container" "pt_cache" {
  name    = "pterodactyl_cache"
  image   = "redis:alpine"
  restart = "unless-stopped"
  networks_advanced {
    name         = docker_network.pt_panel.name
    ipv4_address = "192.168.201.11"
  }
}

resource "docker_container" "pt_panel" {
  name    = "pterodactyl_panel"
  image   = "ghcr.io/pterodactyl/panel:latest"
  restart = "unless-stopped"
  ports {
    internal = 80
    external = 593
  }
  volumes {
    volume_name    = docker_volume.pt_var.name
    container_path = "/app/var/"
  }
  volumes {
    volume_name    = docker_volume.pt_nginx.name
    container_path = "/etc/nginx/http.d/"
  }
  volumes {
    volume_name    = docker_volume.pt_certs.name
    container_path = "/etc/letsencrypt/"
  }
  volumes {
    volume_name    = docker_volume.pt_logs.name
    container_path = "/app/storage/logs"
  }
  networks_advanced {
    name         = docker_network.pt_panel.name
    ipv4_address = "192.168.201.10"
  }
  env = [
    "DB_PORT=3306",
    "DB_HOST=pterodactyl_db",
    "REDIS_HOST=pterodactyl_cache",
    "QUEUE_DRIVER=redis",
    "CACHE_DRIVER=redis",
    "SESSION_DRIVER=redis",
    "APP_ENVIRONMENT_ONLY=false",
    "APP_ENV=production",
    "DB_PASSWORD=${random_password.pt_db_pw.result}",
    "APP_URL=https://panel.profidev.io",
    "APP_TIMEZONE=UTC",
    "APP_SERVICE_AUTHOR=no-reply@profidev.io",
    "MAIL_FROM=no-reply@profidev.io",
    "MAIL_DRIVER=smtp",
    "MAIL_HOST=smtp.protonmail.ch",
    "MAIL_PORT=587",
    "MAIL_USERNAME=no-reply@profidev.io",
    "MAIL_PASSWORD=${var.smtp_password}",
    "MAIL_ENCRYPTION=true",
  ]

  depends_on = [
    docker_container.pt_db,
    docker_container.pt_cache,
  ]
}
