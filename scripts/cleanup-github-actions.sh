#!/bin/bash

# Cleanup Script for GitHub Actions Setup
# This script only cleans up the GitHub Actions service account and related resources
# It does NOT recreate anything - use the setup script separately after cleanup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Get project ID
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

# Clean up existing GitHub Actions service account (NOT the Terraform-managed one)
cleanup_service_account() {
    local sa_name="github-actions-deploy"
    local sa_email="${sa_name}@${PROJECT_ID}.iam.gserviceaccount.com"
    
    print_status "Cleaning up GitHub Actions service account resources..."
    print_warning "NOTE: This will only clean up the 'github-actions-deploy' service account."
    print_warning "The 'notes-api-service' service account created by Terraform will NOT be touched."
    echo ""
    
    if gcloud iam service-accounts describe "$sa_email" --project="$PROJECT_ID" &>/dev/null; then
        print_warning "Found existing GitHub Actions service account: $sa_email"
        
        # List and delete existing keys
        print_status "Cleaning up existing service account keys..."
        local keys
        keys=$(gcloud iam service-accounts keys list --iam-account="$sa_email" --project="$PROJECT_ID" --format="value(name)" --filter="keyType:USER_MANAGED" || true)
        
        if [ -n "$keys" ]; then
            while IFS= read -r key; do
                if [ -n "$key" ]; then
                    print_status "Deleting key: $key"
                    gcloud iam service-accounts keys delete "$key" --iam-account="$sa_email" --project="$PROJECT_ID" --quiet || true
                fi
            done <<< "$keys"
            print_success "Service account keys cleaned up"
        else
            print_status "No user-managed keys found"
        fi
        
        # Remove IAM policy bindings for GitHub Actions service account only
        print_status "Removing IAM policy bindings for GitHub Actions service account..."
        local roles=(
            "roles/cloudbuild.builds.editor"
            "roles/run.admin"
            "roles/artifactregistry.reader"
            "roles/iam.serviceAccountUser"
            "roles/storage.admin"
        )
        
        for role in "${roles[@]}"; do
            print_status "Removing role: $role from $sa_email"
            gcloud projects remove-iam-policy-binding "$PROJECT_ID" \
                --member="serviceAccount:${sa_email}" \
                --role="$role" \
                --quiet || true
        done
        print_success "IAM policy bindings cleaned up"
        
        # Delete the GitHub Actions service account (NOT the Terraform one)
        print_status "Deleting GitHub Actions service account..."
        gcloud iam service-accounts delete "$sa_email" --project="$PROJECT_ID" --quiet
        print_success "GitHub Actions service account deleted"
        
        # Wait a moment for propagation
        print_status "Waiting for deletion to propagate..."
        sleep 5
    else
        print_status "No existing GitHub Actions service account found - nothing to clean up"
    fi
    
    # Clean up any local key files
    if [ -f "github-actions-key.json" ]; then
        print_status "Removing local key file..."
        rm "github-actions-key.json"
        print_success "Local key file removed"
    fi
    
    # Verify Terraform service account is still intact
    local terraform_sa_email="notes-api-service@${PROJECT_ID}.iam.gserviceaccount.com"
    if gcloud iam service-accounts describe "$terraform_sa_email" --project="$PROJECT_ID" &>/dev/null; then
        print_success "Terraform-managed service account is intact: $terraform_sa_email"
    else
        print_warning "Terraform-managed service account not found. Make sure Terraform is applied."
    fi
}

# Main execution
main() {
    echo "GitHub Actions Cleanup Script"
    echo "============================="
    echo ""
    print_warning "This script will clean up GitHub Actions resources only."
    print_warning "It will NOT recreate anything."
    echo ""
    
    get_project_id
    cleanup_service_account
    
    echo ""
    print_success "Cleanup completed successfully!"
    echo ""
    print_status "Next steps:"
    echo "1. Run the setup script: ./scripts/setup-github-actions.sh"
    echo "2. Configure GitHub Secrets with the generated values"
    echo "3. Test the deployment workflow"
}

# Run main function
main "$@"