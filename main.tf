module "config" {
  source = "./terraform"
}

output "all_module_outputs" {
  value = {
    for k, v in module.config : k => v
  }
}
