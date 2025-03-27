module "crds" {
  source  = "rpadovani/helm-crds/kubectl"
  version = "1.0.0"

  crds_urls = [
    //metallb
    "https://raw.githubusercontent.com/metallb/metallb/refs/tags/v0.14.9/charts/metallb/charts/crds/templates/crds.yaml",

    //external-secrets
    "https://raw.githubusercontent.com/external-secrets/external-secrets/refs/tags/v0.15.0/config/crds/bases/external-secrets.io_clusterexternalsecrets.yaml",
    "https://raw.githubusercontent.com/external-secrets/external-secrets/refs/tags/v0.15.0/config/crds/bases/external-secrets.io_clusterpushsecrets.yaml",
    "https://raw.githubusercontent.com/external-secrets/external-secrets/refs/tags/v0.15.0/config/crds/bases/external-secrets.io_clustersecretstores.yaml",
    "https://raw.githubusercontent.com/external-secrets/external-secrets/refs/tags/v0.15.0/config/crds/bases/external-secrets.io_externalsecrets.yaml",
    "https://raw.githubusercontent.com/external-secrets/external-secrets/refs/tags/v0.15.0/config/crds/bases/external-secrets.io_pushsecrets.yaml",
    "https://raw.githubusercontent.com/external-secrets/external-secrets/refs/tags/v0.15.0/config/crds/bases/external-secrets.io_secretstores.yaml",
    "https://raw.githubusercontent.com/external-secrets/external-secrets/refs/tags/v0.15.0/config/crds/bases/generators.external-secrets.io_acraccesstokens.yaml",
    "https://raw.githubusercontent.com/external-secrets/external-secrets/refs/tags/v0.15.0/config/crds/bases/generators.external-secrets.io_clustergenerators.yaml",
    "https://raw.githubusercontent.com/external-secrets/external-secrets/refs/tags/v0.15.0/config/crds/bases/generators.external-secrets.io_ecrauthorizationtokens.yaml",
    "https://raw.githubusercontent.com/external-secrets/external-secrets/refs/tags/v0.15.0/config/crds/bases/generators.external-secrets.io_fakes.yaml",
    "https://raw.githubusercontent.com/external-secrets/external-secrets/refs/tags/v0.15.0/config/crds/bases/generators.external-secrets.io_gcraccesstokens.yaml",
    "https://raw.githubusercontent.com/external-secrets/external-secrets/refs/tags/v0.15.0/config/crds/bases/generators.external-secrets.io_generatorstates.yaml",
    "https://raw.githubusercontent.com/external-secrets/external-secrets/refs/tags/v0.15.0/config/crds/bases/generators.external-secrets.io_githubaccesstokens.yaml",
    "https://raw.githubusercontent.com/external-secrets/external-secrets/refs/tags/v0.15.0/config/crds/bases/generators.external-secrets.io_grafanas.yaml",
    "https://raw.githubusercontent.com/external-secrets/external-secrets/refs/tags/v0.15.0/config/crds/bases/generators.external-secrets.io_passwords.yaml",
    "https://raw.githubusercontent.com/external-secrets/external-secrets/refs/tags/v0.15.0/config/crds/bases/generators.external-secrets.io_quayaccesstokens.yaml",
    "https://raw.githubusercontent.com/external-secrets/external-secrets/refs/tags/v0.15.0/config/crds/bases/generators.external-secrets.io_stssessiontokens.yaml",
    "https://raw.githubusercontent.com/external-secrets/external-secrets/refs/tags/v0.15.0/config/crds/bases/generators.external-secrets.io_uuids.yaml",
    "https://raw.githubusercontent.com/external-secrets/external-secrets/refs/tags/v0.15.0/config/crds/bases/generators.external-secrets.io_vaultdynamicsecrets.yaml",
    "https://raw.githubusercontent.com/external-secrets/external-secrets/refs/tags/v0.15.0/config/crds/bases/generators.external-secrets.io_webhooks.yaml",

    //cert-manager
    "https://github.com/cert-manager/cert-manager/releases/download/v1.12.16/cert-manager.crds.yaml"
  ]
}
