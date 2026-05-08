variable "resource_group_name" {
  description = "Name of the Azure resource group that will contain the Azure Machine Learning Registry."
  type        = string
  default     = "rg-aml-registry-demo"

  validation {
    condition     = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90
    error_message = "resource_group_name must be between 1 and 90 characters."
  }
}

variable "location" {
  description = "Primary Azure region for the Azure Machine Learning Registry. Use the canonical location name, for example japaneast or eastus."
  type        = string
  default     = "japaneast"

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.location))
    error_message = "location must be an Azure location name without spaces, for example japaneast or eastus."
  }
}

variable "registry_name" {
  description = "Name of the Azure Machine Learning Registry. Registry names are tenant-wide and cannot be changed after creation."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9_-]{2,32}$", var.registry_name))
    error_message = "registry_name must start with an alphanumeric character and then contain only alphanumeric characters, hyphens, or underscores. The total length must be 3 to 33 characters."
  }
}

variable "replication_locations" {
  description = <<DESCRIPTION
Optional list of registry replication locations. Leave as null for a single-region registry in var.location.
Each item can optionally include storage or ACR settings for system-created resources in that region.
DESCRIPTION
  type = list(object({
    location                    = string
    storage_account_name        = optional(string)
    storage_account_type        = optional(string)
    storage_account_hns         = optional(bool)
    storage_account_hns_enabled = optional(bool)
    allow_blob_public_access    = optional(bool)
    acr_name                    = optional(string)
    acr_sku                     = optional(string)
  }))
  default = null

  validation {
    condition     = var.replication_locations == null ? true : length(var.replication_locations) > 0
    error_message = "replication_locations must be null or contain at least one location."
  }

  validation {
    condition = var.replication_locations == null ? true : alltrue([
      for replication in var.replication_locations :
      try(replication.acr_sku, null) == null ? true : replication.acr_sku == "Premium"
    ])
    error_message = "acr_sku must be null or Premium. Azure Machine Learning Registry only supports Premium for new system-created ACRs."
  }
}

variable "public_network_access" {
  description = "Whether public network access is enabled for the registry. Use Enabled or Disabled."
  type        = string
  default     = "Enabled"

  validation {
    condition     = contains(["enabled", "disabled"], lower(var.public_network_access))
    error_message = "public_network_access must be Enabled or Disabled."
  }
}

variable "managed_resource_group_resource_id" {
  description = "Optional ARM resource ID of the managed resource group used for system-created registry resources. Leave null to let Azure Machine Learning manage it."
  type        = string
  default     = null

  validation {
    condition     = var.managed_resource_group_resource_id == null || can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+$", var.managed_resource_group_resource_id))
    error_message = "managed_resource_group_resource_id must be null or a resource group ARM ID like /subscriptions/<subscription-id>/resourceGroups/<name>."
  }
}

variable "identity_type" {
  description = "Managed identity type for the registry."
  type        = string
  default     = "SystemAssigned"

  validation {
    condition     = contains(["None", "SystemAssigned", "UserAssigned", "SystemAssigned,UserAssigned"], var.identity_type)
    error_message = "identity_type must be one of None, SystemAssigned, UserAssigned, or SystemAssigned,UserAssigned."
  }
}

variable "identity_ids" {
  description = "User-assigned managed identity resource IDs. Required when identity_type is UserAssigned or SystemAssigned,UserAssigned."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources created by this configuration."
  type        = map(string)
  default = {
    workload = "azure-machine-learning-registry"
  }
}
