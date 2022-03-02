data "aws_vpc" "current" {
  id = var.vpc_id
}

resource "aws_ec2_tag" "vpc" {
  resource_id = data.aws_vpc.current.id
  key = "kubernetes.io/cluster/${var.cluster_name}"
  value = "shared"
}

resource "aws_ec2_tag" "subnets" {
  for_each = toset(var.subnets)
  resource_id = each.key
  key = "kubernetes.io/cluster/${var.cluster_name}"
  value = "shared"
}
