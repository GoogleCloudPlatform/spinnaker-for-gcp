# Install and run sample application and pipelines

## Introduction

Try out Spinnaker using the sample application provided with your Spinnaker instance. It comes with...

* A sample "hello world" Go application
* A Cloud Build trigger to build an image from source
* Sample Spinnaker pipelines to deploy the image and validate the application in a progression from staging environment to production

To proceed, make sure the Spinnaker instance is reachable with port-forwarding or is exposed publicly.

Select the project containing your Spinnaker instance, then click **Start**, below.

<walkthrough-project-billing-setup/>

## Create application and pipelines

Run this command to create the required resources:

```bash
~/cloudshell_open/spinnaker-for-gcp/samples/helloworldwebapp/create_app_and_pipelines.sh
```

### Resources created:

The source code is hosted in a repository in [Cloud Source Repository](https://source.cloud.google.com/{{project-id}}/spinnaker-for-gcp-helloworldwebapp)
in the same project as your Spinnaker cluster.

This repository contains a few other items:

* Kubernetes configs for the application

  These are used to deploy the application and validate the service.

* A [Cloud Build config](https://source.cloud.google.com/{{project-id}}/spinnaker-for-gcp-helloworldwebapp/+/master:cloudbuild.yaml)

  This builds the image and copies the Kubernetes configs to the Spinnaker GCS bucket.

* A [Cloud Build trigger](https://console.developers.google.com/cloud-build/triggers?project={{project-id}}) 

  This executes the Cloud Build config when any source code or manifest files are changed under
  src/** or config/** in the repository.

Cloud Build creates an [image](https://gcr.io/{{project-id}}/spinnaker-for-gcp-helloworldwebapp)
from source and tags that image with the short commit hash.

The script also creates two Kubernetes namespaces...
* **helloworldwebapp-staging**
* **helloworldwebapp-prod**

...and the **helloworldwebapp-service** service in each of those namespaces, in the [Spinnaker Kubernetes cluster](https://console.developers.google.com/kubernetes/discovery?project={{project-id}}).

These services expose the Go application for staging and prod environments.

This process creates two Spinnaker pipelines under the **helloworldwebapp** Spinnaker application:

* **Deploy to Staging**

  This triggers on a newly completed GCB build, and deploys the image to the
  **helloworldwebapp-staging** namespace. It then runs a validation job to check the health status of the service.

* **Deploy to Production**

  This starts on a successful **Deploy to Staging** run and Blue/Green deploys 
  the tested image to **helloworldwebapp-prod** namespace. It then runs the health validation job.
 
  On success, the old replicaset is scaled down after a 5 minute wait period.

  On failure, the old replicaset is re-enabled and the new replicaset is disabled. A Pub/Sub
  notification of the failure is sent via the preconfigured Pub/Sub publisher.

You can navigate to your Spinnaker UI to see these pipelines.

## Start a new build

To build and deploy an image, just change some [source code](https://source.cloud.google.com/{{project-id}}/spinnaker-for-gcp-helloworldwebapp/+/master:src/main.go)
or [manifest files](https://source.cloud.google.com/{{project-id}}/spinnaker-for-gcp-helloworldwebapp/+/master:config/) and push the change to the master branch. 

The repository is already cloned to your home directory. Make some changes to the source code...

```bash
cloudshell edit ~/{{project-id}}/spinnaker-for-gcp-helloworldwebapp/src/main.go
```

...and commit the changes:
```bash
cd ~/{{project-id}}/spinnaker-for-gcp-helloworldwebapp

git commit -am "Cool new features"
git push
```

The new commit triggers the chain of events...
1. Cloud Build builds the image.
2. The **Deploy to Staging** pipeline deploys the image to staging and validates it.
3. The **Deploy to Production** pipeline promotes the image to production and validates it.

Visit the Spinnaker UI to verify that the pipelines complete successfully.

After the pipelines finish, the [**helloworldwebapp-services**](https://console.developers.google.com/kubernetes/discovery?project={{project-id}})
hosting the Go application will now be up and healthy. Click on the **endpoints**
for each service to see a "Hello World" page!

### Clean-up

Run this command to delete all the resources created above:

```bash
~/cloudshell_open/spinnaker-for-gcp/samples/helloworldwebapp/cleanup_app_and_pipelines.sh && cd ~/cloudshell_open/spinnaker-for-gcp
```

### Return to Spinnaker console

Run this command to return to the management environment:

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/update_console.sh
```
