#!/bin/bash

# GitHub Actions Setup Script for Cloud Run Deployment
# This script helps set up the service account and permissions needed for GitHub Actions

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if gcloud is installed and authenticated
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 > /dev/null; then
        print_error "No active gcloud authentication found. Please run 'gcloud auth login' first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to get project ID
get_project_id() {
    if [ -z "$PROJECT_ID" ]; then
        PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
        if [ -z "$PROJECT_ID" ]; then
            print_error "No project ID found. Please set PROJECT_ID environment variable or configure gcloud default project."
            exit 1
        fi
    fi
    print_status "Using project ID: $PROJECT_ID"
}

# Function to enable required APIs
enable_apis() {
    print_status "Enabling required APIs..."
    
    local apis=(
        "cloudbuild.googleapis.com"
        "artifactregistry.googleapis.com"
        "run.googleapis.com"
        "iam.googleapis.com"
    )
    
    for api in "${apis[@]}"; do
        print_status "Enabling $api..."
        gcloud services enable "$api" --project="$PROJECT_ID"
    done
    
    print_success "All required APIs enabled"
}


# Function to grant IAM roles
grant_permissions() {
    local sa_email="$1"
    
    print_status "Granting IAM roles to service account..."
    
    local roles=(
        "roles/cloudbuild.builds.editor"
        "roles/run.admin"
        "roles/artifactregistry.reader"
        "roles/iam.serviceAccountUser"
        "roles/storage.admin"
    )
    
    for role in "${roles[@]}"; do
        print_status "Granting role: $role"
        gcloud projects add-iam-policy-binding "$PROJECT_ID" \
            --member="serviceAccount:${sa_email}" \
            --role="$role" \
            --quiet
    done
    
    print_success "All IAM roles granted"
}

# Function to create service account key
create_service_account_key() {
    local sa_email="$1"
    local key_file="github-actions-key.json"
    
    print_status "Creating service account key..."
    
    gcloud iam service-accounts keys create "$key_file" \
        --iam-account="$sa_email" \
        --project="$PROJECT_ID"
    
    print_success "Service account key created: $key_file"
    
    # Generate base64 encoded key
    print_status "Generating base64 encoded key for GitHub Secrets..."
    local base64_key
    if command -v base64 &> /dev/null; then
        base64_key=$(base64 -i "$key_file")
    else
        print_error "base64 command not found. Please encode the key manually."
        return 1
    fi
    
    echo ""
    print_success "Setup completed! Please add the following secrets to your GitHub repository:"
    echo ""
    echo "Repository Settings → Secrets and variables → Actions → New repository secret"
    echo ""
    echo "Secret Name: GCP_PROJECT_ID"
    echo "Secret Value: $PROJECT_ID"
    echo ""
    echo "Secret Name: GCP_SA_KEY"
    echo "Secret Value:"
    echo "$base64_key"
    echo ""
    echo "Secret Name: GCP_REGION"
    echo "Secret Value: us-central1"
    echo ""
    echo "Secret Name: CLOUD_RUN_SERVICE_NAME"
    echo "Secret Value: notes-api"
    echo ""
    
    print_warning "IMPORTANT: Delete the key file after setting up GitHub Secrets:"
    echo "rm $key_file"
    echo ""
}

# Function to verify setup
verify_setup() {
    print_status "Verifying setup..."
    
    # Check Artifact Registry repository
    if gcloud artifacts repositories describe notes-api-repo \
        --location=us-central1 \
        --project="$PROJECT_ID" &>/dev/null; then
        print_success "Artifact Registry repository found"
    else
        print_warning "Artifact Registry repository 'notes-api-repo' not found. Make sure Terraform is applied."
    fi
    
    # Check if notes-api service account exists (from Terraform)
    if gcloud iam service-accounts describe "notes-api-service@${PROJECT_ID}.iam.gserviceaccount.com" \
        --project="$PROJECT_ID" &>/dev/null; then
        print_success "Notes API service account found"
    else
        print_warning "Notes API service account not found. Make sure Terraform is applied."
    fi
    
    print_success "Setup verification completed"
}

# Main execution
main() {
    echo "GitHub Actions Setup for Cloud Run Deployment"
    echo "=============================================="
    echo ""
    
    check_prerequisites
    get_project_id
    enable_apis
    
    # Create service account with proper output handling
    print_status "Setting up service account..."
    
    local sa_name="github-actions-deploy"
    local sa_email="${sa_name}@${PROJECT_ID}.iam.gserviceaccount.com"
    
    print_status "Creating service account: $sa_name"
    
    # Check if service account already exists
    if gcloud iam service-accounts describe "$sa_email" --project="$PROJECT_ID" &>/dev/null; then
        print_warning "Service account $sa_email already exists"
    else
        gcloud iam service-accounts create "$sa_name" \
            --display-name="GitHub Actions Deployment" \
            --description="Service account for GitHub Actions to deploy to Cloud Run" \
            --project="$PROJECT_ID" \
            --quiet
        print_success "Service account created: $sa_email"
        
        # Wait for service account to be fully created
        print_status "Waiting for service account to be ready..."
        sleep 5
    fi
    
    print_status "Service account email: $sa_email"
    
    grant_permissions "$sa_email"
    create_service_account_key "$sa_email"
    verify_setup
    
    echo ""
    print_success "GitHub Actions setup completed successfully!"
    echo ""
    print_status "Next steps:"
    echo "1. Add the secrets to your GitHub repository"
    echo "2. Delete the local key file: rm github-actions-key.json"
    echo "3. Push code to main branch or create a PR to test the workflow"
    echo ""
    print_status "For detailed instructions, see GITHUB_ACTIONS_SETUP.md"
}

# Run main function
main "$@"