# main.tf - Simplified version for assessment
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "nomad" {
  name     = "rg-nomad-cluster"
  location = "East US"
}

# Virtual Network
resource "azurerm_virtual_network" "nomad" {
  name                = "vnet-nomad"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.nomad.location
  resource_group_name = azurerm_resource_group.nomad.name
}

# Subnet for servers
resource "azurerm_subnet" "servers" {
  name                 = "subnet-servers"
  resource_group_name  = azurerm_resource_group.nomad.name
  virtual_network_name = azurerm_virtual_network.nomad.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Subnet for clients
resource "azurerm_subnet" "clients" {
  name                 = "subnet-clients"
  resource_group_name  = azurerm_resource_group.nomad.name
  virtual_network_name = azurerm_virtual_network.nomad.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Network Security Group
resource "azurerm_network_security_group" "nomad" {
  name                = "nsg-nomad"
  location            = azurerm_resource_group.nomad.location
  resource_group_name = azurerm_resource_group.nomad.name

  # SSH
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Nomad UI
  security_rule {
    name                       = "Nomad-UI"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "4646"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Nomad RPC
  security_rule {
    name                       = "Nomad-RPC"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "4647"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # App ports
  security_rule {
    name                       = "Apps"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Public IP for server
resource "azurerm_public_ip" "server" {
  name                = "pip-nomad-server"
  location            = azurerm_resource_group.nomad.location
  resource_group_name = azurerm_resource_group.nomad.name
  allocation_method   = "Static"
}

# Network Interface for server
resource "azurerm_network_interface" "server" {
  name                = "nic-nomad-server"
  location            = azurerm_resource_group.nomad.location
  resource_group_name = azurerm_resource_group.nomad.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.servers.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.server.id
  }
}

# Network Interface for client
resource "azurerm_network_interface" "client" {
  name                = "nic-nomad-client"
  location            = azurerm_resource_group.nomad.location
  resource_group_name = azurerm_resource_group.nomad.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.clients.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Associate NSG with NICs
resource "azurerm_network_interface_security_group_association" "server" {
  network_interface_id      = azurerm_network_interface.server.id
  network_security_group_id = azurerm_network_security_group.nomad.id
}

resource "azurerm_network_interface_security_group_association" "client" {
  network_interface_id      = azurerm_network_interface.client.id
  network_security_group_id = azurerm_network_security_group.nomad.id
}

# Nomad Server VM
resource "azurerm_linux_virtual_machine" "server" {
  name                = "vm-nomad-server"
  resource_group_name = azurerm_resource_group.nomad.name
  location            = azurerm_resource_group.nomad.location
  size                = "Standard_B1s"  # Cheapest option
  admin_username      = "adminuser"
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.server.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")  # You'll need to generate this
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(file("${path.module}/scripts/install-nomad-server.sh"))
}

# Nomad Client VM
resource "azurerm_linux_virtual_machine" "client" {
  name                = "vm-nomad-client"
  resource_group_name = azurerm_resource_group.nomad.name
  location            = azurerm_resource_group.nomad.location
  size                = "Standard_B1s"  # Cheapest option
  admin_username      = "adminuser"
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.client.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/scripts/install-nomad-client.sh", {
    server_ip = azurerm_network_interface.server.private_ip_address
  }))
}

# Outputs
output "nomad_ui_url" {
  value = "http://${azurerm_public_ip.server.ip_address}:4646"
}

output "ssh_server" {
  value = "ssh adminuser@${azurerm_public_ip.server.ip_address}"
}

output "server_private_ip" {
  value = azurerm_network_interface.server.private_ip_address
}

output "client_private_ip" {
  value = azurerm_network_interface.client.private_ip_address
}
