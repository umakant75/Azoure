# Configure the Microsoft Azure Provider.
provider "azurerm" {
  version = "~>1.31"
}


# Create a resource group
resource "azurerm_resource_group" "iotrg" {
  name     = "${var.prefix}-IOT"
  location = var.location
  tags     = var.tags
}
resource "azurerm_storage_account" "iotrg" {
  name                     = "iotrgstorage"
  resource_group_name      = azurerm_resource_group.iotrg.name
  location                 = azurerm_resource_group.iotrg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
resource "azurerm_storage_container" "iotrg" {
  name                  = "iotrg-container"
  storage_account_name  = azurerm_storage_account.iotrg.name
  container_access_type = "private"
}
resource "azurerm_eventhub_namespace" "iotrg" {
  name                = "iotrg-namesapce"
  resource_group_name = azurerm_resource_group.iotrg.name
  location            = azurerm_resource_group.iotrg.location
  sku                 = "Basic"
}
resource "azurerm_eventhub" "iotrg" {
  name                = "iotrg-eventhub"
  resource_group_name = azurerm_resource_group.iotrg.name
  namespace_name      = azurerm_eventhub_namespace.iotrg.name
  partition_count     = 2
  message_retention   = 1
}
resource "azurerm_eventhub_authorization_rule" "iotrg" {
  resource_group_name = azurerm_resource_group.iotrg.name
  namespace_name      = azurerm_eventhub_namespace.iotrg.name
  eventhub_name       = azurerm_eventhub.iotrg.name
  name                = "acctest"
  send                = true
}
resource "azurerm_iothub" "iotrg" {
  name                = "iotrg-IoTHub"
  resource_group_name = azurerm_resource_group.iotrg.name
  location            = azurerm_resource_group.iotrg.location

  sku {
    name     = "S1"
    capacity = "1"
  }
  endpoint {
    type                       = "AzureIotHub.StorageContainer"
    connection_string          = azurerm_storage_account.iotrg.primary_blob_connection_string
    name                       = "export"
    batch_frequency_in_seconds = 60
    max_chunk_size_in_bytes    = 10485760
    container_name             = azurerm_storage_container.iotrg.name
    encoding                   = "Avro"
    file_name_format           = "{iothub}/{partition}_{YYYY}_{MM}_{DD}_{HH}_{mm}"
  }
    endpoint {
    type              = "AzureIotHub.EventHub"
    connection_string = azurerm_eventhub_authorization_rule.iotrg.primary_connection_string
    name              = "export2"
  }

  route {
    name           = "export"
    source         = "DeviceMessages"
    condition      = "true"
    endpoint_names = ["export"]
    enabled        = true
  }

  route {
    name           = "export2"
    source         = "DeviceMessages"
    condition      = "true"
    endpoint_names = ["export2"]
    enabled        = true
  }

  tags = {
    purpose = "testing"
  }
}
