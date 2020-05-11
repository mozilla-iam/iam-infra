#!/bin/bash


# Install audisp-json (required by EIS)
aws s3 cp --recursive s3://audisp-json/ /tmp
sudo rpm -i /tmp/audisp-json-2.2.5-1.x86_64-amazon.rpm
sudo mv /tmp/audisp-json.conf /etc/audisp/audisp-json.conf
sudo service auditd restart

# Install amazon-ssm-agent (can't run as a DaemonSet because kube2iam)
sudo yum install -y amazon-ssm-agent 
sudo systemctl start amazon-ssm-agent"

