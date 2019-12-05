# Using Jenkins to install Spinnaker for GCP

You can use Jekins to install Spinnaker for GCP. The Jenkins agent executing the job must be installed on a Unix-like operating system. 

The following section assumes you have an existing Jenkins server. If not, consider one of the [Jenkins solutions on Google Cloud](https://cloud.google.com/jenkins/).

## Jenkins on GCP

If your Jenkins server is running on GCP, follow [best practices](https://cloud.google.com/compute/docs/access/create-enable-service-accounts-for-instances#best_practices) for managing its service account. Your Jenkins server must have full access to all Google Cloud APIs to successfully install Spinnaker for GCP. See the [Compute Engine documentation](https://cloud.google.com/compute/docs/access/create-enable-service-accounts-for-instances#changeserviceaccountandscopes) for guidance on how to modify an instance's Google Cloud API access scopes.

You can't use Jenkins to install Spinnaker for GCP with a shared VPC. For Shared VPC support, conduct the [setup in Cloud Shell](https://cloud.google.com/docs/ci-cd/spinnaker/spinnaker-for-gcp).

## Dependencies

There are several dependencies that must be available to the Jenkins server before it can be used to install Spinnaker for GCP.

### Google Cloud SDK

The Google Cloud SDK is required to provision GCP resources. Install a [versioned archive](https://cloud.google.com/sdk/docs/downloads-versioned-archives) to the Jenkins server.

### Git

Git is required for backing up and restoring the Spinnaker for GCP configuration. Install Git on the Jenkins server by running `sudo apt-get install git-all`

### `kubectl`

`kubectl` is required to manage the cluster Spinnaker for GCP will be installed on. Install `kubectl` on the Jenkins server by running `sudo apt-get install kubectl`

### jq

jq is required for processing JSON. Install jq to the Jenkins server by running `sudo apt-get install jq`

### AnsiColor Plugin

The [AnsiColor Jenkins Plugin](https://plugins.jenkins.io/ansicolor) is required for properly rendering stdout while installing Spinnaker for GCP. Once the plugin has been installed, enable `Color ANSI Console Output` in the build configuration and set the `ANSI color map` to `xterm`.

## Service account

The Jenkins server must be configured with a GCP service account with the following roles:

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

These roles can be enabled through the IAM UI or with [gcloud](https://cloud.google.com/sdk/gcloud/reference/projects/add-iam-policy-binding).

## Enable Cloud Resource Manager API

The Cloud Resource Manager API must be enabled for Jenkins to successfully retrieve IAM policies. Enable it for your project by visiting the below URL and substituting your project id.

https://console.developers.google.com/apis/api/cloudresourcemanager.googleapis.com/overview?project=[PROJECT_ID]

## Properties file

To get Jenkins to install Spinnaker for GCP, you need to generate a properties file and make it available to Jenkins:

1. Run [setup_properties.sh](../scripts/install/setup_properties.sh).
 
1. Make the resulting properties file available to the installation script as it executes the Jenkins job. In this example, the properties file has been uploaded to the Jenkins server using the [Credentials plug-in](https://wiki.jenkins.io/display/JENKINS/Credentials+Plugin). It is made accessible to the job by binding the file to the PROPERTIES variable. Alternatively, you can use a secrets-management solution (like [Hashicorp Vault](https://www.vaultproject.io/)) and configure Jenkins to read it from there.

### Configure the Jenkins job

Once the dependencies are fulfilled, follow these steps to configure a job to install Spinnaker for GCP. 

1. Create a `New Item` from the Jenkins menu and select a `Freestyle project`. 
1. From the configuration screen, enable `Color ANSI Console Output` and set the `ANSI color map` to `xterm`.
1. Under `Build Environment`, enable `Delete workspace before build starts`.
1. Add an `Execute Shell` build step.
1. Configure the build step to retrieve and execute the `setup.sh` script.

```shell
#!/usr/bin/env bash

set -e

git clone https://github.com/GoogleCloudPlatform/spinnaker-for-gcp.git
git config --global user.name "jenkins-user"
git config --global user.email "jenkins-user@example.com"

PARENT_DIR=$WORKSPACE PROPERTIES_FILE=$PROPERTIES CI=true $WORKSPACE/spinnaker-for-gcp/scripts/install/setup.sh
```

In the above example, the Git `user.name` and `user.email` must be configured before you run `setup.sh`. Git operations can also be managed using the [Jenkins Git plugin](https://plugins.jenkins.io/git).

`setup.sh` requires several variables to be passed in:

- `PARENT_DIR`: The absolute path for the Jenkins workspace. Jenkins makes this available via `$WORKSPACE`.
- `PROPERTIES_FILE`: This is the absolute path to your generated Spinnaker for GCP properties file.
- `CI`: This must be set to `true` when running `setup.sh` outside of Cloud Shell.

1. Execute the job to install Spinnaker for GCP. 

If you change the properties file, apply the change by re-running the job. 

Additional instructions for how to access or manage the deployed Spinnaker application are available [here](https://cloud.google.com/docs/ci-cd/spinnaker/spinnaker-for-gcp#access_spinnaker).
