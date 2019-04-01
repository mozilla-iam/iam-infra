# EKS cluster management

This document provides instructions for Kubernetes cluster administration (user management). It also focuses on managing cluster addons like kube2iam.

See the [README](/README.md) for related documents.

# Table of Contents

- [Introduction](#toc-introduction)
- [User management](#toc-user-management)
  - [Allow CodeBuild to deploy](#toc-allow-codebuild)
  - [Add a new user](#toc-add-user)
    - [Configure IAM](#toc-add-user-in-iam)
    - [Configure ConfigMap](#toc-add-user-to-configmap)
- [kube2iam setup](#toc-kube2iam-setup)
  - [Testing the configuration](#toc-kube2iam-testing)
  - [Role naming](#toc-role-naming)
- [Upgrades](#toc-upgrades)
  - [Prometheus Operator](#toc-upgrade-prometheus-operator)

# <a id="toc-introduction"></a>Introduction

Generally speaking, a new user should refer to the Kubernetes documentation for questions about cluster administration. In this document, I do want to provide a quick reference for actions that I expect to be repeated across all of our clusters. As of today, I know that we will be setting up new users, roles, kube2iam and Calico after every new cluster is created. Until these documented steps are automated, this should be a useful resource.

# <a id="toc-user-management"></a>User Management

EKS user management requires two separate changes. A user or role will need to be created in IAM. That ARN can be added to the `aws-auth` ConfigMap in Kuberenetes to authorize it to perform certain actions associated with a user and groups.

## <a id="toc-allow-codebuild"></a>Allow CodeBuild to deploy
In order to allow CodeBuild to run commands in a EKS Kubernetes cluster, you need to add the user which runs the CodeBuild job to the `aws-auth` ConfigMap. This process has to be enhanced, and probably future versions of EKS come with a better support for doing this kind of things. For the moment just edit the `aws-auth` configmap running `kubectl edit configmap -n kube-system aws-auth`.
As an example, the next snippet gives the user rights to deploy into the cluster:
```yaml
mapRoles:
----
...
- rolearn: arn:aws:iam::320464205386:role/template-codebuild
  groups:
    - system:masters
```

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

# <a id="toc-upgrades"></a>Upgrades
This section provides insights on how to upgrade different services running in the cluster.
Before upgrading any component, you should read before its Changelog and make sure the upgrade will not break any functionality needed.

## <a id="toc-upgrade-prometheus-operator"></a>Prometheus-Operator
Prometheus Operator is taking care of choosing the right container image for Prometheus, so if you want to upgrade to a more recent version, first you have to check if it is supported by the operator, and upgrade this one.
Before start doing it, is important that you read the [Changelog](https://github.com/coreos/prometheus-operator/blob/master/CHANGELOG.md) and verify that there are not incompatible changes, or if they are, that you took care of those.

New versions can modify 2 very different things: the code of the prometheus-operator binary and/or the code of the CRDs.

If you want to upgrade to a new version, which is not modifying the CRDs you are lucky, it's strightforward! Modify the version of the operator [here](https://github.com/mozilla-iam/eks-deployment/blob/master/cluster-conf/monitoring/10-prometheus-operator.yml#L103), apply the changes, and delete the prometheus-operator pod. Kubernetes will take care of starting it again using the new image.

If the upgrade modifies also the CRDs, you will have to replace them first: "kubectl replace -f 01-*". Once this is done, the prometheus-operator pod should start again hopefully without any errors. In case you face errors, better fixing them while the old version of Prometheus is running. Once you are done with it, you can delete the prometheus-master pod, and the operator will recreate it using the new image.
