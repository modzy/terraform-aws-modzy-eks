
module "iam_assumable_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "4.1.0"
  create_role = true
  role_name = "${var.cluster_name}-cluster-autoscaler"
  provider_url = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns = [aws_iam_policy.cluster_autoscaler.arn]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:${var.cluster_autoscaler_namespace}:${var.cluster_autoscaler_serviceaccount_name}"
  ]
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name = "${var.cluster_name}-eks-autoscaling-policy"
  description = "EKS autoscaling policy for ${var.cluster_name} cluster."
  policy = data.aws_iam_policy_document.cluster_autoscaler.json
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup"
    ]
    resources = ["*"]
    condition {
      test = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${module.eks.cluster_id}"
      values = ["owned"]
    }
    condition {
      test = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values = ["true"]
    }
  }
}
