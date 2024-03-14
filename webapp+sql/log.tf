resource "azurerm_log_analytics_workspace" "example" {
  name                = "workspace-test523324"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_application_insights" "example" {
  name                = "tf-test-appinsights7634623"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.example.id
  application_type    = "web"

  depends_on = [azurerm_log_analytics_workspace.example,
  azurerm_resource_group.rg]
}



output "instrumentation_key" {
  sensitive = true
  value     = azurerm_application_insights.example.instrumentation_key
}

output "app_id" {
  value = azurerm_application_insights.example.app_id
}

# output the connection string for application insights 
output "connection_string" {
  sensitive = true
  value     = azurerm_application_insights.example.connection_string
}
