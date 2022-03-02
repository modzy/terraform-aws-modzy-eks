
locals {
  node_group_tags = concat(
    [for k, v in local.tags :
      {
        key = k
        propagate_at_launch = "true"
        value = v
      }
    ],
    [
      {
        key = "k8s.io/cluster-autoscaler/enabled"
        propagate_at_launch = "false"
        value = "true"
      },
      {
        key = "k8s.io/cluster-autoscaler/${var.cluster_name}"
        propagate_at_launch = "false"
        value = "owned"
      }
    ],
  )
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "17.24.0"
 
  cluster_name = var.cluster_name
  cluster_version = var.k8s_version
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_endpoint_private_access = true
  cluster_endpoint_private_access_cidrs = var.management_cidrs
  cluster_create_endpoint_private_access_sg_rule = true
  cluster_endpoint_public_access = false

  enable_irsa = true

  subnets = var.subnets
  vpc_id = var.vpc_id

  map_users = [
    {
      userarn = var.admin_role_arn
      username = var.admin_role_arn
      groups = ["system:masters"]
    }
  ]

  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks_secrets.arn
      resources = ["secrets"]
    }
  ]

  worker_groups_launch_template = [
    for node_group in var.node_groups : merge(node_group, {
      tags = concat(local.node_group_tags, lookup(node_group, "tags", []))
    })
  ]

  workers_group_defaults = {
    health_check_type = "EC2"
    key_name = var.ec2_keypair_name

    root_volume_size = "100"
    root_volume_type = "gp2"
    ebs_optimized = true
    enable_monitoring = var.enable_monitoring

    public_ip = false

    enabled_metrics = ["GroupDesiredCapacity"]

    root_kms_key_id = aws_kms_key.ebs.arn
    root_encrypted = true
  }
}
