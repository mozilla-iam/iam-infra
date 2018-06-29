# Connect to EKS cluster

## Summary

This document provides a brief overview of cluster authentication and user
management.

## Instructions

### Connecting to the cluster with kubectl

Interacting with the cluster with `kubectl` is described in this section of the
[EKS cluster creation
document](create-and-destroy-eks.md#authenticating-and-adding-worker-nodes-to-cluster).

### User management with IAM and the Heptio Authenticator

The AWS documentation provides a nice overview of [cluster
authentication](https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html).

![auth-architecture](https://docs.aws.amazon.com/eks/latest/userguide/images/eks-iam.png)
