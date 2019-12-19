## Use Spinnaker

### Forward the port to Deck, and connect

Don't use the `hal deploy connect` command. Instead, use the following command
only.

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/connect_unsecured.sh
```

To connect to the Deck UI, click on the Preview button above and select "Preview on port 8080":

![Image](https://github.com/GoogleCloudPlatform/spinnaker-for-gcp/raw/master/scripts/manage/preview_button.png)

### View Spinnaker Audit Log

View the who, what, when and where of your Spinnaker installation
[here](https://console.developers.google.com/logs/viewer?project={{project-id}}&resource=cloud_function&logName=projects%2F{{project-id}}%2Flogs%2F$CLOUD_FUNCTION_NAME&minLogLevel=200).

### View Spinnaker Container Logs

View the logging output of the individual components of your Spinnaker installation
[here](https://console.developers.google.com/logs/viewer?project={{project-id}}&resource=k8s_container%2Fcluster_name%2F$GKE_CLUSTER%2Fnamespace_name%2Fspinnaker).

### Expose Spinnaker

If you would like to connect to Spinnaker without relying on port forwarding, we can
expose it via a secure domain behind the [Identity-Aware Proxy](https://cloud.google.com/iap/).

Note that this phase could take 30-60 minutes. **Spinnaker will be inaccessible during this time.**

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/expose/configure_endpoint.sh
```

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
