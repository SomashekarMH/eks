output "cluster_id" {
  value = aws_eks_cluster.somu-cluster.id
}

output "node_group_id" {
  value = aws_eks_node_group.somu-node-group.id
}

output "vpc_id" {
  value = aws_vpc.somu-project.id
}

