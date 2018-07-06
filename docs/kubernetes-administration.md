# EKS cluster management

This document provides instructions for Kubernetes cluster administration (user management). We also focus on managing cluster addons which are essential to meet our security best practices.

See the [README](/README.md) for related documents.

# Table of Contents

- [Introduction](#toc-introduction)
- [Overview](#toc-overview)
  - [kube2iam](#toc-kube2iam)
  - [Calico](#toc-calico)
  - [User management](#toc-summary-user-management)
- [User management](#toc-user-management)
  - [Add a new IAM user](#toc-add-iam-user)
    - [Configure IAM](#toc-add-user-in-iam)
    - [Configure ConfigMap](#toc-add-user-to-configmap)
- [kube2iam setup](#toc-kube2iam-setup)
  - [Service account and role binding](#toc-kube2iam-role)
  - [Daemonset](#toc-kube2iam-daemonset)
  - [Testing the configuration](#toc-kube2iam-testing)
- [Calico setup](#toc-calico-setup)
  - [Undefined](#toc-calico-undefined)

# <a id="toc-introduction"></a>Introduction

This document is a work in progress.

### kube2iam

#### Why?

kube2iam will allow us to impose strict control over the AWS API calls that can be made by individual pods. This is useful for many reasons but we can imagine having `webservice-01` and `webservice-02`. Each has a set of secrets to perform its function. We can create an IAM role for each web service which only provides access to certain S3 buckets, namespaced Parameter Store values, etc.

If someone compromises one pod, they won't be able to access the secrets for the other service's pods because of the strict control that kube2iam affords us.

#### Setup

##### Service account and role binding

Create a new service role for kube2iam if RBAC is enabled on your cluster. We do have RBAC enabled so this is required.

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kube2iam
  namespace: kube-system
```

Apply this with `kubectl`:

```sh
$ kubectl apply -f kube2iam-service-role.yaml
serviceaccount "kube2iam" unchanged
```

Setup the role and binding:

```yaml
---
apiVersion: v1
items:
  - apiVersion: rbac.authorization.k8s.io/v1beta1
    kind: ClusterRole
    metadata:
      name: kube2iam
    rules:
      - apiGroups: [""]
        resources: ["namespaces","pods"]
        verbs: ["get","watch","list"]
  - apiVersion: rbac.authorization.k8s.io/v1beta1
    kind: ClusterRoleBinding
    metadata:
      name: kube2iam
    subjects:
    - kind: ServiceAccount
      name: kube2iam
      namespace: kube-system
    roleRef:
      kind: ClusterRole
      name: kube2iam
      apiGroup: rbac.authorization.k8s.io
kind: List
```

Apply with `kubectl`:

```sh
$ kubectl apply -f kube2iam-role-bindings.yaml
serviceaccount "kube2iam" unchanged
```

Source: https://github.com/jtblin/kube2iam#rbac-setup

##### Create the kube2iam daemonset

You can `kubectl` apply the following daemonset YAML:

```yaml
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: kube2iam
  labels:
    app: kube2iam
  namespace: kube-system
spec:
  template:
    metadata:
      labels:
        name: kube2iam
    spec:
      serviceAccountName: kube2iam
      hostNetwork: true
      containers:
        - image: jtblin/kube2iam:latest
          imagePullPolicy: Always
          name: kube2iam
          args:
            - "--iptables=true"
            - "--host-ip=$(HOST_IP)"
            - "--auto-discover-base-arn"
            - "--host-interface=eni+"
            - "--verbose"
          env:
            - name: HOST_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
          ports:
            - containerPort: 8181
              hostPort: 8181
              name: http
          securityContext:
            privileged: true
```

In this daemonset, we have diverged from the kube2iam documentation when passing arguments into kube2iam. The `--host-interface` should be set to `eni+` because we are currently using this VPC ENI. This is only documented in a [pull request](https://github.com/jtblin/kube2iam/pull/146) from a user. When we look at Calico in the future, this may change.

##### Validate kube2iam

You should have a kube2iam pod running on each worker node in your cluster. In my case, I have two nodes:

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

