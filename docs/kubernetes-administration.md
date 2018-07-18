# EKS cluster management

This document provides instructions for Kubernetes cluster administration (user management). It also focuses on managing cluster addons like kube2iam.

See the [README](/README.md) for related documents.

# Table of Contents

- [Introduction](#toc-introduction)
- [Configuration syncing with Flux](#toc-flux)
- [User management](#toc-user-management)
  - [Add a new user](#toc-add-user)
    - [Configure IAM](#toc-add-user-in-iam)
    - [Configure ConfigMap](#toc-add-user-to-configmap)
- [kube2iam setup](#toc-kube2iam-setup)
  - [Testing the configuration](#toc-kube2iam-testing)
  - [Role naming](#toc-role-naming)

# <a id="toc-introduction"></a>Introduction

Generally speaking, a new user should refer to the Kubernetes documentation for questions about cluster administration. In this document, I do want to provide a quick reference for actions that I expect to be repeated across all of our clusters. As of today, I know that we will be setting up new users, roles, kube2iam and Calico after every new cluster is created. Until these documented steps are automated, this should be a useful resource.

# <a id="toc-flux"></a>Configuration syncing with Flux

Fortunately, we can simplify cluster management with the GitOps Kubernetes operator from Weaveworks.

https://github.com/weaveworks/flux

We can deploy Flux to our cluster with the following instructions:

https://github.com/weaveworks/flux/blob/master/site/standalone/installing.md

First, clone the repository and edit `deploy/flux-deployment.yaml` to set the `--git-url` parameter. We want to set this to our configuration repository at `mozilla-iam/eks-configuration`. Once Flux is running in the cluster, capture the SSH public key that it generates and add it as a deploy key, with write access, to the `mozilla-iam/eks-configuration` repository. Flux will automatically poll the repository for changes and `kubectl apply` each YAML file in the repository.

**Note:** This will not remove resources once they have been created. You will have to do that manually.

Today, this will setup:

- Calico
- kube2iam
- Prometheus and Grafana

**Security concerns:**

Unfortunately, the Flux project has an open issue to evaluate and implement read-only access to a source repository. Until this is available, we will need to add the deploy key to the settings for the GitHub repository.

Flux keeps the private key as a Kubernetes secret:

https://github.com/weaveworks/flux/blob/master/deploy/flux-deployment.yaml#L16-L20

If the secret store were compromised or the Flux container itself, which is not exposed to the internet, an attacker could gain write access to the source repository. We should be able to improve our security by restricting the Kubernetes namespaces that Flux has access to. Beyond that, if an attacker can write to the repository, they would have either full control or partial control over our cluster.

In order to get the private key, an attacker would have to have some foothold into the cluster anyway so this may not be a huge concern for us today. We could also leak the private key but we would have to go out of our way to access the Kubernetes secret and expose it in some way.

**Flux demo:**

[![asciicast](https://asciinema.org/a/K8ZXtHuSaqqsDUDte3pjQn85e.png)](https://asciinema.org/a/K8ZXtHuSaqqsDUDte3pjQn85e)

# <a id="toc-user-management"></a>User Management

EKS user management requires two separate changes. A user or role will need to be created in IAM. That ARN can be added to the `aws-auth` ConfigMap in Kuberenetes to authorize it to perform certain actions associated with a user and groups.

## <a id="toc-add-user"></a>Add a new user

## <a id="toc-add-user-in-iam"></a>Configure IAM

Create a [new user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html) or [role](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create.html) in IAM. Take care to ensure that new users setup MFA. Once this work is complete, make a note of the ARN for the user or role.

## <a id="toc-add-user-to-configmap"></a>Configure ConfigMap

Please read the linked documentation for a comprehensive overview of this process. Here is an example of the udpated ConfigMap might contain:

```yaml
  mapUsers: |
    - userarn: arn:aws:iam::555555555555:user/admin
      username: admin
      groups:
        - system:masters
```

[Source](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html).

# <a id="toc-kube2iam-setup"></a>kube2iam setup

kube2iam will allow us to impose strict control over the AWS API calls that can be made by individual pods. This is useful for many reasons but we can imagine having `webservice-01` and `webservice-02`. Each has a set of secrets to perform its function. We can create an IAM role for each web service which only provides access to certain S3 buckets or namespaced Parameter Store values.

We benefit from this if someone compromises the security of a pod.

**Update**: kube2iam does not need to be setup manually anymore. We use a Kubernetes operator called Flux to poll for changes in a GitHub configuration repository. When a change is detected, or after Flux runs for the first time, the `kube2iam.yaml` file is applied to the cluster.

## <a id="toc-kube2iam-testing"></a>Testing the configuration

Now, there should be a kube2iam pod running on each worker node in the cluster:

```sh
$ kubectl get pods -n kube-system | grep kube2iam
kube2iam-m5vmr             1/1       Running   0          2d
kube2iam-pjzpn             1/1       Running   0          2d
```

You'll want to refer to the kube2iam documentation to see how annotations are used to specify the role arn to be assumed by pods.

As a general note, I did find the following useful for testing kube2iam. I created a new pod with the following YAML and tested different annotations and resource requests:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: aws-cli
  labels:
    name: aws-cli
  annotations:
    iam.amazonaws.com/role: arn:aws:iam::SOMETHING
spec:
  containers:
  - image: fstab/aws-cli
    command:
      - "/home/aws/aws/env/bin/aws"
      - "s3"
      - "ls"
      - "s3://bucket"
    name: aws-cli
```

Please review the next section for standards on role naming in AWS.

## <a id="toc-role-naming"></a>Role naming

Please adhere to these naming conventions when creating new IAM roles that will be referenced in pod annotations.

```
arn:aws:iam::{{ account_id }}:role/eks-{{ service_name }}-{{ env }}
```

We have not settled on a templating solution yet. This document will be updated once that is available.
