# Overview

Spinnaker is an open source, multi-cloud continuous delivery platform for
releasing software changes with high velocity and confidence.

If you would like to learn more about Spinnaker, please visit the
[Spinnaker website](https://spinnaker.io/).

## About Spinnaker for Google Cloud Platform

This solution installs a single instance of Spinnaker onto a GKE cluster in a
production-ready configuration. The installation follows recommended practices
for running Spinnaker on Google Cloud Platform, and is integrated with related
Google Cloud services, such as [Cloud Build](https://cloud.google.com/cloud-build/).

This solution also provides a simplified configuration experience, as well as a
management environment and workflow for ongoing administration of Spinnaker.

# Use this solution

Click this button to install and manage Spinnaker using the [Cloud
Shell](https://cloud.google.com/shell/)-based management console.

[![Install Spinnaker](https://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/spinnaker-for-gcp.git&cloudshell_working_dir=scripts/install&cloudshell_tutorial=provision-spinnaker.md&cloudshell_print=instructions.txt)

The article [Install and Manage Spinnaker on Google Cloud
Platform](https://cloud.google.com/docs/ci-cd/spinnaker/spinnaker-for-gcp)
has instructions for using this solution.

## Architecture

![Architecture diagram](resources/spinnaker-k8s-app-architecture.png)

Spinnaker comprises a number of individual
[microservices](https://www.spinnaker.io/reference/architecture/). These are
deployed in their own Kubernetes Pods, managed by Deployment objects, behind
Service objects.

### Management components

We provide the following two components to help you manage your Spinnaker instance:

[Halyard](https://www.spinnaker.io/reference/halyard/) is Spinnaker's
configuration service and consists of a CLI and a daemon. The CLI will be
installed in the management environment (based on Cloud Shell) included in
this solution. The daemon will be installed in a Pod managed by a StatefulSet
object.

[Spin](https://www.spinnaker.io/guides/spin/app/) is Spinnaker's CLI. It is also
available in the management environment.

### Network access to Spinnaker

As a safe default, the Spinnaker instance is not exposed to external traffic.
It's accessed via port fowarding, which can be set up with with a single
command from the management environment.

Alternatively, the management environment allows you to expose Spinnaker via
the [Identity-Aware Proxy](https://cloud.google.com/iap/), using a secure
domain.

