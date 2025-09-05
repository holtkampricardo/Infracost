# POC: Creating a Specific VM in GCP with Terraform, Modules, and Infracost

This project demonstrates how to create a VM in Google Cloud Platform using Terraform with a reusable module, parameters from a YAML file, and estimate costs using Infracost.

## 1. File Structure
```text
POC_Infracost/
├─ main.tf                   # Root Terraform module
├─ modules.yaml              # Module parameters and VM definitions
├─ read_yaml.py              # Python script to read YAML
├─ modules/
│  └─ vm_instance/
│     └─ main.tf             # VM module
├─ key.json                  # GCP service account credentials
└─ .venv/                    # Python virtual environment (optional)
```
## 2. YAML Configuration (modules.yaml)

Defines the modules and VM parameters:
```
modules:
  - name: vm_instance
    params:
      name: my-single-vm
      machine_type: e2-micro
      zone: us-central1-a
      disk_size_gb: 10
      disk_type: pd-standard
      network: default
```
## 3. Python Script to Read YAML (read_yaml.py)

Converts YAML into JSON for Terraform:
```
#!/usr/bin/env python3
import yaml, json

with open("modules.yaml") as f:
    data = yaml.safe_load(f)
```
### Convert the module list to a valid JSON map
```
output = {"modules_json": json.dumps(data["modules"])}
print(json.dumps(output))
```

Note: You must install PyYAML in your Python environment.

## 4. VM Module (modules/vm_instance/main.tf)
```
variable "name"          { type = string }
variable "machine_type"  { type = string }
variable "zone"          { type = string }
variable "disk_size_gb"  { type = number }
variable "disk_type"     { type = string }
variable "network"       { type = string }
variable "sa_email"      { type = string }

resource "google_compute_instance" "this" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = var.disk_size_gb
      type  = var.disk_type
    }
  }

  scratch_disk {
    interface = "NVME"
  }

  network_interface {
    network = var.network
    access_config {}
  }

  metadata_startup_script = "echo hi > /test.txt"

  service_account {
    email  = var.sa_email
    scopes = ["cloud-platform"]
  }
}

output "instance_self_link" {
  value = google_compute_instance.this.self_link
}
```
## 5. Root Module (main.tf)
```
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "~> 6.0" }
  }
}

provider "google" {
  project = "aqueous-depth-471107-j6"
  region  = "us-central1"
}

# Service account for the VM
resource "google_service_account" "default" {
  account_id   = "my-custom-sa"
  display_name = "Custom SA for VM Instance"
}

# Read YAML using external data source
data "external" "modules" {
  program = ["python3", "${path.module}/read_yaml.py"]
}

# Decode JSON string into module list
locals {
  vm_list = { for idx, m in jsondecode(data.external.modules.result.modules_json) : idx => m }
}

# Launch module for each YAML entry
module "vm_instance" {
  for_each    = local.vm_list
  source      = "./modules/vm_instance"
  name        = each.value["params"]["name"]
  machine_type= each.value["params"]["machine_type"]
  zone        = each.value["params"]["zone"]
  disk_size_gb= each.value["params"]["disk_size_gb"]
  disk_type   = each.value["params"]["disk_type"]
  network     = each.value["params"]["network"]
  sa_email    = google_service_account.default.email
}
```
## 6. Python Virtual Environment (Optional)

It is recommended to create a virtual environment to install PyYAML:
```
python3 -m venv .venv
source .venv/bin/activate
pip install pyyaml
```
## 7. Main Terraform and Infracost Commands
### Authenticate with GCP
```
export GOOGLE_APPLICATION_CREDENTIALS="key.json"
gcloud auth application-default login
```
### Initialize Terraform
```
terraform init
```
### Create plan
```
terraform plan -out=tfplan.binary
```
### Apply plan
```
terraform apply tfplan.binary
```
### Generate Infracost report
```
infracost breakdown --path tfplan.binary --project-name aqueous-depth-471107-j6 --show-skipped
infracost output --path=tfplan.binary --format html > infracost_report.html
open infracost_report.html
```
## 8. Important Notes

* All VM parameters come from the YAML, enabling modularity and scalability.

* data "external" requires the script to return a JSON map of strings, so we use json.dumps() in Python.

* The service account must be declared in the root module before using it in modules.

* To avoid PyYAML errors, always use a virtual environment and install pyyaml.