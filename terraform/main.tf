terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Variables
variable "billing_account_id" {
  description = "The billing account ID to associate with the project"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "notes-api"
}

variable "region" {
  description = "The default region for resources"
  type        = string
  default     = "us-central1"
}

# Random suffix for unique project ID
resource "random_id" "project_suffix" {
  byte_length = 4
}

# Create Google Cloud Project
resource "google_project" "notes_project" {
  name            = var.project_name
  project_id      = "${var.project_name}-${random_id.project_suffix.hex}"
  billing_account = var.billing_account_id
}

# Enable required APIs
resource "google_project_service" "firestore_api" {
  project = google_project.notes_project.project_id
  service = "firestore.googleapis.com"
}

resource "google_project_service" "cloud_resource_manager_api" {
  project = google_project.notes_project.project_id
  service = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "artifact_registry_api" {
  project = google_project.notes_project.project_id
  service = "artifactregistry.googleapis.com"
}

resource "google_project_service" "cloud_build_api" {
  project = google_project.notes_project.project_id
  service = "cloudbuild.googleapis.com"
}

# Create Artifact Registry repository
resource "google_artifact_registry_repository" "notes_api_repo" {
  project       = google_project.notes_project.project_id
  location      = var.region
  repository_id = "notes-api-repo"
  description   = "Docker repository for Notes API"
  format        = "DOCKER"

  depends_on = [google_project_service.artifact_registry_api]
}

# Create Firestore Database
resource "google_firestore_database" "notes_database" {
  project     = google_project.notes_project.project_id
  name        = "(default)"
  location_id = var.region
  type        = "FIRESTORE_NATIVE"

  depends_on = [google_project_service.firestore_api]
}

# Create service account for the notes API
resource "google_service_account" "notes_api_sa" {
  project      = google_project.notes_project.project_id
  account_id   = "notes-api-service"
  display_name = "Notes API Service Account"
}

# Grant Firestore permissions to service account
resource "google_project_iam_member" "firestore_user" {
  project = google_project.notes_project.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.notes_api_sa.email}"
}

# Outputs
output "project_id" {
  description = "The ID of the created project"
  value       = google_project.notes_project.project_id
}

output "project_number" {
  description = "The number of the created project"
  value       = google_project.notes_project.number
}

output "firestore_database_name" {
  description = "The name of the Firestore database"
  value       = google_firestore_database.notes_database.name
}

output "service_account_email" {
  description = "The email of the service account"
  value       = google_service_account.notes_api_sa.email
}

output "artifact_registry_repository" {
  description = "The name of the Artifact Registry repository"
  value       = google_artifact_registry_repository.notes_api_repo.name
}

output "docker_image_url" {
  description = "The base URL for Docker images in Artifact Registry"
  value       = "${var.region}-docker.pkg.dev/${google_project.notes_project.project_id}/${google_artifact_registry_repository.notes_api_repo.repository_id}"
}

output "next_steps" {
  description = "Next steps to configure your application"
  value = <<-EOT
    1. Update your .env file with: GOOGLE_CLOUD_PROJECT_ID=${google_project.notes_project.project_id}
    2. Authenticate your application: gcloud auth application-default login
    3. Configure Docker for Artifact Registry: gcloud auth configure-docker ${var.region}-docker.pkg.dev
    4. Test your Dart application connection
    5. Build and push your Docker image using Cloud Build
  EOT
}