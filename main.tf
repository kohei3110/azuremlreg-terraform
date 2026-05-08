resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "aml_registry" {
  source = "./modules/aml-registry"

  name                               = var.registry_name
  location                           = var.location
  resource_group_id                  = azurerm_resource_group.this.id
  replication_locations              = var.replication_locations
  public_network_access              = var.public_network_access
  managed_resource_group_resource_id = var.managed_resource_group_resource_id
  identity_type                      = var.identity_type
  identity_ids                       = var.identity_ids
  tags                               = var.tags
}
