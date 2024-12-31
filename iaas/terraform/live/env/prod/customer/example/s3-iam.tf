data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "openobserve_bucket" {
  bucket = "${var.bucket_prefix}-${var.random_number}"
}

resource "aws_iam_policy" "openobserve_policy" {
  name        = "OpenObservePolicy-${var.customer_name}"
  description = "Policy for OpenObserve S3 bucket access"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.openobserve_bucket.bucket}/*",
        "arn:aws:s3:::${aws_s3_bucket.openobserve_bucket.bucket}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "openobserve_eks_policy" {
  name        = "OpenObserve_EKS_Policy-${var.customer_name}"
  description = "Policy for OpenObserve secrets in AWS secrets manager"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue",
                "secretsmanager:ListSecrets"
            ],
            "Resource": "arn:aws:secretsmanager:*:*:secret:*o2*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "openobserve_role" {
  name               = "OpenObserveRole-${var.customer_name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${module.eks.oidc_provider_arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${module.eks.oidc_provider}:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "openobserve_policy_attach" {
  role       = aws_iam_role.openobserve_role.name
  policy_arn = aws_iam_policy.openobserve_policy.arn
}

output "role_arn" {
  value = aws_iam_role.openobserve_role.arn
}
