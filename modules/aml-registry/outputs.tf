output "id" {
  description = "ARM resource ID of the Azure Machine Learning Registry."
  value       = azapi_resource.this.id
}

output "name" {
  description = "Name of the Azure Machine Learning Registry."
  value       = azapi_resource.this.name
}

output "location" {
  description = "Primary Azure region of the Azure Machine Learning Registry."
  value       = azapi_resource.this.location
}

output "discovery_url" {
  description = "Discovery URL returned by Azure Machine Learning for the registry."
  value       = try(azapi_resource.this.output.properties.discoveryUrl, null)
}

output "mlflow_registry_uri" {
  description = "MLflow Registry URI returned by Azure Machine Learning for the registry."
  value       = try(azapi_resource.this.output.properties.mlFlowRegistryUri, null)
}

output "region_details" {
  description = "Region details returned by Azure Machine Learning for the registry."
  value       = try(azapi_resource.this.output.properties.regionDetails, null)
}
