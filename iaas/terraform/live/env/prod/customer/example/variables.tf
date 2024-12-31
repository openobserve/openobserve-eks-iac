variable "cluster_name" {
  description = "EKS cluster name"
  default     = "o2"
}

variable "region" {
  description = "AWS Region"
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  default     = "10.1.0.0/16"
}

variable "node_instance_type" {
  description = "Instance type for managed node group"
  default     = "m7g.xlarge"
}

variable "node_min_size" {
  description = "Minimum size of the managed node group"
  default     = 2
}

variable "node_max_size" {
  description = "Maximum size of the managed node group"
  default     = 4
}

variable "desired_capacity" {
  description = "Desired capacity for the managed node group"
  default     = 2
}

variable "bucket_prefix" {
  description = "Prefix for the S3 bucket"
  default     = "openobserve"
}

variable "customer_name" {
  description = "Name of the customer"
  default     = "o2-is-best"
}

variable "random_number" {
  description = "Random number for bucket name"
  default     = 12345
}

variable "db_username" {
  description = "Database admin username"
  default     = "openobserve"
}

variable "root_user_email" {
  description = "The root user email for OpenObserve"
  default     = "admin@example.com"
}

variable "root_user_password" {
  description = "The root user password for OpenObserve"
  default     = "SuperSecurePassword123"
}

variable "o2_domain" {
  description = "The main domain for OpenObserve"
  default     = "example.openobserve.ai"
}

variable "o2_dex_domain" {
  description = "The DEX domain for OpenObserve"
  default     = "example-auth.openobserve.ai"
}

variable "secret_name" {
  description = "The secrets for OpenObserve"
  default     = "test-secret"
}