# Output values for EKS
output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_arn" {
  value = module.eks.cluster_arn
}

output "eks_node_group_name" {
  value = aws_eks_node_group.managed_node_group.node_group_name
}

output "s3_bucket_name" {
  value = aws_s3_bucket.openobserve_bucket.bucket
}

output "iam_role_arn" {
  value = aws_iam_role.openobserve_role.arn
}

output "rds_instance_endpoint" {
  value = aws_db_instance.openobserve_rds.endpoint
}

output "rds_db_password" {
  value = random_password.db_password.result
  sensitive = true
}