#
# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EC2 Security Group to allow networking traffic
#  * Data source to fetch latest EKS worker AMI
#  * AutoScaling Launch Configuration to configure worker instances
#  * AutoScaling Group to launch worker instances
#

resource "aws_iam_role" "demo-node" {
  name = "terraform-${var.cluster-name}-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role" "cluster-autoscaler" {
  name = "terraform-${var.cluster-name}-ClusterAutoscaler"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_role.demo-node.arn}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role" "keel" {
  name = "terraform-${var.cluster-name}-node-keel"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_role.demo-node.arn}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "cluster-autoscaler-policy" {
  name = "terraform-${var.cluster-name}-node-ClusterAutoscaler"
  role = "${aws_iam_role.cluster-autoscaler.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "keel-policy" {
  name = "terraform-${var.cluster-name}-node-keel"
  role = "${aws_iam_role.keel.id}"

  policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [{
		"Effect": "Allow",
		"Action": [
			"ecr:GetAuthorizationToken",
			"ecr:BatchCheckLayerAvailability",
			"ecr:GetDownloadUrlForLayer",
			"ecr:GetRepositoryPolicy",
			"ecr:DescribeRepositories",
			"ecr:ListImages",
			"ecr:DescribeImages",
			"ecr:BatchGetImage"
		],
		"Resource": "*"
	}]
}
EOF
}

resource "aws_iam_policy" "sts-assume-role" {
  name = "terraform-${var.cluster-name}-node-AllowSTSAssumeRole"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::656532927350:role/*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "demo-node-STSAssumeRole" {
  policy_arn = "${aws_iam_policy.sts-assume-role.arn}"
  role       = "${aws_iam_role.demo-node.name}"
}

resource "aws_iam_role_policy_attachment" "demo-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.demo-node.name}"
}

resource "aws_iam_role_policy_attachment" "demo-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.demo-node.name}"
}

resource "aws_iam_role_policy_attachment" "demo-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.demo-node.name}"
}

resource "aws_iam_instance_profile" "demo-node" {
  name = "terraform-${var.cluster-name}"
  role = "${aws_iam_role.demo-node.name}"
}

resource "aws_security_group" "demo-node" {
  name        = "terraform-${var.cluster-name}-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${aws_vpc.demo.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "terraform-${var.cluster-name}-node",
     "kubernetes.io/cluster/${var.cluster-name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "demo-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.demo-node.id}"
  source_security_group_id = "${aws_security_group.demo-node.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "demo-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.demo-node.id}"
  source_security_group_id = "${aws_security_group.demo-cluster.id}"
  to_port                  = 65535
  type                     = "ingress"
}

data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["eks-worker-*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon
}

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/amazon-eks-nodegroup.yaml
locals {
  demo-node-userdata = <<USERDATA
#!/bin/bash -xe

CA_CERTIFICATE_DIRECTORY=/etc/kubernetes/pki
CA_CERTIFICATE_FILE_PATH=$CA_CERTIFICATE_DIRECTORY/ca.crt
mkdir -p $CA_CERTIFICATE_DIRECTORY
echo "${aws_eks_cluster.demo.certificate_authority.0.data}" | base64 -d >  $CA_CERTIFICATE_FILE_PATH
INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
sed -i s,"bin/kubelet","bin/kubelet --eviction-hard=memory.available<500Mi --system-reserved=memory=768Mi",g /etc/systemd/system/kubelet.service
sed -i s,MASTER_ENDPOINT,${aws_eks_cluster.demo.endpoint},g /var/lib/kubelet/kubeconfig
sed -i s,CLUSTER_NAME,${var.cluster-name},g /var/lib/kubelet/kubeconfig
sed -i s,REGION,${data.aws_region.current.name},g /etc/systemd/system/kubelet.service
sed -i s,MAX_PODS,20,g /etc/systemd/system/kubelet.service
sed -i s,MASTER_ENDPOINT,${aws_eks_cluster.demo.endpoint},g /etc/systemd/system/kubelet.service
sed -i s,INTERNAL_IP,$INTERNAL_IP,g /etc/systemd/system/kubelet.service
DNS_CLUSTER_IP=10.100.0.10
if [[ $INTERNAL_IP == 10.* ]] ; then DNS_CLUSTER_IP=172.20.0.10; fi
sed -i s,DNS_CLUSTER_IP,$DNS_CLUSTER_IP,g /etc/systemd/system/kubelet.service
sed -i s,CERTIFICATE_AUTHORITY_FILE,$CA_CERTIFICATE_FILE_PATH,g /var/lib/kubelet/kubeconfig
sed -i s,CLIENT_CA_FILE,$CA_CERTIFICATE_FILE_PATH,g  /etc/systemd/system/kubelet.service
systemctl daemon-reload
systemctl restart kubelet
USERDATA
}

resource "aws_launch_configuration" "demo2" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.demo-node.name}"
  image_id                    = "${data.aws_ami.eks-worker.id}"
  instance_type               = "${var.instance-type}"
  name_prefix                 = "terraform-${var.cluster-name}"
  security_groups             = ["${aws_security_group.demo-node.id}"]
  user_data_base64            = "${base64encode(local.demo-node-userdata)}"

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 50
  }
}

resource "aws_cloudformation_stack" "mymodule_asg" {
  name          = "cf-terraform-${var.cluster-name}"
  depends_on    = ["aws_launch_configuration.demo2"]

  lifecycle {
    create_before_destroy = true
  }

  template_body = <<EOF
{
  "Resources": {
    "${replace("CFTerraform-${var.cluster-name}","-","")}": {
      "Type": "AWS::AutoScaling::AutoScalingGroup",
      "Properties": {
        "VPCZoneIdentifier": ${jsonencode("${aws_subnet.demo.*.id}")},
        "LaunchConfigurationName": "${aws_launch_configuration.demo2.name}",
        "MaxSize": ${var.instance-max},
        "MinSize": ${var.instance-min},
        "DesiredCapacity": ${var.instance-desired-capacity},
        "TerminationPolicies": ["OldestLaunchConfiguration", "OldestInstance"],
        "Tags" : [
          {
            "Key": "Name",
            "Value": "terraform-${var.cluster-name}",
            "PropagateAtLaunch": "true"
          },
          {
            "Key": "kubernetes.io/cluster/${var.cluster-name}",
            "Value": "owned",
            "PropagateAtLaunch": "true"
          },
          {
            "Key": "k8s.io/cluster-autoscaler/${var.cluster-name}",
            "Value": "",
            "PropagateAtLaunch": "true"
          },
          {
            "Key": "k8s.io/cluster-autoscaler/enabled",
            "Value": "true",
            "PropagateAtLaunch": "true"
          }
        ]
      },
      "CreationPolicy" : {
        "AutoScalingCreationPolicy" : {
          "MinSuccessfulInstancesPercent" : 0
        },
        "ResourceSignal": {
          "Count": 0
        }
      },
      "UpdatePolicy": {
        "AutoScalingRollingUpdate": {
          "MinInstancesInService": ${var.instance-min},
          "MaxBatchSize": 1,
          "PauseTime": "PT3M",
          "WaitOnResourceSignals" : false
        }
      }
    }
  },
  "Outputs": {
    "${replace("CFTerraform-${var.cluster-name}","-","")}": {
      "Description": "The name of the auto scaling group for ${var.cluster-name}",
       "Value": {"Ref": "${replace("CFTerraform-${var.cluster-name}","-","")}"}
    }
  }
}
EOF
}
