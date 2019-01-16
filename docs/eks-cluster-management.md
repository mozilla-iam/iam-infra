# EKS cluster management

This document provides instructions for managing EKS cluster resources in AWS with Terraform.

See the [README](/README.md) for related documents.

# Table of Contents

- [Introduction](#toc-introduction)
- [Overview](#toc-overview)
  - [Terraform](#toc-terraform)
  - [Remote state](#toc-remote-state)
  - [EKS workers](#toc-workers)
- [Deploying your first EKS cluster](#toc-first-cluster)
  - [Requirements](#toc-requirements)
  - [Terraform options](#toc-terraform-options)
  - [Create resources](#toc-terraform-apply)
  - [Test cluster authentication](#toc-test-auth)
  - [Add workers](#toc-add-workers)
  - [Cleanup](#toc-cleanup)
- [Upgrades](#toc-upgrades)
  - [EKS cluster](#toc-cluster-upgrade)
  - [Workers](#toc-worker-upgrade)

# <a id="toc-introduction"></a>Introduction

This document provides an overview of how Mozilla IAM manages Kubernetes cluster resources with the help of Amazon EKS. This overview leads into intructions that show you how to create and destroy a test cluster.

>Amazon Elastic Container Service for Kubernetes (Amazon EKS) is a managed service that makes it easy for you to run Kubernetes on AWS without needing to stand up or maintain your own Kubernetes control plane. Kubernetes is an open-source system for automating the deployment, scaling, and management of containerized applications.

This process diverges from Amazon's [cluster creation documentation](https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html). We are using Terraform to create all resources required to run a Kubernetes cluster in AWS with EKS.

# <a id="toc-overview"></a>Overview

## <a id="toc-terraform"></a>Terraform

The Terraform used to manage these cluster resources is found at the root of [this repository](https://github.com/mozilla-iam/eks-deployment). This will create:

- IAM roles and policies
- VPC, subnets, security groups
- Workers based on the EKS optimized AMI
- An EKS cluster
- Launch configuration and an autoscaling group

This is a copy of the work that [Terraform shared](https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html). Minor changes have been made to namespace resources based on the provided cluster name. This allows you to use the same Terraform to create multiple clusters.

The future architecture of this Terraform is being discussed in [issue/3](https://github.com/mozilla-iam/eks-deployment/issues/3).

## <a id="toc-remote-state"></a>Remote state

The Terraform documentation describes this best:

>By default, Terraform stores state locally in a file named terraform.tfstate. When working with Terraform in a team, use of a local file makes Terraform usage complicated because each user must make sure they always have the latest state data before running Terraform and make sure that nobody else runs Terraform at the same time.
>
>With remote state, Terraform writes the state data to a remote data store, which can then be shared between all members of a team. Terraform supports storing state in Terraform Enterprise, HashiCorp Consul, Amazon S3, and more.

Source: [state/remote](https://www.terraform.io/docs/state/remote.html)

We are using remote state backed by S3. This is configured in `providers.tf`. Today, you must edit the [following lines](https://github.com/mozilla-iam/eks-deployment/blob/master/providers.tf#L21-L28) manually to set the proper region, S3 bucket and object key. This will be described in more depth in the [Terraform options](#toc-terraform-options) section below.

## <a id="toc-workers"></a>EKS workers

Our Terraform will automatically create worker nodes for our Kubernetes cluster. These nodes will be used to run our cluster workload. Before they can be used, the `aws-auth` ConfigMap will need to be applied to the cluster with `kubectl`. This will be explained in more depth in the [add workers](#toc-add-workers) section when you use the steps below to setup a test cluster.

# <a id="toc-first-cluster"></a>Deploying your first EKS cluster

## <a id="toc-requirements"></a>Requirements

In order to complete this deployment, you must have `kubectl` version >= 1.10 and the `heptio-authenticator-aws` binary installed and available in your `PATH`. AWS provides these instructions and links to download both binaries for Linux, MacOS and Windows: [Configure kubectl](https://docs.aws.amazon.com/eks/latest/userguide/configure-kubectl.html).

## <a id="toc-terraform-options"></a>Terraform options

As mentioned above, this Terraform source has minor changes from what the Terraform team has [shared with the community](https://github.com/terraform-providers/terraform-provider-aws/tree/master/examples/eks-getting-started).
I have modified some of the resource names to include the cluster name specified
in `variables.tf`. This would allow you to apply the Terraform multiple times to
deploy multiple clusters, as long as you change the cluster name.

To begin, clone the source repository:

```sh
$ git clone https://github.com/mozilla-iam/eks-deployment.git
$ cd eks-deployment
```

Edit the `variables.tf` file to include your desired `cluster-name`:

```hcl
#
# Variables Configuration
#

variable "cluster-name" {
  default = "eks-development"
  type    = "string"
}
```

Edit the `providers.tf` file to include the S3 bucket for shared state and a
key name for the state file. You must update the key name so you are not
overwriting a shared state file for another cluster.

```hcl
# Shared state configuration

terraform {
  backend "s3" {
    bucket  = ""
    key     = "iam-eks-cluster/USE_CLUSTER_NAME_HERE/terraform.tfstate"
  }
}
```

## <a id="toc-terraform-apply"></a>Create resources

With the prerequisites addressed, you can run your Terraform `init`, `plan` and `apply` from the root of the repository:

```sh
$ terraform init
$ terraform plan
$ terraform apply
```

## <a id="toc-test-auth"></a>Test cluster authentication

When Terraform is done applying resources, you will receive a config map to apply and a `kubeconfig` file that you can use to interact with the cluster.

If you no longer have the history from the `terraform apply` output, you can get
these file contents by running `terraform output`:

```sh
$ terraform output
config-map-aws-auth =

apiVersion: v1
kind: ConfigMap
...
```

Write out each output to a file so you can use them. For `kubectl`, you can set
the `KUBECONFIG` environment variable to point to the `kubeconfig` file you
created. Alternatively, you can pass in the path when you run `kubectl`:

```sh
$ kubectl --kubeconfig=./kubeconfig cluster-info
Kubernetes master is running at https://UNIQUE-NAME.yl4.us-west-2.eks.amazonaws.com

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

## <a id="#toc-add-workers"></a>Add workers

To connect workers, apply the config map so the worker nodes can join the cluster. If you named the other file `config-map-aws-auth.yaml`, you can apply
it like this:

```sh
$ kubectl --kubeconfig=./kubeconfig apply -f config-map-aws-auth.yaml
```

After a successful write of that config map, you'll start to see nodes joining
your cluster. Note: this can take a moment and you may want to run the command several times or append the `--watch` flag.

```sh
$ kubectl --kubeconfig=./kubeconfig get nodes
NAME                                       STATUS    ROLES     AGE       VERSION
ip-10-0-0-90.us-west-2.compute.internal    Ready     <none>    1h        v1.10.3
ip-10-0-1-100.us-west-2.compute.internal   Ready     <none>    1h        v1.10.3
```

## <a id="toc-cleanup"></a>Cleanup

From the folder where you can the apply, you can run your destroy:

```sh
$ terraform destroy
```

You will be prompted to confirm that you want to remove all cluster resources.

# <a id="toc-upgrades"></a>Upgrades

This is a work in progress. I have gone through the cluster and worker upgrade
process one time and this provides some documentation for that along with a
number of issues that should be addressed in the future.

## <a id="toc-cluster-upgrade"></a>EKS cluster

The managed workers are simple to upgrade thanks for AWS. Documentation can be
found
[here](https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html). At
the bottom of the page there should be a link for "Worker Node Updates". That
documentation should apply to the AWS recommended setup which uses
CloudFormation. Our process is different with Terraform. Continue to the next
section for details.

## <a id="toc-worker-upgrade"></a>Workers

There are two important pieces of information that you should have:

- We use the
[EKS
module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/1.0.0)
from the Terraform team.
- We take [Wylie's
  approach](https://thinklumo.com/blue-green-node-deployment-kubernetes-eks-terraform/)
to worker node deployments with EKS and Terraform (Thank you, Wylie)

These are the steps you should follow to upgrade the worker nodes:

1. To begin, open
[main.tf](https://github.com/mozilla-iam/eks-deployment/blob/development/infrastructure/infra-dev/prod/us-west-2/kubernetes/main.tf#L9)
and identify the unused worker group. You will see two in the list of worker
groups. The unused one will have the ASG desired, min and max instances set to
0
2. For the new worker group, make any necessary changes (AMI ID, root volume
size, etc.) and set the ASG desired, min and max instances to match the active
worker group
3. Run `terraform apply`
4. Use `kubectl get nodes` and wait for all new workers to join. The total
number will depend on the ASG capacity as well as whether or not the cluster
autoscaler has added new nodes. Once all new nodes are in a ready state, you can
begin draining the old nodes
5. Sort the nodes by the date created: `kubectl get no
--sort-by=.metadata.creationTimestamp`
6. Drain one node and use `kubectl describe node <node name>` to make sure the
pods have moved to another node successfully. Capture the name from the first
column in the output from the previous command use drain the node with `kubectl
drain node <name> --ignore-daemonsets=true --delete-local-data`
7. Once this is done, you can drain all of the old nodes. After that, all the
pods should be running on the new nodes

This is where I ran into an issue. The documentation in the EKS Terraform module
says that you should add the following to your worker group configuration if you
are going to use the cluster autoscaler: `protect_from_scale_in = true`. This is
consistent with what I have read in other places. This prevents the autoscaling
group from terminating nodes.

Terraform will return an error after it times out waiting to terminate the
instances. I did this, ran the `terraform apply` again and then manually
terminated those older instances in the AWS console.

