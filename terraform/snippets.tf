data "template_file" "cluster-ca-cert-volume" {
  template = file("${path.module}/../snippets/cluster-ca-cert-volume.yaml")
}

data "template_file" "cluster-ca-cert-volume-mount" {
  template = file("${path.module}/../snippets/cluster-ca-cert-volume-mount.yaml")
}
