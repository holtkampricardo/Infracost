data "external" "modules" {
  program = ["python3", "${path.module}/read_yaml.py"]
}

# Decodificamos el JSON que viene como string
locals {
  vm_list = { for idx, m in jsondecode(data.external.modules.result.modules_json) : idx => m }
}

module "vm_instance" {
  for_each    = local.vm_list
  source      = "./modules/vm_instance"
  name        = each.value["params"]["name"]
  machine_type= each.value["params"]["machine_type"]
  zone        = each.value["params"]["zone"]
  disk_size_gb= each.value["params"]["disk_size_gb"]
  disk_type   = each.value["params"]["disk_type"]
  network     = each.value["params"]["network"]
  sa_email    = "555132573296-compute@developer.gserviceaccount.com"
}
