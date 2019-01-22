# IAM Kubernetes Handbook

This handbook is structured in three parts:

* [EKS cluster management](/docs/eks-cluster-management.md) - Managing cluster resources in AWS.
* [Kubernetes administration](/docs/kubernetes-administration.md) - Includes topics like user management and cluster addons.
* [CI/CD and manual deployments](/docs/cluster-ci.md) - Deploy a sample application through a CI/CD pipeline using AWS tools.
* [Local development](/docs/local-dev.md) - Suggestions for local development.
* [Runbooks and Troubleshooting](/docs/runbooks/) - Instructions for troubleshooting problems.

Use these resources to setup a cluster, administer it, troubleshoot the problems you find and extend it with addons like kube2iam and Calico.

## Notes

This is a work in progress and I am starting with Terraform's EKS getting started guide (linked below). I plan on slowly turning this into a Terraform module that we can use to start new EKS clusters.

https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html
