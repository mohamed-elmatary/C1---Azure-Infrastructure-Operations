provider "azurerm" {
  features {}
  subscription_id = "{{subscription_id}}"
  tenant_id       = "{{tenant_id}}"
  client_id       = "{{client_id}}"
  client_secret   = "{{client_secret}}"
}



resource "azurerm_virtual_network" "vnet" {
  name                = "main-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
  tags = {
    "project" = "Deploying a Web Server in Azure"
  }
}

resource "azurerm_subnet" "subnet" {
  name                 = "main-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
    # Attach the NSG to the subnet
}

resource "azurerm_subnet_network_security_group_association" "nsg_subnet_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "nic-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    "project" = "Deploying a Web Server in Azure"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "nic_association" {
  count                   = var.vm_count
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}

resource "azurerm_availability_set" "avset" {
  name                = "my-avset"
  location            = var.location
  resource_group_name = var.resource_group_name

  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  managed                      = true
  tags = {
    "project" = "Deploying a Web Server in Azure"
  }
}


resource "azurerm_linux_virtual_machine" "vm" {
  count               = var.vm_count
  name                = "vm-${count.index}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_DS1_v2"
  admin_username      = "azureuser"
  admin_password      = "Azxc@mc123456789"
  disable_password_authentication =  false
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  availability_set_id   = azurerm_availability_set.avset.id
  source_image_id       = "/subscriptions/{{subscription_id}}/resourceGroups/MYRESOURCEGROUP/providers/Microsoft.Compute/images/myPackerImage"

  os_disk {
    name                 = "vm-${count.index}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  tags = {
    "project" = "Deploying a Web Server in Azure"
  }
}

resource "azurerm_public_ip" "lb_public_ip" {
  name                = "lb-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    "project" = "Deploying a Web Server in Azure"
  }
}

resource "azurerm_lb" "lb" {
  name                = "my-loadbalancer"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.lb_public_ip.id
  }
  tags = {
    "project" = "Deploying a Web Server in Azure"
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name                = "backend-pool"
  loadbalancer_id     = azurerm_lb.lb.id

}

resource "azurerm_lb_probe" "tcp_probe" {
  name                = "tcp-probe"
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = "Tcp"
  port                = 80
}

resource "azurerm_lb_rule" "lb_rule" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                       = azurerm_lb_probe.tcp_probe.id
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg"
  location            = "East US"
  resource_group_name = var.resource_group_name
  


  security_rule {
    name                       = "allow_to_azure_load_balancer"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                        = "allow-http-from-azure_load_balancer"
    priority                    = 200
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "80"
    source_address_prefix       = "AzureLoadBalancer"
    destination_address_prefix  = "*"
  }

  security_rule {
      name                        = "allow-inbound-vnet"
      priority                    = 300
      direction                   = "Inbound"
      access                      = "Allow"
      protocol                    = "*"
      source_port_range           = "*"
      destination_port_range      = "*"
      source_address_prefix       = "VirtualNetwork"
      destination_address_prefix  = "VirtualNetwork"
  }

  security_rule {
    name                       = "deny_all_inbound_from_internet"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                        = "allow-outbound-vnet"
    priority                    = 100
    direction                   = "Outbound"
    access                      = "Allow"
    protocol                    = "*"
    source_port_range           = "*"
    destination_port_range      = "*"
    source_address_prefix       = "VirtualNetwork"
    destination_address_prefix  = "VirtualNetwork"
  }
  

  



  tags = {
    "project" = "Deploying a Web Server in Azure"
  }
}

output "lb_public_ip" {
  value = azurerm_public_ip.lb_public_ip.ip_address
}