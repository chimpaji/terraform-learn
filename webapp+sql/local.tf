locals {
  webapp_name         = "webapp"
  sql_server_name     = "sqlserver3234test234577"
  sql_db_name         = "sqldb"
  sql_db_seed_file    = "01.sql"
  resource_group_name = "rg"
  location            = "UK South"
  sas_url             = "https://${azurerm_storage_account.example.name}.blob.core.windows.net/${azurerm_storage_container.example.name}?${data.azurerm_storage_account_sas.example.sas}"
  client_ip           = "FILL_IN_YOUR_CLIENT_IP"
}
