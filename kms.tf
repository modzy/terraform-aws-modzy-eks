# ------------------------------------------------------------------------------
# EKS Secrets Encryption Key

resource "aws_kms_key" "eks_secrets" {
  description = "EKS Secrets Encryption for ${var.cluster_name} EKS cluster."
  key_usage = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days = 30
  enable_key_rotation = true
  is_enabled = true
  policy = data.aws_iam_policy_document.eks_secrets_policy.json
}

data "aws_iam_policy_document" "eks_secrets_policy" {
  statement {
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_kms_alias" "eks_secrets" {
  target_key_id = aws_kms_key.eks_secrets.key_id
  name = "alias/${var.cluster_name}-eks-secrets"
}

# ------------------------------------------------------------------------------
# EBS Encryption Key

resource "aws_kms_key" "ebs" {
  description = "EBS Volume Encryption for ${var.cluster_name} EKS nodes."
  key_usage = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days = 30
  enable_key_rotation = true
  is_enabled = true
  policy = data.aws_iam_policy_document.ebs_policy.json
}

# This policy is derived from the default AWS-managed EBS key that comes with each AWS account.
data "aws_iam_policy_document" "ebs_policy" {
  statement {
    sid = "Allow access through EBS for all principals in the account that are authorized to use EBS"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "*"
      ]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey"
    ]
    resources = [
      "*"
    ]
    condition {
      test = "StringEquals"
      variable = "kms:ViaService"
      values = ["ec2.${data.aws_region.current.name}.amazonaws.com"]
    }
    condition {
      test = "StringEquals"
      variable = "kms:CallerAccount"
      values = [data.aws_caller_identity.current.account_id]
    }
  }
  statement {
    sid = "Allow direct access to key metadata to the account"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_kms_alias" "ebs" {
  target_key_id = aws_kms_key.ebs.key_id
  name = "alias/${var.cluster_name}-ebs"
}
