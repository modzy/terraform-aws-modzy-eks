
locals {
  cluster_autoscaler_labels = {
    k8s-addon = "cluster-autoscaler.addons.k8s.io"
    k8s-app = var.cluster_autoscaler_serviceaccount_name
  }
  cluster_autoscaler_version_map = {
    "1.19" = "v1.19.1"
    "1.21"  = "v1.21.1"
  }
}

resource "kubernetes_service_account" "cluster-autoscaler" {
  depends_on = [module.eks]
  metadata {
    namespace = var.cluster_autoscaler_namespace
    name = var.cluster_autoscaler_serviceaccount_name
    labels = local.cluster_autoscaler_labels
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam_assumable_role.iam_role_arn
    }
  }
}

resource "kubernetes_cluster_role" "cluster-autoscaler" {
  depends_on = [module.eks]
  metadata {
    name = var.cluster_autoscaler_serviceaccount_name
    labels = local.cluster_autoscaler_labels
  }
  rule {
    api_groups = [""]
    resources = ["events", "endpoints"]
    verbs = ["create", "patch"]
  }
  rule {
    api_groups = [""]
    resources = ["pods/eviction"]
    verbs = ["create"]
  }
  rule {
    api_groups = [""]
    resources = ["pods/status"]
    verbs = ["update"]
  }
  rule {
    api_groups = [""]
    resources = ["endpoints"]
    resource_names = [var.cluster_autoscaler_serviceaccount_name]
    verbs = ["get", "update"]
  }
  rule {
    api_groups = [""]
    resources = ["nodes"]
    verbs = ["watch", "list", "get", "update"]
  }
  rule {
    api_groups = [""]
    resources = [
      "pods",
      "services",
      "replicationcontrollers",
      "persistentvolumeclaims",
      "persistentvolumes"
    ]
    verbs = ["watch", "list", "get"]
  }
  rule {
    api_groups = ["extensions"]
    resources = ["replicasets", "daemonsets"]
    verbs = ["watch", "list", "get"]
  }
  rule {
    api_groups = ["policy"]
    resources = ["poddisruptionbudgets"]
    verbs = ["watch", "list"]
  }
  rule {
    api_groups = ["apps"]
    resources = ["statefulsets", "replicasets", "daemonsets"]
    verbs = ["watch", "list", "get"]
  }
  rule {
    api_groups = ["storage.k8s.io"]
    resources = ["storageclasses", "csinodes"]
    verbs = ["watch", "list", "get"]
  }
  rule {
    api_groups = ["batch", "extensions"]
    resources = ["jobs"]
    verbs = ["get", "list", "watch", "patch"]
  }
  rule {
    api_groups = ["coordination.k8s.io"]
    resources = ["leases"]
    verbs = ["create"]
  }
  rule {
    api_groups = ["coordination.k8s.io"]
    resources = ["leases"]
    resource_names = [var.cluster_autoscaler_serviceaccount_name]
    verbs = ["get", "update"]
  }
}

resource "kubernetes_role" "cluster-autoscaler" {
  depends_on = [module.eks]
  metadata {
    namespace = var.cluster_autoscaler_namespace
    name = var.cluster_autoscaler_serviceaccount_name
    labels = local.cluster_autoscaler_labels
  }
  rule {
    api_groups = [""]
    resources = ["configmaps"]
    verbs = ["create", "list", "watch"]
  }
  rule {
    api_groups = [""]
    resources = ["configmaps"]
    resource_names = ["cluster-autoscaler-status", "cluster-autoscaler-priority-expander"]
    verbs = ["delete", "get", "update", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "cluster-autoscaler" {
  depends_on = [module.eks]
  metadata {
    name = var.cluster_autoscaler_serviceaccount_name
    labels = local.cluster_autoscaler_labels
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = var.cluster_autoscaler_serviceaccount_name
  }
  subject {
    kind = "ServiceAccount"
    namespace = var.cluster_autoscaler_namespace
    name = var.cluster_autoscaler_serviceaccount_name
  }
}

resource "kubernetes_role_binding" "cluster-autoscaler" {
  depends_on = [module.eks]
  metadata {
    namespace = var.cluster_autoscaler_namespace
    name = var.cluster_autoscaler_serviceaccount_name
    labels = local.cluster_autoscaler_labels
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "Role"
    name = var.cluster_autoscaler_serviceaccount_name
  }
  subject {
    kind = "ServiceAccount"
    namespace = var.cluster_autoscaler_namespace
    name = var.cluster_autoscaler_serviceaccount_name
  }
}

resource "kubernetes_deployment" "cluster-autoscaler" {
  depends_on = [module.eks]
  metadata {
    namespace = var.cluster_autoscaler_namespace
    name = var.cluster_autoscaler_serviceaccount_name
    labels = {
      app: var.cluster_autoscaler_serviceaccount_name
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app: var.cluster_autoscaler_serviceaccount_name
      }
    }
    template {
      metadata {
        labels = {
          app = var.cluster_autoscaler_serviceaccount_name
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port" = "8085"
        }
      }
      spec {
        service_account_name = var.cluster_autoscaler_serviceaccount_name
        container {
          name = "cluster-autoscaler"
          image = "k8s.gcr.io/autoscaling/cluster-autoscaler:${local.cluster_autoscaler_version_map[var.k8s_version]}"
          image_pull_policy = "Always"
          resources {
            requests = {
              cpu = "100m"
              memory = "500Mi"
            }
            limits = {
              cpu = "100m"
              memory = "500Mi"
            }
          }
          command = [
            "./cluster-autoscaler",
            "--v=4",
            "--stderrthreshold=info",
            "--cloud-provider=aws",
            "--skip-nodes-with-local-storage=false",
            "--balance-similar-node-groups",
            "--expander=least-waste",
            "--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/${var.cluster_name}"
          ]
          volume_mount {
            name = "ssl-certs"
            mount_path = "/etc/ssl/certs/ca-certificates.crt" #/etc/ssl/certs/ca-bundle.crt for Amazon Linux Worker Nodes
            read_only = true
          }
        }
        volume {
          name = "ssl-certs"
          host_path {
            path = "/etc/ssl/certs/ca-bundle.crt"
          }
        }
      }
    }
  }
}
