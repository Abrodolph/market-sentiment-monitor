terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# 1. External IP Address
resource "google_compute_address" "static_ip" {
  name = "sentiment-monitor-ip"
}

# 2. Firewall Rule (HTTP)
resource "google_compute_firewall" "http_firewall" {
  name    = "allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# 3. Firewall Rule (SSH)
resource "google_compute_firewall" "ssh_firewall" {
  name    = "allow-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# 4. SSH Key Generation
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/sentiment_gcp_key.pem"
  file_permission = "0400"
}

# 5. Archive Application Source
data "archive_file" "app_source" {
  type        = "zip"
  source_dir  = "${path.module}/.."
  output_path = "${path.module}/app_source.zip"
  excludes    = ["infra", ".git", ".next", "node_modules", "venv", ".env", "sentiment_monitor_deploy_key.pem", "*.zip", "sentiment_gcp_key.pem"]
}

# 6. Compute Engine Instance
resource "google_compute_instance" "app_server" {
  name         = "sentiment-monitor-vm"
  machine_type = var.machine_type
  tags         = ["http-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.static_ip.address
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${tls_private_key.ssh_key.public_key_openssh}"
    startup-script = <<-EOF
      #!/bin/bash
      apt-get update
      apt-get install -y docker.io docker-compose unzip
      systemctl start docker
      systemctl enable docker
    EOF
  }

  # Provisioning
  provisioner "file" {
    source      = data.archive_file.app_source.output_path
    destination = "/tmp/app_source.zip"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.ssh_key.private_key_pem
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p ~/app",
      "unzip -o /tmp/app_source.zip -d ~/app",
      "cd ~/app",
      "echo 'TAVILY_API_KEY=${var.tavily_api_key}' > .env",
      "echo 'GEMINI_API_KEY=${var.gemini_api_key}' >> .env",
      "echo 'POSTGRES_PASSWORD=${var.postgres_password}' >> .env",
      "echo 'DATABASE_URL=postgresql://user:${var.postgres_password}@db:5432/sentiment_db' >> .env",
      "sudo docker-compose up -d --build"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.ssh_key.private_key_pem
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }
}

output "public_ip" {
  value = google_compute_address.static_ip.address
}
