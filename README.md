# iam-infra
This repository contains all the code and resources needed for creating the infrastructure used in the IAM project, or more precisely for DinoPark.

## Repository structure
The repository is structured in top-level folders containing the different kind of resources needed to create AWS resources (terraform folder), configuring the different Kubernetes cluster (kubernetes folder), documentation, scripts which automate common operations and dockerfiles specific to the IAM project.

The Terraform code and Kubernetes manifests are organized by folders representing the different environments as observed by the infrastructure, and inisde there are organized by the AWS region where reside. This layout clearly has the disadvantage of repeating code, but has the advantage of knowing exactly what is deployed  and where just looking at the folders. In this way you don't have to look at templates and render values in your head but just go and look at the code. While this has helped us during the beginning, once we reach a more mature state we might decide to use Helm for templating Kubernetes manifests or modify Terraform resources to create modules..

### Terraform code
The Terraform code, as stated above is divided in folder representing environments and location. Also the resources needed for both environments staging and production will go to the global folder, like for example a policy allowing other AWS account to fetch metrics.
Inside of each environment and location the code is organized in independent modules. This means that each of the components are maintaining its own state file rather than sharing one for all the resources. This design has mostly 2 implications that can be considered an advantage or a disadvantage. The first one is that you can issue `terraform delete` only affecting the resource that you want, think for example if we stop using Graylog, issuing a `terraform destroy` on the Graylog folder will delete the ES cluster and DNS name but leave the rest of the infrastructure as it is. The second implication is that in order to share the state we use `remote_state` pointing to the state file used by the resource for example most of the services need to know the VPC id and are adding it as a remote state.


### Kubernetes code
The Kubernetes manifests present on this repository are organized in a similar fashion to the Terraform ones. Inside the Kubernetes folder we can find 2 more folder each one corresponding to one of the clusters: one for production and one for staging.
Here there is all the infrastructure resources, the manifests containing application specific resources like namespaces and deployments are living in each application repository.


## Documentation
Documentation about differen topics like managing users in EKS, deploying applications into the cluster, troubleshooting problems and monitoring applications can be found in different files inside the docs folder. These different files are intended for developers and administrators.

Here is a table of content with the different topics:

