
resource "helm_release" "aws_node_termination_handler" {
  depends_on = [module.eks]
  repository = "https://aws.github.io/eks-charts"
  chart = "aws-node-termination-handler"
  version = "0.15.0"
  namespace = "kube-system"
  name = "aws-node-termination-handler"
  recreate_pods = true
  force_update = true
  set {
    name = "enableSpotInterruptionDraining"
    value = "true"
  }
  set {
    name = "enableScheduledEventDraining"
    value = "false"
  }
  set {
    name = "deleteLocalData"
    value = "true"
  }
  set {
    name = "ignoreDaemonSets"
    value = "true"
  }
}
