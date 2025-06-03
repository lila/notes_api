# GitHub Actions Setup Guide

This guide will help you configure GitHub Actions for automatic deployment to Cloud Run when merging to the main branch.

## Prerequisites

- [x] GitHub repository with admin access
- [x] Google Cloud Project with billing enabled
- [x] Terraform infrastructure deployed (from `terraform/` directory)
- [x] `gcloud` CLI installed and authenticated

## Step 1: Create Service Account for GitHub Actions

First, create a dedicated service account for GitHub Actions deployments:

```bash
# Set your project ID (replace with your actual project ID)
export PROJECT_ID="your-project-id-here"

# Create service account
gcloud iam service-accounts create github-actions-deploy \
    --display-name="GitHub Actions Deployment" \
    --description="Service account for GitHub Actions to deploy to Cloud Run" \
    --project=$PROJECT_ID

# Get the service account email
export SA_EMAIL="github-actions-deploy@${PROJECT_ID}.iam.gserviceaccount.com"
```

## Step 2: Grant Required Permissions

Grant the necessary IAM roles to the service account:

```bash
# Cloud Build Editor - to trigger builds
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/cloudbuild.builds.editor"

# Cloud Run Admin - to deploy services
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/run.admin"

# Artifact Registry Reader - to pull images
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/artifactregistry.reader"

# Service Account User - to run as service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/iam.serviceAccountUser"

# Storage Admin - for Cloud Build logs and artifacts
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/storage.admin"
```

## Step 3: Create and Download Service Account Key

```bash
# Create and download the service account key
gcloud iam service-accounts keys create github-actions-key.json \
    --iam-account=$SA_EMAIL \
    --project=$PROJECT_ID

# Display the base64 encoded key (you'll need this for GitHub Secrets)
base64 -i github-actions-key.json

# Store the output - you'll need it for the next step
```

⚠️ **Security Note**: Keep this key secure and delete the local file after setting up GitHub Secrets.

## Step 4: Configure GitHub Repository Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions, then add these secrets:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `GCP_PROJECT_ID` | `your-project-id` | Your Google Cloud Project ID |
| `GCP_SA_KEY` | `base64-encoded-key` | The base64 output from Step 3 |
| `GCP_REGION` | `us-central1` | Your deployment region |
| `CLOUD_RUN_SERVICE_NAME` | `notes-api` | Your Cloud Run service name |

### How to add secrets:

1. Navigate to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with the name and value from the table above

## Step 5: Enable Required APIs

Ensure these APIs are enabled in your Google Cloud Project:

```bash
# Enable required APIs
gcloud services enable cloudbuild.googleapis.com \
    artifactregistry.googleapis.com \
    run.googleapis.com \
    --project=$PROJECT_ID
```

## Step 6: Verify Terraform Infrastructure

Make sure your Terraform infrastructure includes these resources:

```bash
# Check if Artifact Registry repository exists
gcloud artifacts repositories list --project=$PROJECT_ID

# Check if the notes-api service account exists (from Terraform)
gcloud iam service-accounts list --project=$PROJECT_ID --filter="email:notes-api-service@*"

# Check if Firestore is set up
gcloud firestore databases list --project=$PROJECT_ID
```

## Step 7: Test the Workflow

### Option A: Push to Main Branch
```bash
# Make a small change and push to main
echo "# Test deployment" >> README.md
git add README.md
git commit -m "test: trigger deployment workflow"
git push origin main
```

### Option B: Create and Merge a Pull Request
1. Create a new branch: `git checkout -b test-deployment`
2. Make a small change and commit
3. Push the branch: `git push origin test-deployment`
4. Create a Pull Request on GitHub
5. Merge the Pull Request

## Step 8: Monitor the Deployment

1. Go to your repository → **Actions** tab
2. Click on the running workflow
3. Monitor the deployment progress
4. Check the deployment summary for the service URL

## Troubleshooting

### Common Issues and Solutions

#### 1. Authentication Errors
```
Error: google: could not find default credentials
```
**Solution**: Verify the `GCP_SA_KEY` secret is correctly base64 encoded.

#### 2. Permission Denied Errors
```
Error: Permission denied on resource project
```
**Solution**: Ensure all IAM roles from Step 2 are granted to the service account.

#### 3. Cloud Build Timeout
```
Error: Build timeout
```
**Solution**: The build is taking longer than expected. Check Cloud Build logs in the GCP Console.

#### 4. Health Check Failures
```
Health check failed with status: 500
```
**Solution**: Check Cloud Run logs:
```bash
gcloud logs read --service=notes-api --limit=50 --project=$PROJECT_ID
```

### Debugging Commands

```bash
# Check service account permissions
gcloud projects get-iam-policy $PROJECT_ID \
    --flatten="bindings[].members" \
    --format="table(bindings.role)" \
    --filter="bindings.members:github-actions-deploy@*"

# Check Cloud Run service status
gcloud run services describe notes-api \
    --region=us-central1 \
    --project=$PROJECT_ID

# View recent builds
gcloud builds list --limit=5 --project=$PROJECT_ID

# Check Artifact Registry images
gcloud artifacts docker images list \
    us-central1-docker.pkg.dev/$PROJECT_ID/notes-api-repo \
    --include-tags
```

## Security Best Practices

1. **Rotate Service Account Keys**: Regularly rotate the service account key
2. **Principle of Least Privilege**: Only grant necessary permissions
3. **Monitor Access**: Review Cloud Audit Logs for service account usage
4. **Use Workload Identity**: Consider upgrading to Workload Identity Federation for enhanced security

## Next Steps

After successful deployment:

1. **Set up monitoring**: Configure Cloud Monitoring alerts
2. **Add staging environment**: Create a staging deployment workflow
3. **Implement rollback**: Add manual rollback capabilities
4. **Add tests**: Include automated testing in the workflow

## Cleanup (if needed)

To remove the GitHub Actions setup:

```bash
# Delete service account
gcloud iam service-accounts delete $SA_EMAIL --project=$PROJECT_ID

# Remove local key file
rm github-actions-key.json
```

## Support

If you encounter issues:

1. Check the GitHub Actions logs
2. Review Cloud Build logs in GCP Console
3. Check Cloud Run service logs
4. Verify all secrets are correctly configured
5. Ensure all required APIs are enabled

For additional help, refer to:
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud Build Documentation](https://cloud.google.com/build/docs)