- 1 [EKS cluster management](/docs/eks-cluster-management.md)
  - 1.1 [Introduction](https://github.com/mozilla-iam/iam-infra/blob/master/docs/eks-cluster-management.md#introduction)
  - 1.2 [Overview](https://github.com/mozilla-iam/iam-infra/blob/master/docs/eks-cluster-management.md#overview)
    - 1.2.1 [Terraform](https://github.com/mozilla-iam/iam-infra/blob/master/docs/eks-cluster-management.md#terraform)
    - 1.2.2 [Remote state](https://github.com/mozilla-iam/iam-infra/blob/master/docs/eks-cluster-management.md#remote-state)
    - 1.2.3 [EKS workers](https://github.com/mozilla-iam/iam-infra/blob/master/docs/eks-cluster-management.md#eks-workers)
  - 1.3 [Deploy your first EKS cluster](https://github.com/mozilla-iam/iam-infra/blob/master/docs/eks-cluster-management.md#deploying-your-first-eks-cluster)
    - 1.3.1 [Requirements](https://github.com/mozilla-iam/iam-infra/blob/master/docs/eks-cluster-management.md#requirements)
    - 1.3.2 [Terraform options](https://github.com/mozilla-iam/iam-infra/blob/master/docs/eks-cluster-management.md#terraform-options)
    - 1.3.3 [Create resources](https://github.com/mozilla-iam/iam-infra/blob/master/docs/eks-cluster-management.md#create-resources)
    - 1.3.4 [Test cluster authentication](https://github.com/mozilla-iam/iam-infra/blob/master/docs/eks-cluster-management.md#test-cluster-authentication)
    - 1.3.5 [Add workers](https://github.com/mozilla-iam/iam-infra/blob/master/docs/eks-cluster-management.md#test-cluster-authentication)
    - 1.3.6 [Cleanup](https://github.com/mozilla-iam/iam-infra/blob/master/docs/eks-cluster-management.md#cleanup)
  - 1.4 [Upgrades](https://github.com/mozilla-iam/iam-infra/blob/master/docs/eks-cluster-management.md#upgrades)
    - 1.4.1 [EKS cluster](https://github.com/mozilla-iam/iam-infra/blob/master/docs/eks-cluster-management.md#eks-cluster)
    - 1.4.2 [EKS Workers](https://github.com/mozilla-iam/iam-infra/blob/master/docs/eks-cluster-management.md#workers)
    - 1.4.3 [Prometheus operator](https://github.com/mozilla-iam/iam-infra/blob/master/docs/eks-cluster-management.md#upgrade-prom-operator)
- 2 [Kubernetes administration](/docs/kubernetes-administration.md)
  - 2.1 [Introduction](https://github.com/mozilla-iam/iam-infra/blob/master/docs/kubernetes-administration.md#introduction)
  - 2.2 [User management](https://github.com/mozilla-iam/iam-infra/blob/master/docs/kubernetes-administration.md#user-management)
    - 2.2.1 [Allow Codebuild to deploy](https://github.com/mozilla-iam/iam-infra/blob/master/docs/kubernetes-administration.md#allow-codebuild-to-deploy)
    - 2.2.2 [Add a new user](https://github.com/mozilla-iam/iam-infra/blob/master/docs/kubernetes-administration.md#configure-iam)
  - 2.3 [Kube2IAM](https://github.com/mozilla-iam/iam-infra/blob/master/docs/kubernetes-administration.md#kube2iam-setup)
- 3 [Deploying applications to the cluster](/docs/cluster-ci.md)
  - 3.1 [Introduction](https://github.com/mozilla-iam/iam-infra/blob/master/docs/cluster-ci.md#introduction)
  - 3.2 [Overview](https://github.com/mozilla-iam/iam-infra/blob/master/docs/cluster-ci.md#overview)
  - 3.3 [CI/CD Pipeline using Terraform](https://github.com/mozilla-iam/iam-infra/blob/master/docs/cluster-ci.md#creating-a-deployment-pipeline-using-terraform-preferred)
    - 3.3.1 [Create the Pipeline](https://github.com/mozilla-iam/iam-infra/blob/master/docs/cluster-ci.md#create-the-pipeline)
    - 3.3.2 [The build stage](https://github.com/mozilla-iam/iam-infra/blob/master/docs/cluster-ci.md#the-build-stage)
    - 3.3.3 [The deployment stage](https://github.com/mozilla-iam/iam-infra/blob/master/docs/cluster-ci.md#-the-deployment-stage)
  - 3.4 [CI/CD Pipeline using AWS Console](https://github.com/mozilla-iam/iam-infra/blob/master/docs/cluster-ci.md#creating-a-deployment-pipeline-using-aws-console)
    - 3.4.1 [Create the Pipeline](https://github.com/mozilla-iam/iam-infra/blob/master/docs/cluster-ci.md#create-the-pipeline-1)
    - 3.4.2 [The build stage](https://github.com/mozilla-iam/iam-infra/blob/master/docs/cluster-ci.md#the-build-stage-1)
    - 3.4.3 [The deployment stage](https://github.com/mozilla-iam/iam-infra/blob/master/docs/cluster-ci.md#-the-deployment-stage-1)
- 4 [Monitoring applications](https://github.com/mozilla-iam/iam-infra/blob/master/docs/metrics.md)
  - 4.1 [Metrics in Kubernetes](https://github.com/mozilla-iam/iam-infra/blob/master/docs/metrics.md#monitoring-in-kubernetes)
    - 4.1.1 [Deploying the monitoring stack](https://github.com/mozilla-iam/iam-infra/blob/master/docs/metrics.md#deploying-the-stack-into-a-kubernetes-cluster)
    - 4.1.2 [Fetching metrics from your application](https://github.com/mozilla-iam/iam-infra/blob/master/docs/metrics.md#monitoring-your-application)
  - 4.2 [Central logging stack](https://github.com/mozilla-iam/iam-infra/blob/master/docs/logging.md)
    - 4.2.1 [Intro](https://github.com/mozilla-iam/iam-infra/blob/master/docs/logging.md#central-logging-stack)
    - 4.2.2 [Components](https://github.com/mozilla-iam/iam-infra/blob/master/docs/logging.md#components)
    - 4.2.3 [Deployment](https://github.com/mozilla-iam/iam-infra/blob/master/docs/logging.md#deployment)
    - 4.2.4 [Configuration](https://github.com/mozilla-iam/iam-infra/blob/master/docs/logging.md#configuration)
    - 4.2.5 [Usage](https://github.com/mozilla-iam/iam-infra/blob/master/docs/logging.md#usage)
- 5 [Runbooks and Troubleshooting](/docs/runbooks/)
  - 5.1 [Disaster recovery and backups](https://github.com/mozilla-iam/iam-infra/blob/master/docs/runbooks/cluster-and-services.md#disaster-recovery-and-backups)
  - 5.2 [General problems](https://github.com/mozilla-iam/iam-infra/blob/master/docs/runbooks/cluster-and-services.md#general-problems)
    - 5.2.1 [Pod stuck in ContainerCreatingState](https://github.com/mozilla-iam/iam-infra/blob/master/docs/runbooks/cluster-and-services.md#pod-stuck-in-containercreating-state)
  - 5.3 [Cluster services](https://github.com/mozilla-iam/iam-infra/blob/master/docs/runbooks/cluster-and-services.md#cluster-services)
    - 5.3.1 [MongoDB](https://github.com/mozilla-iam/iam-infra/blob/master/docs/runbooks/cluster-and-services.md#mongodb)
  - 5.4 [Applications](/docs/runbooks/)
    - 5.4.1 [SSO Dashboard](https://github.com/mozilla-iam/iam-infra/blob/master/docs/runbooks/sso-dashboard.md#sso-dashboard-runbook)

