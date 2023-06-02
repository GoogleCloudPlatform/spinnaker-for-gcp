# Manage Spinnaker

Use this section to manage your Spinnaker deployment going forward.

## Select GCP project

Select the project in which your Spinnaker is installed, then click **Start**.

<walkthrough-project-billing-setup>
</walkthrough-project-billing-setup>

## Manage Spinnaker via Halyard from Cloud Shell

This management environment lets you run [Halyard
commands](https://www.spinnaker.io/reference/halyard/) to configure and manage
your Spinnaker installation.

### Ensure you are connected to the correct Kubernetes context

```bash
PROJECT_ID={{project-id}} ~/cloudshell_open/spinnaker-for-gcp/scripts/manage/check_cluster_config.sh
```

### Pull Spinnaker config

Paste and run this command to pull the configuration from your Spinnaker
deployment into your Cloud Shell.

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/pull_config.sh
```

### Update this console

**This is required if you've just pulled config from a different Spinnaker deployment.**

This command refreshes the contents of the right-hand pane, including details on how
to connect to Spinnaker.

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/update_console.sh
```

### Configure Spinnaker via Halyard

All [halyard](https://www.spinnaker.io/reference/halyard/commands/) commands are available.

```bash
hal config
```

As with provisioning Spinnaker, don't use `hal deploy connect` when managing
Spinnaker. Also, don't use `hal deploy apply`. Instead, use the `push_and_apply.sh`
command shown below.

### Notes on Halyard commands that reference local files

If you add a Kubernetes account that references a kubeconfig file, that file must live within
the '`~/.hal/default/credentials`' directory on your Cloud Shell VM. The
kubeconfig is specified using the `--kubeconfig-file` argument to the
`hal config provider kubernetes account add` and ...`edit` commands.

A similar requirement applies for any other local file referenced from your halyard config,
including Google JSON key files specified via the `--json-path` argument to various commands.
These files must live within '`~/.hal/default/credentials`' or '`~/.hal/default/profiles`'.

### Push and apply updated config to Spinnaker deployment

If you change any of the configuration, paste and run this command to push
and apply those changes to your Spinnaker deployment.

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/push_and_apply.sh
```

## Included command-line tools

### Halyard CLI

The [Halyard CLI](https://www.spinnaker.io/reference/halyard/) (`hal`) and
daemon are installed in your Cloud Shell.

If you want to use a specific version of Halyard, use:

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/cli/install_hal.sh --version 1.55.0
```

If you want to upgrade to the latest version of Halyard, use:

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/cli/update_hal.sh
```

### Spinnaker CLI

The [Spinnaker CLI](https://www.spinnaker.io/guides/spin/app/) 
(`spin`) is installed in your Cloud Shell.

If you want to upgrade to the latest version, use:

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/cli/install_spin.sh
```

## Scripts for Common Commands

Remember that any configuration changes you make locally (e.g. adding
accounts) must be pushed and applied to your deployment to take effect:

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/push_and_apply.sh
```

### Add Spinnaker account for GKE

This script grants the required
[IAM roles](https://cloud.google.com/kubernetes-engine/docs/how-to/iam) to the
Spinnaker instance's service account, in the GCP project containing the referenced
cluster.

Before you run this command, make sure you've configured the context you intend
to use to manage your GKE resources.

The public Spinnaker documentation contains details on [configuring GKE
clusters](https://www.spinnaker.io/setup/install/providers/kubernetes-v2/gke/).

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/add_gke_account.sh
```

### Add Spinnaker account for GCE

This script grants the required
[IAM roles](https://cloud.google.com/compute/docs/access/) to the Spinnaker
instance's service account, in the GCP project within which you wish to manage
GCE resources.

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/add_gce_account.sh
```

### Add Spinnaker account for GAE

This script grants the required
[IAM roles](https://cloud.google.com/appengine/docs/admin-api/access-control)
to the Spinnaker instance's service account, in the GCP project within which you
wish to manage GAE resources.

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/add_gae_account.sh
```

### Upgrade Spinnaker

First, modify `SPINNAKER_VERSION` in your `properties` file to reflect the desired version of Spinnaker:

```bash
cloudshell edit ~/cloudshell_open/spinnaker-for-gcp/scripts/install/properties
```

Next, use Halyard to apply the changes:

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/update_spinnaker_version.sh
```

### Upgrade Halyard daemon running in cluster

First, modify `HALYARD_VERSION` in your `properties` file to reflect the desired version of Halyard:

```bash
cloudshell edit ~/cloudshell_open/spinnaker-for-gcp/scripts/install/properties
```

Next, apply this change to the Statefulset managing the Halyard daemon:

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/update_halyard_daemon.sh
```

### Upgrade Management Environment

Update the commands and documentation in your management environment to the latest available version.

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/update_management_environment.sh
```

### Sign up for Spinnaker for GCP updates and announcements

Join the [mailing list](https://groups.google.com/forum/#!forum/spinnaker-for-gcp-announce) to keep informed about updates and other announcements.

### Connect to Redis

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/connect_to_redis.sh
```

### Restore a backup to Cloud Shell

Restore a backup of the halyard configuration and deployment configuration from Cloud Source Repositories to your Cloud Shell. 

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/restore_backup_to_cloud_shell.sh -p spinnaker-388416 -r spinnaker-config -h GIT_HASH
```

All backups can be viewed in this [Cloud Source Repository](https://source.cloud.google.com/spinnaker-388416/spinnaker-config).

## Configure Operator Access

To add additional operators, grant them the `Owner` role on GCP Project {{project-id}}: [IAM Permissions](https://console.developers.google.com/iam-admin/iam?project={{project-id}})

Once they have been added to the project, they can locate Spinnaker by navigating to the newly-registered [Kubernetes Application](https://console.developers.google.com/kubernetes/application/europe-west1-b/spinnaker/spinnaker/spinnaker?project={{project-id}}).

The application's *Next Steps* section contains the relevant links and operator instructions.

### If you have secured Spinnaker via IAP

Granting someone the `Owner` role does not implicitly grant them access as a user. For configuring user access, please continue on to the *Configure User Access (IAP)* section.

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
[here](https://console.developers.google.com/logs/viewer?project={{project-id}}&resource=cloud_function&logName=projects%2F{{project-id}}%2Flogs%2FspinnakerAuditLog&minLogLevel=200).

### View Spinnaker Container Logs

View the logging output of the individual components of your Spinnaker installation
[here](https://console.developers.google.com/logs/viewer?project={{project-id}}&resource=k8s_container%2Fcluster_name%2Fspinnaker%2Fnamespace_name%2Fspinnaker).

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
