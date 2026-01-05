# # # Frontend: Azure Storage Static Website # # #
locals {
  frontend_sa_name = substr(lower("stweb${replace(local.name_prefix, "-", "")}"), 0, 24)
}

resource "azurerm_storage_account" "frontend" {
  name                = local.frontend_sa_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  https_traffic_only_enabled = true
  min_tls_version           = "TLS1_2"

  # Static website hosting requires public access on the $web container content.
  allow_nested_items_to_be_public = true


  tags = local.tags
}

resource "azurerm_storage_account_static_website" "frontend" {
  storage_account_id = azurerm_storage_account.frontend.id
  index_document     = "index.html"
  error_404_document = "404.html"
}

##################################################