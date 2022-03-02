# Modzy AWS EKS Terraform Module

This Terraform module will provision and configure the EKS cluster necessary to run a
Modzy environment in AWS. 


## Usage

This module is called from the <a href="https://github.com/modzy/terraform-aws-modzy-env"> Modzy Terraform Module </a>


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| aws_region | The AWS Region that this deployment will be made in. | string | | yes |
| aws_profile | The AWS CLI profile to use to provide credentials to automate AWS resources. | string | | yes |
| cluster_name | Name of the AWS EKS cluster to create | string | | yes |
| k8s_version | The version of Kubernetes to deploy. | string | 1.21 | | yes |
| management_cidrs | A list of CIDRs that are considered part of your management network. These CIDRs will automatically be added to various security groups to allow direct access to internal resources. It is _highly_ recommended that these only include private networks accessed via VPN or bastion host/jump box. | list(string) | | yes |
| enable_monitoring | Enabling monitoring | string | true | no |
| admin_role_arn | The AWS IAM Role ARN that will be granted full access to the EKS cluster. | string | | yes |
| tags | A map of tags that will be applied to every AWS object that supports tags. | map(string) | | no |
| vpc_id | The VPC ID to deploy resources into. | string | | yes |
| ec2_keypair_name | The EC2 Keypair name to assign to all EKS nodes. | string | | yes |
| node_groups | A list of the additional node groups to attach to EKS for running models. | list(object) | | yes |

