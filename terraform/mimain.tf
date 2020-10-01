 provider "azurerm" {
  version = "2.2.0"
  features {}
}

locals {
  mi_server_name   = var.mi_server_name
}

resource "azurerm_resource_group" "mi_server_rg" {
  name     = var.mi_server_rg
  location = var.mi_server_location
}

resource "azurerm_storage_account" "mi_stg_acct" {
    name                        = "mistg00020200716"
    resource_group_name         = var.mi_server_rg
    location                    = var.mi_server_location
    account_replication_type    = "LRS"
    account_tier                = "Standard"
}

resource "azurerm_virtual_network" "mi_server_vnet" {
  name                = "miserver-vnet"
  location            = var.mi_server_location
  resource_group_name = azurerm_resource_group.mi_server_rg.name
  address_space       = [var.mi_server_address_space] 
}

resource "azurerm_subnet" "mi_server_subnet" {
    name                 = "mi-subnet"
    resource_group_name  = azurerm_resource_group.mi_server_rg.name
    virtual_network_name = azurerm_virtual_network.mi_server_vnet.name
    address_prefix       = var.mi_server_address_prefix
}

resource "azurerm_network_security_group" "mi_server_nsg" {
  name                = "mi-nsg"
  location            = var.mi_server_location  
  resource_group_name = azurerm_resource_group.mi_server_rg.name    
}

resource "azurerm_network_security_rule" "mi_server_nsg_rule_rdp" {
  name                        = "RDP Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.mi_server_rg.name   
  network_security_group_name = azurerm_network_security_group.mi_server_nsg.name
}


resource "azurerm_subnet_network_security_group_association" "mi_server_sag" {
  network_security_group_id = azurerm_network_security_group.mi_server_nsg.id  
  subnet_id                 = azurerm_subnet.mi_server_subnet.id
}

resource "azurerm_public_ip" "mi_publicip" {
    name                         = "mi_PublicIP"
    location                     = var.mi_server_location
    resource_group_name          = var.mi_server_rg
    allocation_method            = "Dynamic"
}

resource "azurerm_network_interface" "mi_nic" {
    name                        = "mi_NIC"
    location                    = var.mi_server_location
    resource_group_name         = var.mi_server_rg

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.mi_server_subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.mi_publicip.id
    }
}

resource "azurerm_virtual_machine" "web_server" {
  name                  = var.mi_server_name
  location              = var.mi_server_location
  resource_group_name   = var.mi_server_rg
  network_interface_ids = [azurerm_network_interface.mi_nic.id]
  vm_size               = "Standard_B2s"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core-smalldisk"
    version   = "latest"
  }

  storage_os_disk {
    name              = "server-os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name      = var.mi_server_name
    admin_username     = "miAdmin"
    admin_password     = "********"

  }

