# Terraform Firestore Setup

This directory contains Terraform configuration to set up a Google Cloud project with Firestore for the notes API.

## Quick Start

1. **Prerequisites**:
   - Install [Terraform](https://developer.hashicorp.com/terraform/downloads)
   - Install [Google Cloud CLI](https://cloud.google.com/sdk/docs/install)
   - Authenticate: `gcloud auth application-default login`

2. **Get your billing account ID**:
   ```bash
   gcloud billing accounts list
   ```

3. **Configure variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your billing account ID
   ```

4. **Deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. **Update your application**:
   - Copy the `project_id` from Terraform output
   - Add `GOOGLE_CLOUD_PROJECT_ID=<project_id>` to your `.env` file

## Files

- `main.tf` - Main Terraform configuration
- `terraform.tfvars.example` - Example variables file
- `terraform.tfvars` - Your actual variables (gitignored)

## What Gets Created

- Google Cloud Project with unique ID
- Firestore database in Native mode
- Service account with Firestore permissions
- Required API enablement

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Troubleshooting

- **Billing account error**: Verify your billing account ID and permissions
- **Authentication error**: Run `gcloud auth application-default login`
- **API errors**: The configuration automatically enables required APIs

For detailed instructions, see the main project's `TERRAFORM_FIRESTORE_SETUP.md` file.