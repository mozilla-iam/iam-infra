#!/bin/bash

#######################################################################################################
#
# This script performs rolling deployments of Kubernetes worker nodes, doing a blue/green deployment
# of their AutoscalingGroups. It's normally used to perform upgrades of EC2 instances OS.
#
# It detects which Autoscaling group is active and its desired capacity, after it scales the inactive
# ASG to N+1 instances, starts draining kubernetes nodes one by one making sure applications are
# able to start in the new nodes. After all the Pods have been moved, and the instances drained,
# deleted from Kubernetes and the underlying EC2 instance is deleted after reducing the ASG to 0.
#
# Note: $ASG_ACTIVE corresponds to the active ASG at the beginning of the run, and will keep that name
# even if at the end of the script it will be Inactive. Same (but all the way around) for $ASG_INACTIVE
# 
# Maintainer: <adelbarrio@mozilla.com>
#
#######################################################################################################

ENV="stage"

echo "In few moments a Blue/Green deployment for the worker nodes of the Kubernetes cluster"
echo -e "$ENV is going to start. Interrupt now if you don't want to continue\n"

# Check all pods are running before starting
if [[ $(kubectl get pods --all-namespaces | grep -v Running | wc -l) -ne 1 ]]; then
  echo "There are Pods which are not in 'Running' state, fix those before continuing"
  exit 1
fi

# Check that the current context contains $ENV in its name. This will safe you from
# pointing to a different cluster
if [[ ! $(kubectl config current-context) == *"$ENV"* ]] ; then
  echo "$ENV not found in context name, check you are pointing to the current environment and try again"
  exit 1
fi

# Query all the Autoscaling groups, grep for filtering by Environment
ASGS=$(aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[].[AutoScalingGroupName]' --output text | grep $ENV | grep 'blue\|green')

# Checking which one of the 2 ASGs is active:
for ASG in $ASGS; do
  INSTANCES=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[*].DesiredCapacity" --auto-scaling-group-names $ASG --output text)
  if [[  $INSTANCES -gt 0 ]]; then
    ASG_ACTIVE=$ASG
    NUM_INSTANCES=$INSTANCES
    ASG_MAX_MIN=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[*].[MaxSize,MinSize]" --auto-scaling-group-names $ASG --output text)
    ASG_MAX_SIZE=$(echo $ASG_MAX_MIN| cut -d' ' -f 1)
    ASG_MIN_SIZE=$(echo $ASG_MAX_MIN| cut -d' ' -f 2)
  else
    ASG_INACTIVE=$ASG
  fi
done

echo -e "Currently $ASG_ACTIVE is active with $NUM_INSTANCES instances running.\n" 

# Get some parameters from the active ASG 
# Check that num of k8s nodes match the ASG expected number of instances
ASG_ACTIVE_NODES=$(kubectl get nodes -o name | cut -d'/' -f2)
NUM_KUBE_NODES=$(kubectl get nodes -o name | wc -l)
if [[ $NUM_KUBE_NODES -ne $NUM_INSTANCES ]]; then
  echo "The number of instances reported by Kubernetes differs with the ones reported by the active ASG"
  echo "Kubernetes reports $NUM_KUBE_NODES and ASG reports: $NUM_INSTANCES. Check which ASG are active"
  echo "This should not happen, exiting here"
  exit 1
fi

echo "Starting the $ASG_INACTIVE with capacities: min=$ASG_MIN_SIZE max=$ASG_MAX_SIZE desired=$(( NUM_INSTANCES + 1 ))"
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_INACTIVE \
	--max-size $ASG_MAX_SIZE --min-size $ASG_MIN_SIZE --desired-capacity $(( NUM_INSTANCES + 1 ))


while [[ $(kubectl get nodes -o name | wc -l) -ne $(( NUM_INSTANCES + 1 + NUM_KUBE_NODES)) ]] ; do
  echo "Waiting for all the instances to join the cluster..."
  sleep 10
done

while [[ $(kubectl get nodes | grep 'NotReady') ]] ; do
  echo "Waiting for all the instances to be in 'Ready' state..."
  sleep 10
done

echo -e "All new instances have joined the cluster. Starting to drain the old ones\n"

for NODE in $(echo $ASG_ACTIVE_NODES); do
  echo "Draining node $NODE"
  kubectl drain --ignore-daemonsets=true --delete-local-data=true $NODE

  sleep 3
  while [[ $(kubectl get pods --all-namespaces | grep -v Running | wc -l) -ne 1 ]]; do
    echo -e "Waiting on all the pods to be in 'Running' state"
    sleep 5
  done
done

# Now that all old nodes have been drained, we will reduce the old active ASG to 0
# this won't delete the instance as they are protected from scale-in
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_ACTIVE --min-size 0 --max-size 0 --desired-capacity 0

# Cleaning up: Delete nodes from K8s
for NODE in $(echo $ASG_ACTIVE_NODES); do
  kubectl delete node $NODE
done

# Cleaning up: Delete EC2 instances
for INSTANCE in $(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_ACTIVE --query "AutoScalingGroups[*].Instances[*].InstanceId" --output text) ; do
  aws autoscaling terminate-instance-in-auto-scaling-group --instance-id $INSTANCE --no-should-decrement-desired-capacity >/dev/null
done

echo -e "\nWe are done: $ASG_ACTIVE has been scaled down to 0 and $ASG_INACTIVE is active now!"

