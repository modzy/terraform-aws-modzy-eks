variable "aws_region" {
  default = "us-east-1"
  type = string
}

variable "aws_profile" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_endpoint_public_access" {
  type = bool
}

variable "cluster_endpoint_public_access_cidrs" {
  type = list(string)
}

variable "k8s_version" {
  default = "1.21"
  type = string
}

variable "management_cidrs" {
  type = list(string)
}

variable "enable_monitoring"  {
  type = bool
  default = true
}

variable "tags" {
  type = map(string)
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "admin_role_arn" {
  type = string
}

//variable "secrets_encryption_key_arn" {
//  type = string
//}

variable "ec2_keypair_name" {
  type = string
}

variable "cluster_autoscaler_namespace" {
  type = string
  default = "kube-system"
}
variable "cluster_autoscaler_serviceaccount_name" {
  type = string
  default = "cluster-autoscaler"
}

variable "node_groups" {
  type = list(any)
  default = []
}

