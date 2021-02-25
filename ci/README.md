# Installing Spinnaker for GCP on a Continous Integration Server

You can install Spinnaker for GCP using a continous integration Server. A CI server can be used to conduct the initial installation and to apply updates when the Spinnaker for GCP properties file changes. Solutions for [Google Cloud Build](CLOUD_BUILD.md) and [Jenkins](JENKINS.md) are available.

---

# Added by Zebra Technologies.

Resources created in GCP (spinnaker-NN):
- Cluster
- IAM -> Service Account
- GS bucket
- Using existing pubsub topic projects/spg-zpc-sb/topics/gcr for GCR...
  - 13:13:38  .  Using existing pubsub subscription spinnaker-38-gcr-pubsub-subscription for GCR...
  - 13:13:39  .  Using existing pubsub topic projects/spg-zpc-sb/topics/cloud-builds for GCB...
  - 13:13:39  .  Using existing pubsub subscription spinnaker-38-gcb-pubsub-subscription for GCB...
  - 13:13:40  .  Using existing pubsub topic projects/spg-zpc-sb/topics/spinnaker-38-notifications-topic for notifications
- Memory store -> Redis
- Cloud Functions
- External IP
- Firewall
- Redis-peer?
- Compute Engine - VM Instance - gke-spinnaker-1-default-pool-ff098969-????
- Compute Engine - VM Instance template - gke-spinnaker-1-default-pool-ff098969
- Compute Engine - Disks 
- Compute Engine - Instance Groups - gke-spinnaker-1-default-pool-ff098969-grp
- Network Services - Load balancing - k8s-um-spinnaker-deck-ingress--d907b260247310ee
- Cloud Build for the spinnaker example pipeline - spinnaker-for-gcp-helloworldwebapp
- Endpoints - spinnaker-1.endpoints.spg-zpc-sb.cloud.goog
  - don't know how to get rid of this
- Cloud Source repositories - spinnaker-1-config - hal backup here

# Notes to be deleted
The script is creating a new SA everytime

1*
    2  git config --global user.email     "jerberg424@gmail.com"
    3  git config --global user.name     "jerberg424"
    4  PROJECT_ID=spg-zpc-sb     ~/cloudshell_open/spinnaker-for-gcp/scripts
    5  PROJECT_ID=spg-zpc-sb     ~/cloudshell_open/spinnaker-for-gcp/script
    6  PROJECT_ID=spg-zpc-sb ~/cloudshell_open/spinnaker-for-gcp/scripts/install/setup_properties.sh
    7  cloudshell edit ~/cloudshell_open/spinnaker-for-gcp/scripts/install/properties
    8  ~/cloudshell_open/spinnaker-for-gcp/scripts/install/setup.sh
    9  cloudshell launch-tutorial ~/cloudshell_open/spinnaker-for-gcp/scripts/install/provision-spinnaker.md
   10  ~/cloudshell_open/spinnaker-for-gcp/scripts/install/setup.sh
   11  echo $GOOGLE_APPLICATION_CREDENTIALS
   12  gcloud config list account --format "value(core.account)" --project spg-zpc-sb
   13  ~/cloudshell_open/spinnaker-for-gcp/scripts/install/setup.sh
   14  ~/cloudshell_open/spinnaker-for-gcp/scripts/expose/configure_endpoint.sh
   15  cloudshell launch-tutorial ~/cloudshell_open/spinnaker-for-gcp/scripts/install/provision-spinnaker.md
   16  ~/cloudshell_open/spinnaker-for-gcp/scripts/manage/update_console.sh
   17  cloudshell launch-tutorial ~/cloudshell_open/spinnaker-for-gcp/scripts/install/provision-spinnaker.md
   18  kubectl
   19  gcloud compute addresses
   20  gcloud compute address
   21  gcloud compute addresses list
   22  gcloud compute addresses
   23  gcloud compute addresses describe spinnaker-1-external-ip
   24  cd ..
   25  ls
   26  cloudshell launch-tutorial expose/configure_iap_expanded.md
   27  ~/cloudshell_open/spinnaker-for-gcp/scripts/expose/configure_iap.sh
   28  cloudshell_open --repo_url "https://github.com/GoogleCloudPlatform/spinnaker-for-gcp.git" --print_file "instructions.txt" --dir "scripts/install" --page "editor" --tutoria
l "provision-spinnaker.md"
   29  cloudshell edit ~/cloudshell_open/spinnaker-for-gcp/scripts/install/properties

## actions on Feb 18th
- deleted pub/sub spinnaker 1

# NOTES starting Feb 22
got done tonight with a successful spinnaker deploy but I ran it again for idempotency and it got hung on:
- 21:36:33  configmap/halconfig configured
- 21:36:33  job.batch/hal-deploy-apply created
- 21:36:34  .  completed kubectl apply...waiting for kubectl to complete 

After working through what was happening I found that the 
- completed kubectl apply...waiting for kubectl to complete

Trying to get to the halyard node logs to find out what's going on.  The first time through the kubectl apply completed but the second time through it hung or failed badly here
envsubst < $PARENT_DIR/scripts/install/quick-install.yml | kubectl apply -f -

``` text
jeremy_berg@cloudshell:~ (spg-zpc-tools)$ kubectl get all -n halyard
NAME                 READY   STATUS    RESTARTS   AGE
pod/spin-halyard-0   1/1     Running   0          63m
NAME                   TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
service/spin-halyard   ClusterIP   10.56.5.67   <none>        8064/TCP   63m
NAME                            READY   AGE
statefulset.apps/spin-halyard   1/1     63m
NAME                         COMPLETIONS   DURATION   AGE
job.batch/hal-deploy-apply   0/1           49m        49m
jeremy_berg@cloudshell:~ (spg-zpc-tools)$ kubectl logs pod/spin-halyard-0
Error from server (NotFound): pods "spin-halyard-0" not found
jeremy_berg@cloudshell:~ (spg-zpc-tools)$
```
Looks like it could be something in the CLOUD_FUNCTION_NAME but doubtful, something happened with the hal deploy apply.  Need to look at logs on the hal node

Should fail the same way which means I should run it again with all the variables printed out, think interpolation may be a problem

Failure found, how did this pass the first time but fail the second
com.netflix.spinnaker.halyard.core.error.v1.HalException: You must pick a version of Spinnaker to deploy.

## Feb 25
This don't do much good

https://jenkins.zpc-build.zebra.com/view/all/job/deployspinnakerp/67/console

21:25:46  .  Removing halyard/spin-halyard-0:/home/spinnaker/.hal... 
21:25:46  .  Copying /home/jenkins/agent/workspace/deployspinnakerp/.hal into halyard/spin-halyard-0:/home/spinnaker/.hal... 