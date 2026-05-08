# Azure Machine Learning Registry with Terraform

このリポジトリは、Azure Machine Learning Registry を Terraform で構築する最小構成です。

`azurerm` provider には Azure Machine Learning Registry 専用リソースがまだ用意されていないため、`azapi_resource` を使って ARM リソース `Microsoft.MachineLearningServices/registries@2025-12-01` を作成します。

## 構成

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

## 作成されるリソース

- Azure Resource Group
- Azure Machine Learning Registry

Registry が利用する system-created Storage Account / Azure Container Registry は、Azure Machine Learning が作成・利用します。AzAPI で Registry を作る場合は各リージョンに Storage/ACR 詳細が必要なため、このモジュールは既定で名前と SKU を生成して `regionDetails` に含めます。名前や SKU を明示したい場合は `replication_locations` で上書きできます。

## 前提条件

- Terraform `>= 1.6.0`
- Azure CLI で対象サブスクリプションにログイン済み
- 対象サブスクリプションまたは Resource Group への `Contributor` 以上の権限
- Azure resource provider `Microsoft.MachineLearningServices` が登録済み

この構成では、制限付き権限の環境でも `terraform plan` が不要な Resource Provider 登録で止まらないよう、`azurerm` provider の `resource_provider_registrations` を `none` にしています。そのため、必要な resource provider は事前に明示登録してください。

`Microsoft.MachineLearningServices` が未登録の場合は、登録権限を持つアカウントで以下を実行します。

```bash
az provider register --namespace Microsoft.MachineLearningServices
az provider show --namespace Microsoft.MachineLearningServices --query registrationState -o tsv
```

## 使い方

サンプル変数ファイルをコピーします。

```bash
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` の値を環境に合わせて変更します。

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

Terraform を初期化・検証・実行します。

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

`terraform.tfvars` を作成しない場合は、`terraform plan` 時に `registry_name` の入力を求められます。非対話で実行したい場合は `terraform.tfvars` を作成するか、`-var 'registry_name=<name>'` のように指定してください。

## 単一リージョン構成

`replication_locations = null` の場合、`location` と同じリージョンだけを使う単一リージョン構成になります。

```hcl
location              = "japaneast"
replication_locations = null
```

## 複数リージョン構成

複数リージョンにする場合は、primary location を含めて `replication_locations` を指定します。

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

Azure Machine Learning Registry は primary location を作成後に変更できません。リージョン設計は、今ある workspace と今後追加予定の workspace の場所を踏まえて決めるのがおすすめです。

## Storage / ACR 設定を指定する例

通常は指定不要です。指定しない場合、モジュールが Registry 名・リージョン・Resource Group ID から system-created Storage / ACR 名を生成し、Storage は `Standard_LRS`、ACR は `Premium` を使います。

必要な場合のみ、各 replication location に system-created Storage / ACR の設定を追加します。

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

明示的な名前を指定する場合は、Azure の命名制約に注意してください。

```hcl
replication_locations = [
  {
    location             = "japaneast"
    storage_account_name = "stmlregdev001"
    acr_name             = "acrmlregdev001"
  }
]
```

自動生成名が既存リソースと衝突した場合も、同じように `storage_account_name` と `acr_name` を明示指定してください。

## Public Network Access

既定は `Enabled` です。

```hcl
public_network_access = "Enabled"
```

本番の閉域構成では `Disabled` にしたうえで Private Endpoint / Private DNS / VNet 連携を追加する構成を推奨します。このリポジトリではまず最小構成に絞り、Private Endpoint は後続拡張の想定です。

## User-assigned managed identity

既定は system-assigned managed identity です。

```hcl
identity_type = "SystemAssigned"
identity_ids  = []
```

User-assigned identity を使う場合は、既存 identity の ARM ID を指定します。

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

`discovery_url` と `mlflow_registry_uri` は Azure Machine Learning から返される値です。作成前の `plan` では unknown になります。

## 注意点

- Registry 名は Microsoft Entra tenant 内で一意にする必要があります。
- Registry 名は作成後に変更できません。
- primary location は作成後に変更できません。
- AzAPI 作成では各 `regionDetails` に Storage/ACR 詳細が必要です。このモジュールは既定値を生成して 400 `Neither StorageAccountDetails nor AcrAccountDetails is provided` を避けます。
- Azure Machine Learning Registry が新規作成する system-created ACR の SKU は `Premium` のみサポートされます。
- `Microsoft.MachineLearningServices` resource provider の登録が必要です。
- `azurerm` provider の自動 Resource Provider 登録は無効化しています。`Microsoft.AppConfiguration` など、この構成に不要な provider 登録で `plan` が止まることを避けるためです。
- Terraform state には Azure リソース ID などが保存されます。チーム利用では Azure Storage backend などの remote backend と state lock の導入を推奨します。

## 今後の拡張候補

- Azure Storage backend による Terraform state 管理
- Private Endpoint / Private DNS による閉域構成
- 既存 Resource Group を参照する構成
- CI/CD での `terraform fmt` / `validate` / `plan`
- Azure RBAC role assignment for registry asset readers/writers
