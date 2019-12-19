## Configure User Access (IAP)

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/grant_iap_access.sh
```

Alternatively, you can manually grant the `IAP-secured Web App User` role on the `spinnaker/spin-deck` resource to the user you'd like to grant access to [here](https://console.developers.google.com/security/iap?project={{project-id}}).

## Use Spinnaker

### Connect to Spinnaker

Connect to your Spinnaker installation [here](https://$DOMAIN_NAME).

### View Spinnaker Audit Log

View the who, what, when and where of your Spinnaker installation
[here](https://console.developers.google.com/logs/viewer?project={{project-id}}&resource=cloud_function&logName=projects%2F{{project-id}}%2Flogs%2F$CLOUD_FUNCTION_NAME&minLogLevel=200).

### View Spinnaker Container Logs

View the logging output of the individual components of your Spinnaker installation
[here](https://console.developers.google.com/logs/viewer?project={{project-id}}&resource=k8s_container%2Fcluster_name%2F$GKE_CLUSTER%2Fnamespace_name%2Fspinnaker).

### Install sample applications and pipelines

There are sample applications with example pipelines available to install and try out.
View and install the samples by running this command:

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/list_samples.sh
```

## Delete Spinnaker

### Generate a cleanup script

This command generates a script that deletes all the resources that were provisioned as part of your Spinnaker installation.

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/generate_deletion_script.sh
```
