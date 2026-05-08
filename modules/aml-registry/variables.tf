variable "name" {
  description = "Name of the Azure Machine Learning Registry."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9_-]{2,32}$", var.name))
    error_message = "name must start with an alphanumeric character and then contain only alphanumeric characters, hyphens, or underscores. The total length must be 3 to 33 characters."
  }
}

variable "location" {
  description = "Primary Azure region for the Azure Machine Learning Registry."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.location))
    error_message = "location must be an Azure location name without spaces, for example japaneast or eastus."
  }
}

variable "resource_group_id" {
  description = "ARM resource ID of the resource group that will contain the registry."
  type        = string

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+$", var.resource_group_id))
    error_message = "resource_group_id must be a resource group ARM ID like /subscriptions/<subscription-id>/resourceGroups/<name>."
  }
}

variable "replication_locations" {
  description = <<DESCRIPTION
Optional list of registry replication locations. Leave as null for a single-region registry in var.location.
The primary location must be included when you provide this list.
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
      for replication in var.replication_locations : can(regex("^[a-z0-9]+$", replication.location))
    ])
    error_message = "Each replication location must be an Azure location name without spaces, for example japaneast or eastus."
  }

  validation {
    condition = var.replication_locations == null ? true : length(distinct([
      for replication in var.replication_locations : lower(replication.location)
    ])) == length(var.replication_locations)
    error_message = "replication_locations must not contain duplicate locations."
  }

  validation {
    condition = var.replication_locations == null ? true : alltrue([
      for replication in var.replication_locations :
      try(replication.storage_account_name, null) == null ? true : can(regex("^[a-z0-9]{3,24}$", replication.storage_account_name))
    ])
    error_message = "storage_account_name must be null or 3 to 24 lowercase alphanumeric characters."
  }

  validation {
    condition = var.replication_locations == null ? true : alltrue([
      for replication in var.replication_locations :
      try(replication.storage_account_type, null) == null ? true : contains([
        "Standard_LRS",
        "Standard_GRS",
        "Standard_RAGRS",
        "Standard_ZRS",
        "Standard_GZRS",
        "Standard_RAGZRS",
        "Premium_LRS",
        "Premium_ZRS"
      ], replication.storage_account_type)
    ])
    error_message = "storage_account_type must be null or one of the supported Azure Storage account types."
  }

  validation {
    condition = var.replication_locations == null ? true : alltrue([
      for replication in var.replication_locations :
      try(replication.acr_name, null) == null ? true : can(regex("^[A-Za-z0-9]{5,50}$", replication.acr_name))
    ])
    error_message = "acr_name must be null or 5 to 50 alphanumeric characters."
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
  description = "Optional ARM resource ID of the managed resource group used for system-created registry resources."
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
  description = "Tags to apply to the registry."
  type        = map(string)
  default     = {}
}
