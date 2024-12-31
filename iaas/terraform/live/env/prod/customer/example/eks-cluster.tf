module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  cidr    = var.vpc_cidr
  azs     = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.4.0/24"]
  public_subnets  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
}

resource "aws_eip" "nat_eip" {
  #domain = vpc
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = module.vpc.public_subnets[0]  # Create the NAT Gateway in the first public subnet
}

resource "aws_route" "private_route_to_nat" {
  count          = length(module.vpc.private_subnets)
  route_table_id = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_gateway.id
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version = "18.31.0"
  cluster_name    = var.cluster_name
  cluster_version = "1.30"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = concat(module.vpc.public_subnets, module.vpc.private_subnets)
  enable_irsa     = true
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access_cidrs    = ["0.0.0.0/0"]
}

# Retrieve EKS Cluster Information to get the OIDC URL
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

# IAM Role for EBS CSI Driver with IRSA
resource "aws_iam_role" "ebs_csi_driver_role" {
  name = "AmazonEKS_EBS_CSI_Driver_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = module.eks.oidc_provider_arn  # Use the OIDC issuer ARN from the data source
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            #"${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller"
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Attach AmazonEBSCSIDriverPolicy to the IAM Role
resource "aws_iam_role_policy_attachment" "attach_ebs_csi_driver_policy" {
  role       = aws_iam_role.ebs_csi_driver_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# EKS Add-ons
resource "aws_eks_addon" "aws_ebs_csi_driver" {
  cluster_name              = module.eks.cluster_name
  addon_name                = "aws-ebs-csi-driver"
  service_account_role_arn  = aws_iam_role.ebs_csi_driver_role.arn 
}

# IAM Role for VPC CNI with IRSA
resource "aws_iam_role" "vpc_cni_role" {
  name = "AmazonEKS_VPC_CNI_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = module.eks.oidc_provider_arn 
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:aws-node",
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Attach AmazonEKS_CNI_Policy to the IAM Role
resource "aws_iam_role_policy_attachment" "attach_vpc_cni_policy" {
  role       = aws_iam_role.vpc_cni_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# EKS Add-on for VPC CNI
resource "aws_eks_addon" "vpc_cni" {
  cluster_name              = module.eks.cluster_name
  addon_name                = "vpc-cni"
  service_account_role_arn  = aws_iam_role.vpc_cni_role.arn  
}


resource "aws_iam_role" "eks_node_group_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_eks_node_group" "managed_node_group" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "m7g"  # Graviton instance type
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = module.vpc.private_subnets

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  instance_types = [var.node_instance_type]
  ami_type       = "AL2023_ARM_64_STANDARD"  # For Graviton instances
  disk_size      = 20 # 20 GB

  labels = {
    "purpose" = "OpenObserve"
  }

  tags = {
    "Environment" = "production"
    "Name"        = "${var.customer_name}"
  }
  
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = module.eks.cluster_name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "coredns" {
  cluster_name = module.eks.cluster_name
  addon_name   = "coredns"
}