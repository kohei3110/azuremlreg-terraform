# Azure Machine Learning Registry with Terraform

This repository provides a minimal Terraform configuration for creating an Azure Machine Learning Registry.

The configuration uses `azapi_resource` to create the ARM resource type `Microsoft.MachineLearningServices/registries@2025-12-01`.

## Repository layout

```text
.
├── main.tf
├── outputs.tf
├── providers.tf
├── terraform.tfvars.example
├── variables.tf
├── versions.tf
└── modules
    └── aml-registry
        ├── main.tf
        ├── outputs.tf
        ├── variables.tf
        ├── versions.tf
        └── README.md
```

## Resources created

- Azure Resource Group
- Azure Machine Learning Registry

Azure Machine Learning creates and uses the system-created Storage Account and Azure Container Registry (ACR) resources required by the registry. When a registry is created through AzAPI, each `regionDetails` entry must include Storage/ACR details. This module generates default names and SKUs and includes them in `regionDetails`. If you need explicit names or SKUs, override them through `replication_locations`.

## Prerequisites

- Terraform `>= 1.6.0`
- Azure CLI authenticated to the target subscription
- `Contributor` or higher permissions on the target subscription or resource group
- The Azure resource provider `Microsoft.MachineLearningServices` registered in the target subscription

This configuration sets `resource_provider_registrations` to `none` for the `azurerm` provider so that `terraform plan` does not fail in restricted-permission environments because of automatic resource provider registration attempts. Register the required resource providers explicitly before running Terraform.

If `Microsoft.MachineLearningServices` is not registered, run the following commands with an account that has permission to register resource providers:

```bash
az provider register --namespace Microsoft.MachineLearningServices
az provider show --namespace Microsoft.MachineLearningServices --query registrationState -o tsv
```

## Usage

Copy the sample variable file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` for your environment:

```hcl
resource_group_name = "rg-aml-registry-demo"
location            = "japaneast"
registry_name       = "contoso-mlreg-dev"

replication_locations = null
public_network_access = "Enabled"

identity_type = "SystemAssigned"
identity_ids  = []

managed_resource_group_resource_id = null

tags = {
  environment = "dev"
  workload    = "azure-machine-learning-registry"
}
```

Initialize, validate, and apply the Terraform configuration:

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

If you do not create `terraform.tfvars`, Terraform prompts for `registry_name` during `terraform plan`. For non-interactive runs, create `terraform.tfvars` or pass the value explicitly, for example `-var 'registry_name=<name>'`.

## Single-region configuration

When `replication_locations = null`, the registry is configured as a single-region registry that uses the same region as `location`.

```hcl
location              = "japaneast"
replication_locations = null
```

## Multi-region configuration

To configure multiple regions, set `replication_locations` and include the primary location in the list.

```hcl
location = "japaneast"

replication_locations = [
  {
    location = "japaneast"
  },
  {
    location = "eastus"
  }
]
```

The primary location of an Azure Machine Learning Registry cannot be changed after creation. Choose regions based on the locations of your current workspaces and any workspaces you expect to add later.

## Storage and ACR settings

In most cases, you do not need to specify Storage or ACR settings. If omitted, the module generates system-created Storage/ACR names from the registry name, region, and resource group ID. The default Storage account type is `Standard_LRS`, and the default ACR SKU is `Premium`.

Only add system-created Storage/ACR settings to each replication location when you need to customize them:

```hcl
replication_locations = [
  {
    location                    = "japaneast"
    storage_account_type        = "Standard_LRS"
    storage_account_hns_enabled = false
    allow_blob_public_access    = false
    acr_sku                     = "Premium"
  }
]
```

If you specify explicit names, make sure they meet Azure naming requirements:

```hcl
replication_locations = [
  {
    location             = "japaneast"
    storage_account_name = "stmlregdev001"
    acr_name             = "acrmlregdev001"
  }
]
```

If an automatically generated name conflicts with an existing Azure resource, set `storage_account_name` and `acr_name` explicitly in the same way.

## Public network access

Public network access is enabled by default.

```hcl
public_network_access = "Enabled"
```

For production environments that require private connectivity, set this to `Disabled` and extend the configuration with Private Endpoint, Private DNS, and VNet integration. This repository intentionally focuses on a minimal starting point; private networking can be added as a follow-up enhancement.

## User-assigned managed identity

The default identity configuration uses a system-assigned managed identity.

```hcl
identity_type = "SystemAssigned"
identity_ids  = []
```

To use a user-assigned managed identity, provide the ARM resource ID of an existing identity:

```hcl
identity_type = "UserAssigned"
identity_ids = [
  "/subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<identity-name>"
]
```

## Outputs

- `resource_group_id`
- `registry_id`
- `registry_name`
- `registry_location`
- `discovery_url`
- `mlflow_registry_uri`

`discovery_url` and `mlflow_registry_uri` are values returned by Azure Machine Learning. They are unknown during `terraform plan` before the registry is created.

## Notes

- The registry name must be unique within the Microsoft Entra tenant.
- The registry name cannot be changed after creation.
- The primary location cannot be changed after creation.
- AzAPI registry creation requires Storage/ACR details in each `regionDetails` entry. This module generates defaults to avoid the `400 Neither StorageAccountDetails nor AcrAccountDetails is provided` error.
- Azure Machine Learning Registry supports only `Premium` for newly created system-created ACR resources.
- The `Microsoft.MachineLearningServices` resource provider must be registered before deployment.
- Automatic resource provider registration in the `azurerm` provider is disabled to avoid `plan` failures caused by providers that are not required by this configuration, such as `Microsoft.AppConfiguration`.
- Terraform state stores Azure resource IDs and other deployment metadata. For team usage, use a remote backend such as Azure Storage and enable state locking.

## Possible future enhancements

- Manage Terraform state with an Azure Storage backend
- Add private networking with Private Endpoint and Private DNS
- Support referencing an existing resource group
- Add CI/CD checks for `terraform fmt`, `terraform validate`, and `terraform plan`
- Add Azure RBAC role assignments for registry asset readers and writers
