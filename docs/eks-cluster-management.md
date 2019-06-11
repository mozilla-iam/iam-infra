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
  - [EKS Workers](#toc-worker-upgrade)
  - [Prometheus Operator](#toc-prom-operator)

# <a id="toc-introduction"></a>Introduction

This document provides an overview of how Mozilla IAM manages Kubernetes cluster resources with the help of Amazon EKS. This overview leads into intructions that show you how to create and destroy a test cluster.

>Amazon Elastic Container Service for Kubernetes (Amazon EKS) is a managed service that makes it easy for you to run Kubernetes on AWS without needing to stand up or maintain your own Kubernetes control plane. Kubernetes is an open-source system for automating the deployment, scaling, and management of containerized applications.

This process diverges from Amazon's [cluster creation documentation](https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html). We are using Terraform to create all resources required to run a Kubernetes cluster in AWS with EKS.

# <a id="toc-overview"></a>Overview

## <a id="toc-terraform"></a>Terraform

The Terraform used to manage these cluster resources is found in [this repository](https://github.com/mozilla-iam/eks-deployment/terraform). This will create:

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
$ cd eks-deployment/terraform
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
This section provides insights on how to upgrade different services running in the cluster.
Before upgrading any component, you should read before its Changelog and make sure the upgrade will not break any functionality needed.

## <a id="toc-cluster-upgrade"></a>EKS cluster

The managed masters are simple to upgrade thanks for AWS. Documentation can be
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

We have at all times 2 Autoscaling groups per cluster: blue and green. Only one of this 2 ASGs is active
at a time, the other one has 0 running instances. The approach to upgrade the nodes is to modify the launch 
configuration of the inactive ASG with the new AMI, scale this to N+1 instances, drain the old nodes forcing 
pods to start in the new nodes and once all applications are running in the new nodes, scale down to 0 the old
active ASG.

We have wrote a script which takes care of scaling down the active ASG, scaling up the inactive ASG,
draining the nodes and deleting the remaining EC2 instances.
At this point you only have to deal with changing the AMI id in the Terraform code.

These are the steps you should follow to upgrade the worker nodes:
  1. Modify the Terraform code of the inactive ASG with the new AMI id. Edit this file for [staging](https://github.com/mozilla-iam/iam-infra/blob/master/terraform/stage/us-west-2/kubernetes/main.tf#L12)
  2. Run the [workers-rolling-deployment.sh](https://github.com/mozilla-iam/iam-infra/scripts/scripts/workers-rolling-deployment.sh) passing as an argument the name of the cluster.
  3. Once the script has finished, open again the Terraform file and switch the ASG `asg_desired_capacity`, `asg_max_size`, `asg_min_size` values from the old active ASG to the new active. We recommend reflecting the new AMI also in the second ASG.

## <a id="toc-prom-operator"></a>Prometheus-Operator
Prometheus Operator is taking care of choosing the right container image for Prometheus, so if you want to upgrade to a more recent version, first you have to check if it is supported by the operator, and upgrade this one.
Before start doing it, is important that you read the [Changelog](https://github.com/coreos/prometheus-operator/blob/master/CHANGELOG.md) and verify that there are not incompatible changes, or if they are, that you took care of those.

New versions can modify 2 very different things: the code of the prometheus-operator binary and/or the code of the CRDs.

If you want to upgrade to a new version, which is not modifying the CRDs you are lucky, it's strightforward! Modify the version of the operator [here](https://github.com/mozilla-iam/eks-deployment/blob/master/kubernetes/monitoring/10-prometheus-operator.yml#L103), apply the changes, and delete the prometheus-operator pod. Kubernetes will take care of starting it again using the new image.

If the upgrade modifies also the CRDs, you will have to replace them first: "kubectl replace -f 01-*". Once this is done, the prometheus-operator pod should start again hopefully without any errors. In case you face errors, better fixing them while the old version of Prometheus is running. Once you are done with it, you can delete the prometheus-master pod, and the operator will recreate it using the new image.
