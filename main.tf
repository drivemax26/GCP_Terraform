
provider "google" {
  credentials = file("prismatic-cider-395810-ea020e5f7d54.json") 
  project     = var.project
  region      = var.region
  zone        = var.zone
}



resource "google_compute_subnetwork" "network-with-private-secondary-ip-ranges" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.my_network.id
  
}

resource "google_compute_network" "my_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
}


data "google_compute_image" "image" {
  family  = var.image_family
  project = var.image_project
}


resource "google_compute_instance" "my_instance" {
  name         = var.instance_name
  machine_type = var.instance_type
  zone         = var.zone
  tags         = var.network_tags

  boot_disk {
    initialize_params {
      image = data.google_compute_image.image.self_link
    }
  }

  network_interface {
    network = google_compute_network.my_network.self_link
    subnetwork = google_compute_subnetwork.network-with-private-secondary-ip-ranges.self_link
  }


  metadata_startup_script = <<-EOF
#!bin/bash

sudo apt update && sudo apt upgrade -y

sudo apt install apache2 -y

sudo systemctl enable apache2
sudo systemctl start apache2

echo "Welcome to GCP!" > /var/www/html/index.html
EOF

    metadata = {
    environment = var.environment
  }

}


resource "google_compute_firewall" "my_firewall" {
  name    = "allow-ports"
  network = google_compute_network.my_network.self_link

  allow {
    protocol = "tcp"
    ports    = var.allowed_ports
  }

  source_ranges = ["0.0.0.0/0"]
}
