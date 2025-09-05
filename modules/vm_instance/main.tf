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
  project     = "aqueous-depth-471107-j6"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = var.disk_size_gb
      type  = var.disk_type
    }
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
