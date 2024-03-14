

# add deployment slot to web app
resource "azurerm_windows_web_app_slot" "staging" {
  name           = "staging"
  app_service_id = azurerm_windows_web_app.mywebapp123dd2.id

  site_config {
    always_on = false
    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v6.0"
    }
  }
}

# add source control to deployment slot
# resource "azurerm_app_service_source_control" "staging" {
#   app_id                 = azurerm_windows_web_app_slot.staging.id
#   repo_url               = "some_repo_url_here"
#   branch                 = "master"
#   use_manual_integration = true
# }
