#!/bin/bash


# Enable auditd (required by EIS)
aws s3 cp --recursive s3://audisp-json/v2 /tmp
sudo mv /tmp/audit.rules /etc/audit/rules.d/audit.rules
sudo mv /tmp/auditd.conf /etc/audit/auditd.conf
sudo service auditd restart

# Install amazon-ssm-agent (can't run as a DaemonSet because kube2iam)
sudo yum install -y amazon-ssm-agent 
sudo systemctl start amazon-ssm-agent
