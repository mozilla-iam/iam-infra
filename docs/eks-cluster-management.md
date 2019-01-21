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

The Terraform used to manage these cluster resources is found in [this repository](https://github.com/mozilla-iam/eks-deployment/infrastructure/infra-dev). This will create:

The Terraform is roughly organized like this:

```
.
├── global
│   └── codebuild
│       ├── auth0-deploy
│       └── sso-dashboard
├── prod
│   └── us-west-2
│       ├── Makefile
│       ├── kubernetes
│       ├── services
│       └── vpc
└── stage
    └── us-west-2
        ├── Makefile
        ├── kubernetes
        ├── services
        └── vpc
```

The `services` folder will contain additional folders for AWS services that our deployed sites will rely on. This includes things like RDS and Elasticsearch.

Kubernetes and the VPC used the following modules:

- https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/2.1.0
- https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/1.53.0

These provide a simple interface to manage those resources.

## <a id="toc-remote-state"></a>Remote state

The Terraform documentation describes this best:

>By default, Terraform stores state locally in a file named terraform.tfstate. When working with Terraform in a team, use of a local file makes Terraform usage complicated because each user must make sure they always have the latest state data before running Terraform and make sure that nobody else runs Terraform at the same time.
>
>With remote state, Terraform writes the state data to a remote data store, which can then be shared between all members of a team. Terraform supports storing state in Terraform Enterprise, HashiCorp Consul, Amazon S3, and more.

Source: [state/remote](https://www.terraform.io/docs/state/remote.html)

We are using remote state backed by S3. This is configured in the `providers.tf` file found in each Terraform folder.

## <a id="toc-workers"></a>EKS workers

Our Terraform will automatically create worker nodes for our Kubernetes cluster. These nodes will be used to run our cluster workload. Before they can be used, the `aws-auth` ConfigMap will need to be applied to the cluster with `kubectl`. This will be explained in more depth in the [add workers](#toc-add-workers) section when you use the steps below to setup a test cluster.

# <a id="toc-first-cluster"></a>Deploying your first EKS cluster

## <a id="toc-requirements"></a>Requirements

In order to complete this deployment, you must have `kubectl` version >= 1.10 and the `heptio-authenticator-aws` binary installed and available in your `PATH`. AWS provides these instructions and links to download both binaries for Linux, MacOS and Windows: [Configure kubectl](https://docs.aws.amazon.com/eks/latest/userguide/configure-kubectl.html).

## <a id="toc-terraform-options"></a>Terraform options

To begin, clone the source repository:

```sh
$ git clone https://github.com/mozilla-iam/eks-deployment.git
$ cd eks-deployment/infrastructure/infra-dev
```

If the production cluster has not been deployed, you should change into the `prod/us-west-2/vpc` folder. The Terraform is flexible and you can add new regions or environments by copying the existing folders. If you do this, you must search through the Terraform to make sure you have not duplicated the environment name or things like the Terraform state file location. Just be cautious and try to avoid naming conflicts.

Be sure to read the documentation for the VPC module. You can make any changes in `main.tf` if you would like.

## <a id="toc-terraform-apply"></a>Create resources

With the prerequisites addressed, you can run your Terraform `init`, `plan` and `apply` from the root of the VPC repository:

```sh
$ terraform init
$ terraform plan
$ terraform apply
```

I have had issues with Terraform when MFA is enforced on the AWS authentication. I use `aws-vault` to help deal with this. I have added my account to the tool and then I run the following command: `aws-vault exec mozilla-iam --assume-role-ttl 60m`. This provides me with a shell where Terraform has the right access to the account.

With the network created, you can use Terraform to create the Kubernetes cluster next. You will want to change into your Kubernetes folder, make any changes to `main.tf` that you would like and make sure that `data.tf` points to the right VPC state file. Just like the VPC, you can run the Terraform init, plan and apply to create the cluster.

## <a id="toc-test-auth"></a>Test cluster authentication

When Terraform is done applying resources, you can use the `aws` CLI tool to configure `kubectl`. Use `aws eks update-kubeconfig --name $CLUSTER_NAME`. Cluster name is defined in the Kubernetes `main.tf` file as `kubernetes-${var.environment}-${var.region}`.

With that complete, you should be able to use this context and interact with the cluster with `kubectl`.

## <a id="#toc-add-workers"></a>Add workers

Terraform will output a config map which can be used to make sure that the workers are able to join the cluster. The Terraform module should automatically apply this config map but, if it fails, you can do it manually from the Kubernetes directory. If running `kubectl get nodes` returns an empty list, this may be necessary.

```sh
$ kubectl apply -f config-map-aws-auth.yaml
```

After a successful write of that config map, you'll start to see nodes joining
your cluster. Note: this can take a moment and you may want to run the command several times or append the `--watch` flag.

```sh
$ kubectl get nodes
NAME                                       STATUS    ROLES     AGE       VERSION
ip-10-0-0-90.us-west-2.compute.internal    Ready     <none>    1h        v1.10.3
ip-10-0-1-100.us-west-2.compute.internal   Ready     <none>    1h        v1.10.3
```

## <a id="toc-cleanup"></a>Cleanup

If you want to destroy the cluster, you can do so from the folder where you ran the apply:

```sh
$ terraform destroy
```

You will be prompted to confirm that you want to remove all cluster resources. Repeat the same action for the VPC if that is no longer needed as well.

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

