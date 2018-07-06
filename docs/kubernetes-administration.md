# EKS cluster management

This document provides instructions for Kubernetes cluster administration (user management). It also focuses on managing cluster addons like kube2iam.

See the [README](/README.md) for related documents.

# Table of Contents

- [Introduction](#toc-introduction)
- [User management](#toc-user-management)
  - [Add a new user](#toc-add-user)
    - [Configure IAM](#toc-add-user-in-iam)
    - [Configure ConfigMap](#toc-add-user-to-configmap)
- [kube2iam setup](#toc-kube2iam-setup)
  - [Service account and role binding](#toc-kube2iam-role)
  - [Daemonset](#toc-kube2iam-daemonset)
  - [Testing the configuration](#toc-kube2iam-testing)
  - [Role naming](#toc-role-naming)

# <a id="toc-introduction"></a>Introduction

Generally speaking, a new user should refer to the Kubernetes documentation for questions about cluster administration. In this document, I do want to provide a quick reference for actions that I expect to be repeated across all of our clusters. As of today, I know that we will be setting up new users, roles, kube2iam and Calico after every new cluster is created. Until these documented steps are automated, this should be a useful resource.

# <a id="toc-user-management"></a>User Management

Work in progress.

## <a id="toc-add-user"></a>Add a new user

## <a id="toc-add-user-in-iam"></a>Configure IAM

## <a id="toc-add-user-to-configmap"></a>Configure ConfigMap

# <a id="toc-kube2iam-setup"></a>kube2iam setup

kube2iam will allow us to impose strict control over the AWS API calls that can be made by individual pods. This is useful for many reasons but we can imagine having `webservice-01` and `webservice-02`. Each has a set of secrets to perform its function. We can create an IAM role for each web service which only provides access to certain S3 buckets or namespaced Parameter Store values.

We benefit from this if someone compromises the security of a pod.

## <a id="toc-kube2iam-role"></a>Service account and role binding

Create a new service role for kube2iam.

Note: This is only required on clusters with RBAC enabled. We should always have RBAC enabled.

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

## <a id="toc-kube2iam-daemonset"></a>Daemonset

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

This daemonset diverges from the kube2iam documentation when passing arguments into kube2iam. The `--host-interface` should be set to `eni+` to work with VPC ENIs.

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
