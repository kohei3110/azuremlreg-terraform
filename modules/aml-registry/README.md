# Azure Machine Learning Registry module

This module creates an Azure Machine Learning Registry by using the AzAPI provider and the ARM resource type `Microsoft.MachineLearningServices/registries@2025-12-01`.

## Minimal usage

```hcl
module "aml_registry" {
  source = "./modules/aml-registry"

  name              = "contoso-mlreg-dev"
  location          = "japaneast"
  resource_group_id = azurerm_resource_group.this.id
}
```

By default, the module creates a single-region registry in `location`. Azure Machine Learning creates the system-created storage and Azure Container Registry resources, but the AzAPI request must still include Storage/ACR details in `regionDetails`. This module therefore generates deterministic default names and SKUs when you do not provide them.

## Multi-region usage

```hcl
module "aml_registry" {
  source = "./modules/aml-registry"

  name              = "contoso-mlreg-dev"
  location          = "japaneast"
  resource_group_id = azurerm_resource_group.this.id

  replication_locations = [
    {
      location = "japaneast"
    },
    {
      location = "eastus"
    }
  ]
}
```

The primary `location` must be included in `replication_locations`.

## Optional storage configuration

```hcl
replication_locations = [
  {
    location                    = "japaneast"
    storage_account_type        = "Standard_LRS"
    storage_account_hns_enabled = false
  }
]
```

Use `storage_account_name` and `acr_name` only when you need specific names or when an automatically generated name collides with an existing Azure resource. Otherwise, leave them unset and let the module generate names.

Default generated settings per replication location:

- `storageAccountName`: generated from registry name, location, resource group ID hash
- `storageAccountType`: `Standard_LRS`
- `storageAccountHnsEnabled`: `false`
- `allowBlobPublicAccess`: `false`
- `acrAccountName`: generated from registry name, location, resource group ID hash
- `acrAccountSku`: `Premium`

Azure Machine Learning Registry only supports `Premium` for new system-created ACRs. Supplying `Basic` or `Standard` will fail during apply.

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `name` | `string` | n/a | Azure Machine Learning Registry name. |
| `location` | `string` | n/a | Primary Azure region. |
| `resource_group_id` | `string` | n/a | ARM ID of the target resource group. |
| `replication_locations` | `list(object)` | `null` | Optional replication locations. Defaults to a single entry for `location`. |
| `public_network_access` | `string` | `Enabled` | `Enabled` or `Disabled`. |
| `managed_resource_group_resource_id` | `string` | `null` | Optional managed resource group ARM ID. |
| `identity_type` | `string` | `SystemAssigned` | Managed identity type. |
| `identity_ids` | `list(string)` | `[]` | User-assigned identity IDs when applicable. |
| `tags` | `map(string)` | `{}` | Tags applied to the registry. |

## Outputs

| Name | Description |
| --- | --- |
| `id` | Registry ARM resource ID. |
| `name` | Registry name. |
| `location` | Registry primary location. |
| `discovery_url` | Registry discovery URL returned by Azure Machine Learning. |
| `mlflow_registry_uri` | MLflow Registry URI returned by Azure Machine Learning. |
| `region_details` | Region details returned by Azure Machine Learning. |
