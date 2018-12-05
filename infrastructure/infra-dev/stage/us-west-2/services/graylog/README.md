# Graylog

We are using Amazon's managed Elasticsearch service for Graylog. This will
provide the following:

* An Elasticsearch domain
* An Elasticsearch service linked role in IAM (see
* [this](https://github.com/terraform-providers/terraform-provider-aws/issues/5218)
* for more information)
* Data calls to capture the private subnets created in this region's VPC
* Data calls to capture the SG ID bound to EKS worker nodes
