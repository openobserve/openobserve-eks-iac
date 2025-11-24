# Centralized tagging configuration for AWS resources
# This ensures consistent tagging across all resources as per organizational standards

locals {
  # Common tags applied to ALL resources
  common_tags = {
    Customer       = var.customer_tag
    Environment    = var.environment
    Project        = var.project_name
    ContactAddress = var.contact_address
  }

  # Resource-specific tags
  storage_tags = merge(local.common_tags, {
    DataClassification = "confidential"
  })

  database_tags = merge(local.common_tags, {
    DataClassification = "confidential"
    Offhours          = "Off"
  })

  compute_tags = merge(local.common_tags, {
    Offhours = "Off"
  })

  # Kubernetes labels for resources
  kubernetes_labels = {
    team    = "observability"
    project = "OpenObserve"
  }
}
