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

```sh
$ git clone https://github.com/mozilla-iam/eks-deployment.git
$ cd eks-deployment
```

Edit the `variables.tf` file to include your desired `cluster-name`:

```json
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

```json
# Shared state configuration

terraform {
  backend "s3" {
    bucket  = ""
    key     = "iam-eks-cluster/I_USE_CLUSTER_NAME_HERE/terraform.tfstate"
  }
}
```

After that, you can run your Terraform init, plan and apply from the root of the
repository:

```sh
$ terraform init
$ terraform plan
$ terraform apply
```

### Authenticating and adding worker nodes to cluster

Once complete, you will receive a config map to apply and a `kubeconfig` file
that you can use to interact with the cluster.

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

If you see the following error, you'll need to do some troubleshooting:

```
error: You must be logged in to the server (Unauthorized)
```

Next, you'll want to apply the config map so the worker nodes can join the
cluster. If you named the other file `config-map-aws-auth.yaml`, you can apply
it like this:

```sh
$ kubectl --kubeconfig=./kubeconfig apply -f config-map-aws-auth.yaml
```

After a successful write of that config map, you'll start to see nodes joining
your cluster:

```sh
$ kubectl --kubeconfig=./kubeconfig get nodes
NAME                                       STATUS    ROLES     AGE       VERSION
ip-10-0-0-90.us-west-2.compute.internal    Ready     <none>    1h        v1.10.3
ip-10-0-1-100.us-west-2.compute.internal   Ready     <none>    1h        v1.10.3
```

### Destroying a cluster

From the folder where you can the apply, you can run your destroy:

```sh
$ terraform destroy
```

You will be prompted to confirm that you want to remove all cluster resources.
