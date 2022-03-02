
locals {
  tags = merge(var.tags, {
    "ModzyInstallation": var.cluster_name
  })
}
