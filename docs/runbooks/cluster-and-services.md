# Kubernetes Runbooks

This document provides instructions and insights on how to fix some of the problems we have encountered during the lifetime of the cluster.

See the [README](/README.md) for related documents.

# Table of Contents

- [Introduction](#toc-introduction)
- [General problems](#general-problems)
  - [Pod stuck in ContainerCreating state](#pod-stuck-containercreating)
    - [No Resources Available](#no-resources-available)
    - [ConfigMap/Secret/Volume not found](#resource-not-found)
- [Disaster recovery and backups](#dr-and-backups)
- [Cluster services](#cluster-services)
  - [MongoDB](#mongodb)

# <a id="toc-introduction"></a>Introduction


# <a id="general-problems"></a>General problems

This section provides information about common problems which are not tied to a specific Service. Thus you can try the steps listed here to debug your application if not behaving as expected.

## <a id="pod-stuck-containercreating"></a>Pod stuck in ContainerCreating state

If some of your pods are stuck in ContainerCreating state, the first thing you should do is to find out why is doing that. Normally you will find the answer running `kubectl describe pod PodName -n=NamespaceName`.

### <a id="no-resources-available"></a>No resources available

The most common problem why a pod can not a reference to a ConfigMap, Secret, or Volume which does not exists. In the case you should check the different resources and make sure they are in place.

### <a id="no-resources-available"></a>No resources available

Sometimes Pods are not able to start because there are not enough resources of some kind (CPU, Memory, Disk) available. Generally, the cluster autoscaler should deal with this problem, so first of all you should check ClusterAutoscaler logs in Graylog.

It can be that the ASG already hit the maximum number of instances it can scale. In that case, modify the Terraform code to increase the AutoScalingGroup.

Other possibility is that the Pod tries to mount a volume which was created in an Availability Zone where currently there are not nodes running. We have seen this problem, and overcome it forcing the cluster to create new nodes scaling up some deployment. After the node is created in the right region, scale the Deployment down again.

# <a id="dr-and-backups"></a>Disaster recovery and backups

In order to backup Kubernetes configuration, secrets and persistent volumes we are using Ark, a piece of software developed by Heptio to make easy the process of taking and restoring this kind of backups.

Ark is composed by a server running in the cluster, and a client running in your local machine. In order to schedule and manage backups, and also to restore them you first should install Ark. It can be dowloaded from [here](https://github.com/heptio/ark/releases). It uses your KubeConfig file to find the right cluster, so if you are able to access the Kubernetes cluster, you are all set.

Now, you can take a look at the available backups running `ark backup get`. There you should see several backups with a timestamp. Find the one you want to restore and run: `ark restore create --from-backup $backup-name`, once this is done you can follow the restoring process by running `ark restore get`. 

If you need more information, check the official [Ark documentation](https://heptio.github.io/ark/v0.10.0/index.html).


# <a id="cluster-services"></a>Cluster services

## <a id="mongodb"></a>MongoDB

MongoDB is deployed via a StatefulSet with 3 replicas and it is only used to store Graylog's configuration. In case only one pod is not able to start, everything will continue working as expected. In case the Mongo cluster is down and Graylog can't access it, the log ingestion will continue working, but we will not be able to make changes in Graylog like adding users, streams... This is why is not a big deal, and can wait until business hours to be fixed.


### Mongo can not start because of corrupted file.
The logs from the affected pod are showing messages similar to this one: `log file journal/WiredTigerLog.0000005020 corrupted`.

The first thing to notice is the scope of the issue, if this is only happening to a pod, and the other two are members of the same cluster, we are not really experiencing a big problem.
The solution to this, is to wipe the underlying storage, restart the pod and it will re-join the cluster and sync the info from the other members. The size of the database its and will be small, so syncing should not take more than a couple of minutes.
We don't have a reliable solution yet on how to wipe the underlying storage, basically due to the nature of a StatefulSet. One solution is delete the PVC, and later the EBS volume backing it. However the time we have performed this, it caused on Kubernetes node (EC2 instance) to go to NodeLost state. If you know how to do it, please update this documentation.
