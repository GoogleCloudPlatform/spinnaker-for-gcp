# Using Cloud Build to install Spinnaker for GCP

## A note about Shared VPC support

You can't use Cloud Build to install Spinnaker for GCP with a shared VPC. For Shared VPC support, conduct the [setup in Cloud Shell](https://cloud.google.com/docs/ci-cd/spinnaker/spinnaker-for-gcp).

## Service account

To install Spinnaker for GCP, you need to grant the [Cloud Build service account](https://console.cloud.google.com/cloud-build/settings) the following roles:

- Cloud Functions Developer - roles/cloudfunctions.developer
- Compute Network Viewer - roles/compute.networkViewer
- Kubernetes Engine Admin - roles/container.admin 
- Create Service Accounts - roles/iam.serviceAccountCreator
- Pub/Sub Editor - roles/pubsub.editor
- Cloud Memorystore Redis Admin - roles/redis.admin
- Service Usage Admin - roles/serviceusage.serviceUsageAdmin
- Source Repository Administrator - roles/source.admin
- Storage Admin - roles/storage.admin
- Project IAM Admin - roles/resourcemanager.projectIamAdmin
- Service Account User - roles/iam.serviceAccountUser

You can grant these roles using the IAM UI or with [gcloud](https://cloud.google.com/sdk/gcloud/reference/projects/add-iam-policy-binding).

## Enable Cloud Resource Manager API

For Cloud Build to successfully retrieve IAM policies, you must enable the Cloud Resource Manager API. Visit this URL, substituting your project id.

https://console.developers.google.com/apis/api/cloudresourcemanager.googleapis.com/overview?project=[PROJECT_ID]

## Properties file

To get Cloud Build to install Spinnaker for GCP, you need to generate a properties file:

 1. Run [setup_properties.sh](../scripts/install/setup_properties.sh).
 
 1. Copy that file to the directory containing the Cloud Build YAML, so the installation script can access it while executing the Cloud Build job.

## Submitting a Build

Cloud Builds can be triggered using [gcloud](https://cloud.google.com/cloud-build/docs/running-builds/start-build-manually), [build triggers](https://cloud.google.com/cloud-build/docs/running-builds/automate-builds), or [GitHub app triggers](https://cloud.google.com/cloud-build/docs/create-github-app-triggers). The solution in this repository installs Spinnaker for GCP using a gcloud-triggered build. Follow these steps to start a build:

1. Create a new directory. The contents of this directory will be submitted to Cloud Build.
2. Place the generated properties file into that directory.
3. Copy the [cloudbuild.yaml](cloudbuild.yaml) file into the directory and edit the `user.name` and `user.email` used in the Git configuration steps.

```yaml
  - name: gcr.io/cloud-builders/git
    args: ['config', '--global', 'user.name', '<example-user>']
  - name: gcr.io/cloud-builders/git
    args: ['config', '--global', 'user.email', '<example-user@example.com>']
```

4. Copy the [Dockerfile](Dockerfile) and [install.bash](install.bash) file into the directory.
5. Submit the build to Cloud Build: `gcloud builds submit --timeout "25m"  --config cloudbuild.yaml --project PROJECT_ID .`

Cloud Build will execute the job, installing Spinnaker for GCP. If you make any changes to the properties file, re-run the job. Additional instructions for how to access or manage the deployed Spinnaker application are available [here](https://cloud.google.com/docs/ci-cd/spinnaker/spinnaker-for-gcp#access_spinnaker).
