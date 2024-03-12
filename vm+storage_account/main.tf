

# this tf will create virtual network, subnet, and network interface. it will has 2 subnets (subnet1 and subnet2) and 1 network interface that will be in subnet1

locals {
  resource_group_name = "myResourceGroup"
  location            = "UK South"
  vnet_name           = "myVnet"
  nic_name            = "myNic"
  nic_name2           = "myNic2"


  subnets = [
    { name : "subnet1", address_prefix : "10.0.0.0/24" },
    { name : "subnet2", address_prefix : "10.0.1.0/24" }
  ]
}

resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = local.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = local.vnet_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_subnet" "subnet1" {
  name                 = local.subnets[0].name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [local.subnets[0].address_prefix]

  depends_on = [azurerm_virtual_network.vnet]

}

resource "azurerm_subnet" "subnet2" {
  name                 = local.subnets[1].name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [local.subnets[1].address_prefix]

  depends_on = [azurerm_virtual_network.vnet]

}


resource "azurerm_network_interface" "nic" {
  name                = local.nic_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }

  depends_on = [azurerm_subnet.subnet1, azurerm_public_ip.publicip]
}

resource "azurerm_network_interface" "nic2" {
  name                = local.nic_name2
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [azurerm_subnet.subnet1]
}


# create public ip(static) and associate it with the network interface
resource "azurerm_public_ip" "publicip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"

  depends_on = [azurerm_resource_group.rg]
}

//create a network security group and associate it with the network interface. it will allow port 3389(RDP)
resource "azurerm_network_security_group" "nsg" {
  name                = "myNSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg.id

  depends_on = [azurerm_network_security_group.nsg, azurerm_subnet.subnet1]
}


//add window vm to the subnet1 and associate it with the network interface
resource "azurerm_windows_virtual_machine" "example" {
  name                  = "example-vm"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_F2"
  admin_username        = "adminuser"
  admin_password        = "Password1234!"
  network_interface_ids = [azurerm_network_interface.nic.id, azurerm_network_interface.nic2.id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  depends_on = [azurerm_network_interface.nic, azurerm_network_interface.nic2]
}

//add additional disk(16gb) to the vm
resource "azurerm_managed_disk" "example" {
  name                 = "example-os-disk"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 16

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_virtual_machine_data_disk_attachment" "example" {
  managed_disk_id    = azurerm_managed_disk.example.id
  virtual_machine_id = azurerm_windows_virtual_machine.example.id
  lun                = 0
  caching            = "ReadWrite"

  depends_on = [azurerm_managed_disk.example, azurerm_windows_virtual_machine.example]

}

