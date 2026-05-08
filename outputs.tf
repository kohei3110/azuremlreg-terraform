output "resource_group_id" {
  description = "ARM resource ID of the resource group containing the Azure Machine Learning Registry."
  value       = azurerm_resource_group.this.id
}

output "registry_id" {
  description = "ARM resource ID of the Azure Machine Learning Registry."
  value       = module.aml_registry.id
}

output "registry_name" {
  description = "Name of the Azure Machine Learning Registry."
  value       = module.aml_registry.name
}

output "registry_location" {
  description = "Primary Azure region of the Azure Machine Learning Registry."
  value       = module.aml_registry.location
}

output "discovery_url" {
  description = "Discovery URL returned by Azure Machine Learning for the registry."
  value       = module.aml_registry.discovery_url
}

output "mlflow_registry_uri" {
  description = "MLflow Registry URI returned by Azure Machine Learning for the registry."
  value       = module.aml_registry.mlflow_registry_uri
}
