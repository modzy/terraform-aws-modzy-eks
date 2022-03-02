
resource "kubernetes_daemonset" "nvidia_device_plugin" {
  depends_on = [module.eks]
  metadata {
    namespace = "kube-system"
    name = "nvidia-device-plugin-daemonset"
  }
  spec {
    selector {
      match_labels = {
        name = "nvidia-device-plugin-ds"
      }
    }
    strategy {
      type = "RollingUpdate"
    }
    template {
      metadata {
        annotations = {
          # This annotation is deprecated. Kept here for backward compatibility.
          # See https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/
          "scheduler.alpha.kubernetes.io/critical-pod" = ""
        }
        labels = {
          name = "nvidia-device-plugin-ds"
        }
      }
      spec {
        # This toleration is deprecated. Kept here for backward compatibility
        # See https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/
        toleration {
          key = "CriticalAddonsOnly"
          operator = "Exists"
        }
        toleration {
          key = "nvidia.com/gpu"
          operator = "Exists"
          effect = "NoSchedule"
        }
        toleration {
          key = "modzy.com/inference-node"
          operator = "Exists"
          effect = "NoSchedule"
        }
        # Mark this pod as a critical add-on; when enabled, the critical add-on
        # scheduler reserves resources for critical add-on pods so that they can
        # be rescheduled after a failure.
        # See https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/
        priority_class_name = "system-node-critical"
        container {
          name = "nvidia-device-plugin-ctr"
          image = "nvidia/k8s-device-plugin:1.0.0-beta4"
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
          }
          volume_mount {
            name = "device-plugin"
            mount_path = "/var/lib/kubelet/device-plugins"
          }
        }
        volume {
          name = "device-plugin"
          host_path {
            path = "/var/lib/kubelet/device-plugins"
          }
        }
      }
    }
  }
}
