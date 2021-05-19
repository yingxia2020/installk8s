// Configure the Google Cloud provider
provider "google" {
  credentials = file(var.cred_file)
  project     = var.project_name
  region      = var.region_name
}

resource "google_compute_disk" "cnb-disk" {
  for_each = toset(var.vm_name)
  name     = "${each.value}-disk"
  type     = "pd-ssd"
  zone     = var.location
  image    = "ubuntu-1804-bionic-v20200807"
  size     = var.disk_size
}

resource "google_compute_instance" "mynode" {
  for_each     = toset(var.vm_name)
  name         = each.value
  machine_type = var.vm_size[index(var.vm_name, each.value)]
  zone         = var.location

  boot_disk {
    #    initialize_params {
    #      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    #    }
    source = google_compute_disk.cnb-disk[each.key].name
  }

  metadata = {
    ssh-keys = "${var.user_name}:${file(var.ssh_keys)}"
  }

  network_interface {
    # A default network is created for all GCP projects
    # network = "default"
    subnetwork = google_compute_subnetwork.subnet_public.name

    access_config {
      // Include this section to give the VM an external ip address
    }
  }
}

resource "google_compute_network" "vpc" {
  name                    = "${var.proj_name}-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "subnet_public" {
  name = "${var.proj_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  network = "${var.proj_name}-vpc"
  depends_on    = [google_compute_network.vpc]
  region      = var.region_name
}

resource "google_compute_firewall" "firewall_public" {
  name    = "${var.proj_name}-firewall-public"
  network = google_compute_network.vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.ingress_cidr]
}

resource "google_compute_firewall" "firewall_private" {
  name    = "${var.proj_name}-firewall-private"
  network = google_compute_network.vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["1-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["1-65535"]
  }

  source_ranges = [var.subnet_cidr]
}

output "instance_ip_addresses" {
  value = {
    for instance in google_compute_instance.mynode :
    instance.name => [instance.network_interface.0.access_config.0.nat_ip, instance.network_interface.0.network_ip]
  }
}
