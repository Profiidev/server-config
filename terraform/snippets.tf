data "template_file" "cluster-ca-cert-volume" {
  template = templatefile("${path.module}/../snippets/cluster-ca-cert-volume.tftpl", {
    cluster_ca_cert = var.cluster-ca-cert-var
  })
}

data "template_file" "cluster-ca-cert-volume-mount" {
  template = templatefile("${path.module}/../snippets/cluster-ca-cert-volume-mount.tftpl", {
    cluster_ca_cert = var.cluster-ca-cert-var
  })
}
