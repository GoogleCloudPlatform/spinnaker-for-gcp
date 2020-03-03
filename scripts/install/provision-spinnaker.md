# Install Spinnaker

## Select GCP project

Select the project in which you'll install Spinnaker, then click **Start**, below.

<walkthrough-project-billing-setup>
</walkthrough-project-billing-setup>

## Spinnaker Installation

Click the **Copy to Cloud Shell** button for each command below, then press **Enter**
to run each commmand.

### Configure Git

If you haven't already configured Git, use the commands below to do so now.
Replace `[EMAIL_ADDRESS]` with your Git email address, and replace `[USERNAME]`
with your Git username.

```bash
git config --global user.email "[EMAIL_ADDRESS]"
git config --global user.name "[USERNAME]"
```

### Configure the environment

Now let's provision Spinnaker within your project {{project-id}}.

```bash
PROJECT_ID={{project-id}} ~/cloudshell_open/spinnaker-for-gcp/scripts/install/setup_properties.sh
```

After that script finishes, you can use the command below to open the properties file for your Spinnaker
installation. This is optional.

```bash
cloudshell edit ~/cloudshell_open/spinnaker-for-gcp/scripts/install/properties
```

**Proceed with caution**. If you edit this file, the installation might not work
as expected.

### Begin the installation

**This will take some time**

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/install/setup.sh
```

Watch the Cloud Shell command line to see when it completes, then click
**Next** to continue to the next step.

## Connect to Spinnaker

You'll now run commands to...
* connect to Spinnaker 
* open the Spinnaker UI (Deck) in a browser window

You have two choices:
* forward port 8080 to tunnel to Spinnaker from your Cloud Shell
* expose Deck securely via a public IP

### Forward the port to Deck, and connect

Don't use the `hal deploy connect` command. Instead, use the following command
only.

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/connect_unsecured.sh
```

To connect to the Deck UI, click on the Preview button above and select "Preview on port 8080":

![Image](https://github.com/GoogleCloudPlatform/spinnaker-for-gcp/raw/master/scripts/manage/preview_button.png)

### Expose Spinnaker publicly

If you would like to connect to Spinnaker without relying on port forwarding, we can
expose it via a secure domain behind the [Identity-Aware Proxy](https://cloud.google.com/iap/).

Note that this phase could take 30-60 minutes. **Spinnaker will be inaccessible during this time.**

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/expose/configure_endpoint.sh
```

## Next steps: manage Spinnaker

Now that you've installed Spinnaker on Google Kubernetes Engine, and
accessed it via port forwarding or made it available over the public
internet, you'll use this same console to manage your Spinnaker instance.

You can open this console by navigating to the Kubernetes Application on the
[Applications](https://console.developers.google.com/kubernetes/application?project={{project-id}})
view. The application's *Next Steps* section contains the relevant links and
operator instructions.

You can...

* Use [Halyard](https://www.spinnaker.io/reference/halyard/) to further
configure Spinnaker
* Add provider accounts
* Upgrade Spinnaker
* Add more operators

To start managing Spinnaker:

```bash
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/update_console.sh
```
