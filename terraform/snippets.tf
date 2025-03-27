data "template_file" "cluster_ca_cert_volume" {
  template = templatefile("${path.module}/../snippets/cluster-ca-cert-volume.tftpl", {
    cluster_ca_cert = var.cluster_ca_cert_var
  })
}

data "template_file" "cluster_ca_cert_volume_mount" {
  template = templatefile("${path.module}/../snippets/cluster-ca-cert-volume-mount.tftpl", {
    cluster_ca_cert = var.cluster_ca_cert_var
  })
}
