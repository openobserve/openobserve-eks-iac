resource "local_file" "values_yaml" {
  filename = "./o2-eks/values.yaml"
  content  = templatefile("./o2-eks/values.yaml.j2", {
    root_user_email    = var.root_user_email
    root_user_password = var.root_user_password
    postgres_dsn       = aws_db_instance.openobserve_rds.endpoint
    s3_bucket_name     = aws_s3_bucket.openobserve_bucket.bucket
    s3_region_name     = aws_s3_bucket.openobserve_bucket.region
    iam_role_arn       = aws_iam_role.openobserve_role.arn
    o2_dex_domain      = var.o2_dex_domain
    o2_domain          = var.o2_domain
    rds_db_password    = random_password.db_password.result
  })
}

resource "local_file" "external_secrets_yaml" {
  filename = "./o2-eks/external-secrets.yaml"
  content  = templatefile("./o2-eks/external-secrets.yaml.j2", {
    secret_name    = var.secret_name
  })
}