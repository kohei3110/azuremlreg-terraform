locals {
  public_network_access = lower(var.public_network_access) == "enabled" ? "Enabled" : "Disabled"
  sanitized_name        = lower(replace(var.name, "/[^0-9A-Za-z]/", ""))

  effective_replication_locations = var.replication_locations != null ? var.replication_locations : [
    {
      location                    = var.location
      storage_account_name        = null
      storage_account_type        = null
      storage_account_hns         = null
      storage_account_hns_enabled = null
      allow_blob_public_access    = null
      acr_name                    = null
      acr_sku                     = null
    }
  ]

  normalized_primary_location = lower(var.location)
  normalized_replication_locations = [
    for replication in local.effective_replication_locations : lower(replication.location)
  ]

  replication_location_configs = [
    for replication in local.effective_replication_locations : {
      location                    = replication.location
      sanitized_location          = lower(replace(replication.location, "/[^0-9A-Za-z]/", ""))
      resource_name_suffix        = substr(sha1("${var.resource_group_id}-${var.name}-${replication.location}"), 0, 8)
      storage_account_name_prefix = substr("st${local.sanitized_name}${lower(replace(replication.location, "/[^0-9A-Za-z]/", ""))}", 0, 16)
      acr_name_prefix             = substr("acr${local.sanitized_name}${lower(replace(replication.location, "/[^0-9A-Za-z]/", ""))}", 0, 42)
      storage_account_name        = try(replication.storage_account_name, null)
      storage_account_type        = try(replication.storage_account_type, null)
      storage_account_hns_enabled = try(coalesce(try(replication.storage_account_hns_enabled, null), try(replication.storage_account_hns, null)), null)
      allow_blob_public_access    = try(replication.allow_blob_public_access, null)
      acr_name                    = try(replication.acr_name, null)
      acr_sku                     = try(replication.acr_sku, null)
    }
  ]

  region_details = [
    for replication in local.replication_location_configs : {
      location = replication.location
      storageAccountDetails = [
        {
          systemCreatedStorageAccount = {
            storageAccountName       = replication.storage_account_name != null ? replication.storage_account_name : "${replication.storage_account_name_prefix}${replication.resource_name_suffix}"
            storageAccountType       = replication.storage_account_type != null ? replication.storage_account_type : "Standard_LRS"
            storageAccountHnsEnabled = replication.storage_account_hns_enabled != null ? replication.storage_account_hns_enabled : false
            allowBlobPublicAccess    = replication.allow_blob_public_access != null ? replication.allow_blob_public_access : false
          }
        }
      ]
      acrDetails = [
        {
          systemCreatedAcrAccount = {
            acrAccountName = replication.acr_name != null ? replication.acr_name : "${replication.acr_name_prefix}${replication.resource_name_suffix}"
            acrAccountSku  = replication.acr_sku != null ? replication.acr_sku : "Premium"
          }
        }
      ]
    }
  ]

  registry_properties = merge(
    {
      publicNetworkAccess = local.public_network_access
      regionDetails       = local.region_details
    },
    var.managed_resource_group_resource_id != null ? {
      managedResourceGroup = {
        resourceId = var.managed_resource_group_resource_id
      }
    } : {}
  )
}

resource "azapi_resource" "this" {
  type      = "Microsoft.MachineLearningServices/registries@2025-12-01"
  name      = var.name
  parent_id = var.resource_group_id
  location  = var.location
  tags      = var.tags

  dynamic "identity" {
    for_each = var.identity_type == "None" ? [] : [var.identity_type]

    content {
      type         = identity.value
      identity_ids = length(var.identity_ids) > 0 ? var.identity_ids : null
    }
  }

  body = {
    properties = local.registry_properties
  }

  response_export_values = [
    "properties.discoveryUrl",
    "properties.mlFlowRegistryUri",
    "properties.regionDetails"
  ]

  lifecycle {
    precondition {
      condition     = contains(local.normalized_replication_locations, local.normalized_primary_location)
      error_message = "replication_locations must include the primary location."
    }

    precondition {
      condition     = !contains(["UserAssigned", "SystemAssigned,UserAssigned"], var.identity_type) || length(var.identity_ids) > 0
      error_message = "identity_ids must contain at least one user-assigned identity ID when identity_type includes UserAssigned."
    }
  }
}
