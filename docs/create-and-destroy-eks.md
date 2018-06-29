# Create and destroy EKS

## Summary

This document provides instructions for creating and destroying an EKS cluster
in AWS with Terraform.

## Instructions

Today, this Terraform source has minor changes from what the Terraform team has
[shared with the
community](https://github.com/terraform-providers/terraform-provider-aws/tree/master/examples/eks-getting-started).
I have modified some of the resource names to include the cluster name specified
in `variables.tf`. This would allow you to apply the Terraform multiple times to
deploy multiple clusters, as long as you change the cluster name.

### Creating a new cluster

```
$ git clone https://github.com/mozilla-iam/eks-deployment.git
$ cd eks-deployment
```

Edit the `variables.tf` file to include your desired `cluster-name`:

```
#
# Variables Configuration
#

variable "cluster-name" {
  default = "eks-development"
  type    = "string"
}
```

Edit the `providers.tf` file to include the S3 bucket for shared state and a
key name for the state file.:

```
# Shared state configuration

terraform {
  backend "s3" {
    bucket  = ""
    key     = "iam-eks-cluster/development/terraform.tfstate"
  }
}
```

After that, you can run your Terraform init, plan and apply from the root of the
repository:

```
$ terraform init
$ terraform plan
$ terraform apply
```

Once complete, you will receive a config map to apply and a `kubeconfig` file
that you can use to interact with the cluster.

### Destroying a cluster

From the folder where you can the apply, you can run your destroy:

```
$ terraform destroy
```

You will be prompted to confirm that you want to remove all cluster resources.
