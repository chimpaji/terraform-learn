
resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = local.location
}

resource "azurerm_service_plan" "example" {
  name                = "example"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku_name            = "S1"
  os_type             = "Windows"

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_windows_web_app" "mywebapp123dd2" {
  name                = "mywebapp123dd2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.example.location
  service_plan_id     = azurerm_service_plan.example.id

  site_config {
    always_on = false
    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v6.0"
    }
    # ip_restriction {
    #   # block all ip addresses
    #   name       = "DenyAll"
    #   action     = "Deny"
    #   priority   = 100
    #   ip_address = "0.0.0.0/0"
    # }
  }

  logs {
    detailed_error_messages = true
    http_logs {
      azure_blob_storage {
        sas_url           = local.sas_url
        retention_in_days = 3
      }
    }
  }
  # add application settings for application insights

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.example.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.example.connection_string
  }

  # add connection string for sql server
  connection_string {
    # name of the variable in the application
    name  = "SQLConnection"
    type  = "SQLAzure"
    value = "Data Source=tcp:${azurerm_mssql_server.example.fully_qualified_domain_name},1433;Initial Catalog=${local.sql_db_name};Persist Security Info=False;User ID=${azurerm_mssql_server.example.administrator_login};Password=${azurerm_mssql_server.example.administrator_login_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  }

  depends_on = [azurerm_service_plan.example]
}

resource "azurerm_app_service_source_control" "example" {
  app_id                 = azurerm_windows_web_app.mywebapp123dd2.id
  repo_url               = "https://github.com/alashro/sqlapp"
  branch                 = "master"
  use_manual_integration = true

  depends_on = [azurerm_windows_web_app.mywebapp123dd2]
}

