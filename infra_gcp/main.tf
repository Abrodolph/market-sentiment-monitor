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

data "google_project" "project" {}

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
  target_tags   = ["ssh-server"]
}

# 3b. Firewall Rule (ICMP/Ping)
resource "google_compute_firewall" "icmp_firewall" {
  name    = "allow-icmp"
  network = "default"

  allow {
    protocol = "icmp"
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
  excludes    = [
    "infra/terraform*",
    "infra/sentiment_monitor_key.pem",
    "infra_gcp",
    ".git",
    ".next",
    "node_modules",
    "**/node_modules/**",
    "venv",
    "**/venv/**",
    ".env",
    "**/.env",
    "__pycache__",
    "**/__pycache__/**",
    ".terraform",
    "**/.terraform/**",
    "*.pem",
    "*.zip",
    ".DS_Store"
  ]
}

# 5. Application Source (GCS)
resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "google_storage_bucket" "deploy_bucket" {
  name                        = "sentiment-monitor-deploy-${random_id.bucket_id.hex}"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "viewer" {
  bucket = google_storage_bucket.deploy_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

resource "google_storage_bucket_object" "app_source_zip" {
  name   = "app_source.zip"
  bucket = google_storage_bucket.deploy_bucket.name
  source = data.archive_file.app_source.output_path
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

  service_account {
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = {
    startup-script = <<-EOF
      #!/bin/bash
      apt-get update
      apt-get install -y docker.io docker-compose unzip
      systemctl start docker
      systemctl enable docker

      # Add swap space (e2-micro only has 1GB RAM, npm install/build needs more)
      fallocate -l 4G /swapfile
      chmod 600 /swapfile
      mkswap /swapfile
      swapon /swapfile
      echo '/swapfile none swap sw 0 0' >> /etc/fstab

      mkdir -p ~/app
      gsutil cp gs://${google_storage_bucket.deploy_bucket.name}/app_source.zip /tmp/app_source.zip
      unzip -o /tmp/app_source.zip -d ~/app
      cd ~/app

      echo 'TAVILY_API_KEY=${var.tavily_api_key}' > .env
      echo 'GEMINI_API_KEY=${var.gemini_api_key}' >> .env
      echo 'POSTGRES_PASSWORD=${var.postgres_password}' >> .env
      echo 'DATABASE_URL=postgresql://user:${var.postgres_password}@db:5432/sentiment_db' >> .env

      sudo docker-compose up -d --build
    EOF
  }
}

output "public_ip" {
  value = google_compute_address.static_ip.address
}
