
# create sql server and database
resource "azurerm_mssql_server" "example" {
  name                         = local.sql_server_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "4dm1n157r470r"
  administrator_login_password = "4-v3ry-53cr37-p455w0rd"



  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_mssql_database" "example" {
  name        = local.sql_db_name
  server_id   = azurerm_mssql_server.example.id
  sku_name    = "Basic"
  collation   = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb = 2

  depends_on = [azurerm_mssql_server.example]
}
#

resource "azurerm_mssql_firewall_rule" "example" {
  name             = "FirewallRule1"
  server_id        = azurerm_mssql_server.example.id
  start_ip_address = local.client_ip
  end_ip_address   = local.client_ip

  depends_on = [azurerm_mssql_server.example]
}

# add fire wall rule for web app
resource "azurerm_mssql_firewall_rule" "webapp" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.example.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"

  depends_on = [azurerm_windows_web_app.mywebapp123dd2]
}


# seed the database with file 01.sql from the local filesystem
resource "null_resource" "database_setup" {
  provisioner "local-exec" {
    command = "sqlcmd -S ${azurerm_mssql_server.example.fully_qualified_domain_name} -U ${azurerm_mssql_server.example.administrator_login} -P ${azurerm_mssql_server.example.administrator_login_password} -d ${local.sql_db_name} -i ${local.sql_db_seed_file}"
  }
  depends_on = [
    azurerm_mssql_database.example
  ]
}

