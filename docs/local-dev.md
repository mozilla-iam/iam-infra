# EKS cluster management

This document provides recommendations for local development workflow.

See the [README](/README.md) for related documents.

# Table of Contents

- [Introduction](#toc-introduction)
- [Minikube](#toc-minikube)

# <a id="toc-introduction"></a>Introduction

Hopefully, as our infrastructure matures, we will all have a pretty similar
toolchain for testing our Kubernetes deployments. Based on our conversations in
sprint planning, it seems perfectly reasonable to recommend Minikube in the
short term. It provides an excellent environment to test deployments and
services.

# <a id="toc-minikube"></a>Minikube

I don't want to re-write existing documentation so I will defer you to the
excellent setup steps provided by the Kubernetes project:

https://kubernetes.io/docs/setup/minikube/#installation

Follow the installation and quickstart steps in order to get a cluster running
on your workstation. With that in place, you can use `kubectl` to experiment
with your Kubernetes projects.
