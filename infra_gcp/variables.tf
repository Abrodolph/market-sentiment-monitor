variable "project_id" {
  description = "The GCP Project ID"
  type        = string
  default     = "project-a5506ace-ab0c-4636-b97"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "GCP machine type (e2-micro is free tier)"
  type        = string
  default     = "e2-micro"
}

variable "tavily_api_key" {
  description = "Tavily API Key"
  type        = string
  sensitive   = true
}

variable "gemini_api_key" {
  description = "Gemini/OpenAI API Key"
  type        = string
  sensitive   = true
}

variable "postgres_password" {
  description = "Postgres Database Password"
  type        = string
  sensitive   = true
  default     = "your_secure_password"
}
