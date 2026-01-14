output "id" {
  description = "ID of the Azure OpenAI service"
  value       = azurerm_cognitive_account.openai.id
}

output "endpoint" {
  description = "Endpoint URL of the Azure OpenAI service"
  value       = azurerm_cognitive_account.openai.endpoint
}

output "primary_key" {
  description = "Primary access key for Azure OpenAI"
  value       = azurerm_cognitive_account.openai.primary_access_key
  sensitive   = true
}

output "name" {
  description = "Name of the Azure OpenAI service"
  value       = azurerm_cognitive_account.openai.name
}

output "gpt4o_deployment_name" {
  description = "Name of the GPT-4o deployment"
  value       = azurerm_cognitive_deployment.gpt4o.name
}

output "gpt4_turbo_deployment_name" {
  description = "Name of the GPT-4 Turbo deployment"
  value       = azurerm_cognitive_deployment.gpt4_turbo.name
}

output "embedding_deployment_name" {
  description = "Name of the text embedding deployment"
  value       = azurerm_cognitive_deployment.text_embedding.name
}
