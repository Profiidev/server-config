terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
  }
}

variable "crds" {
  type = set(string)
  default = [
    //metallb
    "https://raw.githubusercontent.com/metallb/metallb/refs/tags/v0.14.9/charts/metallb/charts/crds/templates/crds.yaml",

    //external-secrets
    "https://raw.githubusercontent.com/external-secrets/external-secrets/refs/tags/v0.15.0/deploy/crds/bundle.yaml",

    //cert-manager
    "https://github.com/cert-manager/cert-manager/releases/download/v1.12.16/cert-manager.crds.yaml"
  ]
}

data "http" "yaml_file" {
  for_each = toset(var.crds)
  url      = each.value
}

resource "null_resource" "status_check" {
  for_each = toset(var.crds)
  provisioner "local-exec" {
    command = contains([200, 201, 204], data.http.yaml_file[each.value].status_code)
  }
}

resource "kubectl_manifest" "crd" {
  for_each = {
    for idx, yaml in flatten([
      for key, part in data.http.yaml_file : split("---", part.response_body)
    ]) : "${idx}" => yaml
    if try(yamldecode(yaml), null) != null
  }

  depends_on = [null_resource.status_check]

  yaml_body = each.value

  force_new         = false
  server_side_apply = false
  force_conflicts   = false
  apply_only        = false
}
