# Bootstrap sample application and pipelines

This section bootstraps your Spinnaker project with a sample Go application, a Cloud Build trigger
to build an image from source, and sample Spinnaker pipelines to deploy the image and validate the 
application in a progression from staging environment to production. Run the following to create
the required resources.

```bash
~/spinnaker-for-gcp/sampleapp/create_sample_pipelines.sh
```

### Resources created:

The source code is hosted in a [Cloud Source Repository](https://source.cloud.google.com/{{project-id}}/spinnaker-marketplace-sampleapp)
in the same project. The repo also contains two other items:

* Kubernetes ReplicaSet, Service, and Job configs used to deploy the application and validate the service
* [Cloud Build config](https://source.cloud.google.com/{{project-id}}/spinnaker-marketplace-sampleapp/+/master:cloudbuild.yaml) 
to build the image to [Google Container Repository](https://gcr.io/{{project-id}}/spinnaker-marketplace-sampleapp/cloudbuild.yaml) 
and copy Kubernetes configs to the Spinnaker GCS bucket. It tags the new image with the short commit
SHA on master branch.

A [Cloud Build trigger](https://console.developers.google.com/cloud-build/triggers?project={{project-id}}) 
triggers on any changes to the src/* code in the CSR repo, and will execute the Cloud Build config.

A GCR image was built from the Cloud Build - [gcr.io/{{project-id}}/spinnaker-marketplace-sampleapp](https://gcr.io/{{project-id}}/spinnaker-marketplace-sampleapp)
and tagged with the short commit hash.

A **sampleapp-staging** and **sampleapp-prod** Kubernetes namespace and **sampleapp-service** services in each namespace
is created in the cluster hosting Spinnaker. These [Kubernetes services](https://console.developers.google.com/kubernetes/discovery?project={{project-id}}) 
will expose the Go application for staging and prod environments.

Spinnaker pipelines are created under the **sampleapp** Spinnaker application. Navigate to your
Spinnaker UI to find the created pipelines.
* **Deploy to Staging** triggers on a newly pushed GCR image, and Blue/Green deploys the image to the
**sampleapp-staging** namespace. It then runs a validation job to check the health status of the service. On
success, the old replicaset is deleted.
* **Deploy to Production** starts on a successful **Deploy to Staging** run and also Blue/Green deploys 
the tested image to **sampleapp-prod** namespace. It then runs the health validation job.

### Start a new build
To start a image build and deployment, simply make some changes to the [Go source code](https://source.cloud.google.com/{{project-id}}/spinnaker-marketplace-sampleapp/+/master:src/main.go)
and push the change to the master branch. This will trigger a Cloud Build to create a new image with the short commit hash tag.
The **Deploy to Staging** pipeline will start when the new image is pushed, and deploy to the staging namespace,
then start the production pipeline to deploy to prod.
