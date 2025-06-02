# Simplified Terraform Firestore Setup

This document outlines a minimal Terraform configuration to set up a Google Cloud project with Firestore for your notes API.

## Overview

This setup creates:
- A new Google Cloud project
- Firestore database in Native mode
- Basic service account for API access
- Required API enablement

## Prerequisites

1. **Terraform CLI** - [Install Terraform](https://developer.hashicorp.com/terraform/downloads)
2. **Google Cloud CLI** - [Install gcloud](https://cloud.google.com/sdk/docs/install)
3. **Google Cloud Authentication**:
   ```bash
   gcloud auth application-default login
   ```
4. **Billing Account ID** - Get this from Google Cloud Console > Billing

## Project Structure

```
terraform/
├── main.tf                      # Main Terraform configuration
├── terraform.tfvars            # Your variable values (gitignored)
├── terraform.tfvars.example    # Example variable file
└── README.md                   # This file
```

## Configuration Files

### main.tf
```hcl
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

output "next_steps" {
  description = "Next steps to configure your application"
  value = <<-EOT
    1. Update your .env file with: GOOGLE_CLOUD_PROJECT_ID=${google_project.notes_project.project_id}
    2. Authenticate your application: gcloud auth application-default login
    3. Test your Dart application connection
  EOT
}
```

### terraform.tfvars.example
```hcl
# Copy this file to terraform.tfvars and fill in your values
billing_account_id = "YOUR_BILLING_ACCOUNT_ID"
project_name       = "notes-api"
region            = "us-central1"
```

## Setup Instructions

### 1. Get Your Billing Account ID
```bash
gcloud billing accounts list
```

### 2. Create Terraform Directory
```bash
mkdir terraform
cd terraform
```

### 3. Create Configuration Files
Create the `main.tf` file with the configuration above.

### 4. Configure Variables
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your billing account ID
```

### 5. Initialize and Apply Terraform
```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### 6. Update Your Application
After Terraform completes, update your `.env` file:
```bash
# Add this to your .env file
GOOGLE_CLOUD_PROJECT_ID=<project_id_from_terraform_output>
```

### 7. Test Your Application
```bash
# Make sure you're authenticated
gcloud auth application-default login

# Run your Dart application
dart run bin/server.dart
```

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Security Notes

- This setup uses Application Default Credentials for authentication
- The service account has minimal Firestore permissions
- For production, consider additional security measures like VPC, IAM conditions, etc.

## Troubleshooting

### Common Issues:

1. **Billing Account Error**: Make sure your billing account ID is correct and you have permissions
2. **API Not Enabled**: The configuration automatically enables required APIs
3. **Authentication Error**: Run `gcloud auth application-default login`
4. **Project ID Conflicts**: The random suffix prevents naming conflicts

### Useful Commands:
```bash
# Check Terraform state
terraform show

# View outputs
terraform output

# Check Google Cloud projects
gcloud projects list
```

## Next Steps

Once your Firestore is set up, you can:
1. Test your notes API endpoints
2. Add Firestore security rules
3. Set up additional environments
4. Add monitoring and logging
5. Implement authentication