resource "aws_iam_role_policy_attachment" "eks_node_policy_attachment" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_registry_policy_attachment" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_image_builder_policy_attachment" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "eks_auto_scaler_policy_attachment" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
}

resource "aws_iam_role_policy_attachment" "eks_amazon_ssm_managed_instance_core" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "eks_cloudwatch_policy_attachment" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_policy" "AmazonEBSCSIDriverPolicy" {
  name        = "AmazonEBSCSIDriverPolicy"
  description = "Provides permissions for the EBS CSI driver to manage Amazon EBS volumes."
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ec2:CreateSnapshot",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:ModifyVolume",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:CreateVolume",
          "ec2:DeleteVolume"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_ebs_policy_attachment" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = aws_iam_policy.AmazonEBSCSIDriverPolicy.arn
}


resource "aws_iam_role_policy_attachment" "eks_cert_manager_policy_attachment" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess"
}

resource "aws_iam_role_policy_attachment" "eks_external_dns_policy_attachment" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
}

# Define the inline policy for ALB with detailed conditions
resource "aws_iam_role_policy" "alb_inline_policy" {
  name   = "eks-alb-inline-policy"
  role   = aws_iam_role.eks_node_group_role.name
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": ["iam:CreateServiceLinkedRole"],
        "Resource": "*",
        "Condition": {
          "StringEquals": {
            "iam:AWSServiceName": "elasticloadbalancing.amazonaws.com"
          }
        }
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeCoipPools",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:GetSubscriptionState",
          "shield:DescribeProtection",
          "shield:CreateProtection",
          "shield:DeleteProtection"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": ["ec2:AuthorizeSecurityGroupIngress", "ec2:RevokeSecurityGroupIngress"],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": ["ec2:CreateSecurityGroup"],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": ["ec2:CreateTags"],
        "Resource": "arn:aws:ec2:*:*:security-group/*",
        "Condition": {
          "StringEquals": { "ec2:CreateAction": "CreateSecurityGroup" },
          "Null": { "aws:RequestTag/elbv2.k8s.aws/cluster": "false" }
        }
      },
      {
        "Effect": "Allow",
        "Action": ["ec2:CreateTags", "ec2:DeleteTags"],
        "Resource": "arn:aws:ec2:*:*:security-group/*",
        "Condition": {
          "Null": {
            "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
            "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
          }
        }
      },
      {
        "Effect": "Allow",
        "Action": ["ec2:AuthorizeSecurityGroupIngress", "ec2:RevokeSecurityGroupIngress", "ec2:DeleteSecurityGroup"],
        "Resource": "*",
        "Condition": {
          "Null": { "aws:ResourceTag/elbv2.k8s.aws/cluster": "false" }
        }
      },
      {
        "Effect": "Allow",
        "Action": ["elasticloadbalancing:CreateLoadBalancer", "elasticloadbalancing:CreateTargetGroup"],
        "Resource": "*",
        "Condition": {
          "Null": { "aws:RequestTag/elbv2.k8s.aws/cluster": "false" }
        }
      },
      {
        "Effect": "Allow",
        "Action": ["elasticloadbalancing:CreateListener", "elasticloadbalancing:DeleteListener", "elasticloadbalancing:CreateRule", "elasticloadbalancing:DeleteRule"],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": ["elasticloadbalancing:AddTags", "elasticloadbalancing:RemoveTags"],
        "Resource": [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ],
        "Condition": {
          "Null": {
            "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
            "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
          }
        }
      },
      {
        "Effect": "Allow",
        "Action": ["elasticloadbalancing:AddTags", "elasticloadbalancing:RemoveTags"],
        "Resource": [
          "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup"
        ],
        "Resource": "*",
        "Condition": {
          "Null": { "aws:ResourceTag/elbv2.k8s.aws/cluster": "false" }
        }
      },
      {
        "Effect": "Allow",
        "Action": ["elasticloadbalancing:AddTags"],
        "Resource": [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ],
        "Condition": {
          "StringEquals": {
            "elasticloadbalancing:CreateAction": [
              "CreateTargetGroup",
              "CreateLoadBalancer"
            ]
          },
          "Null": { "aws:RequestTag/elbv2.k8s.aws/cluster": "false" }
        }
      },
      {
        "Effect": "Allow",
        "Action": ["elasticloadbalancing:RegisterTargets", "elasticloadbalancing:DeregisterTargets"],
        "Resource": "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "elasticloadbalancing:SetWebAcl",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:ModifyRule"
        ],
        "Resource": "*"
      }
    ]
  })
}

