# Manage Spinnaker

Use this section to manage your Spinnaker deployment going forward.

## Select GCP project

Select the project in which your Spinnaker is installed, then click **Start**.

<walkthrough-project-billing-setup>
</walkthrough-project-billing-setup>

## Manage Spinnaker via Halyard from Cloud Shell

### Ensure command-line tools are installed

You can skip this step if you are the original installer/operator, as they will have already been installed.

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/cli/install_hal.sh && ~/cloudshell_open/spinnaker-for-gcp/scripts/cli/install_spin.sh && source ~/.bashrc
```

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